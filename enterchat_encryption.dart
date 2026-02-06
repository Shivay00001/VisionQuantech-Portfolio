// lib/core/security/e2e_encryption_service.dart
import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'dart:convert';
import 'dart:typed_data';
import 'key_management_service.dart';

class E2EEncryptionService {
  static final E2EEncryptionService _instance = E2EEncryptionService._internal();
  factory E2EEncryptionService() => _instance;
  E2EEncryptionService._internal();

  final KeyManagementService _keyManager = KeyManagementService();
  final _algorithm = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
  final _x25519 = X25519();

  Future<void> initialize() async {
    await _keyManager.initialize();
  }

  // Generate key pair for user
  Future<Map<String, String>> generateKeyPair() async {
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    return {
      'publicKey': base64Encode(publicKey.bytes),
      'privateKey': base64Encode(privateKeyBytes),
    };
  }

  // Derive shared secret using ECDH
  Future<List<int>> deriveSharedSecret(
    String myPrivateKeyBase64,
    String theirPublicKeyBase64,
  ) async {
    final myPrivateKey = SimpleKeyPairData(
      base64Decode(myPrivateKeyBase64),
      publicKey: SimplePublicKey([], type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );

    final theirPublicKey = SimplePublicKey(
      base64Decode(theirPublicKeyBase64),
      type: KeyPairType.x25519,
    );

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: myPrivateKey,
      remotePublicKey: theirPublicKey,
    );

    return await sharedSecret.extractBytes();
  }

  // Encrypt message
  Future<EncryptedMessage> encryptMessage({
    required String message,
    required String conversationKeyId,
  }) async {
    try {
      final conversationKey = await _keyManager.getConversationKey(conversationKeyId);
      if (conversationKey == null) {
        throw Exception('Conversation key not found');
      }

      final key = enc.Key.fromBase64(conversationKey);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(message, iv: iv);

      return EncryptedMessage(
        ciphertext: encrypted.base64,
        iv: iv.base64,
        keyId: conversationKeyId,
      );
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  // Decrypt message
  Future<String> decryptMessage({
    required String ciphertext,
    required String iv,
    required String conversationKeyId,
  }) async {
    try {
      final conversationKey = await _keyManager.getConversationKey(conversationKeyId);
      if (conversationKey == null) {
        throw Exception('Conversation key not found');
      }

      final key = enc.Key.fromBase64(conversationKey);
      final ivObj = enc.IV.fromBase64(iv);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decrypt64(ciphertext, iv: ivObj);
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  // Encrypt file
  Future<EncryptedFile> encryptFile({
    required Uint8List fileBytes,
    required String conversationKeyId,
  }) async {
    try {
      final conversationKey = await _keyManager.getConversationKey(conversationKeyId);
      if (conversationKey == null) {
        throw Exception('Conversation key not found');
      }

      final key = enc.Key.fromBase64(conversationKey);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      return EncryptedFile(
        encryptedBytes: encrypted.bytes,
        iv: iv.base64,
        keyId: conversationKeyId,
      );
    } catch (e) {
      throw Exception('File encryption failed: $e');
    }
  }

  // Decrypt file
  Future<Uint8List> decryptFile({
    required Uint8List encryptedBytes,
    required String iv,
    required String conversationKeyId,
  }) async {
    try {
      final conversationKey = await _keyManager.getConversationKey(conversationKeyId);
      if (conversationKey == null) {
        throw Exception('Conversation key not found');
      }

      final key = enc.Key.fromBase64(conversationKey);
      final ivObj = enc.IV.fromBase64(iv);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decryptBytes(
        enc.Encrypted(encryptedBytes),
        iv: ivObj,
      );
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('File decryption failed: $e');
    }
  }

  // Create conversation key from shared secret
  Future<String> createConversationKey(List<int> sharedSecret) async {
    final hash = await Sha256().hash(sharedSecret);
    return base64Encode(hash.bytes);
  }

  // Verify message signature
  Future<bool> verifySignature({
    required String message,
    required String signature,
    required String publicKey,
  }) async {
    try {
      final algorithm = Ed25519();
      final publicKeyObj = SimplePublicKey(
        base64Decode(publicKey),
        type: KeyPairType.ed25519,
      );

      final signatureObj = Signature(
        base64Decode(signature),
        publicKey: publicKeyObj,
      );

      final isValid = await algorithm.verify(
        utf8.encode(message),
        signature: signatureObj,
      );

      return isValid;
    } catch (e) {
      return false;
    }
  }
}

class EncryptedMessage {
  final String ciphertext;
  final String iv;
  final String keyId;

  EncryptedMessage({
    required this.ciphertext,
    required this.iv,
    required this.keyId,
  });

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'iv': iv,
    'keyId': keyId,
  };

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      ciphertext: json['ciphertext'],
      iv: json['iv'],
      keyId: json['keyId'],
    );
  }
}

class EncryptedFile {
  final Uint8List encryptedBytes;
  final String iv;
  final String keyId;

  EncryptedFile({
    required this.encryptedBytes,
    required this.iv,
    required this.keyId,
  });
}

// lib/core/security/key_management_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class KeyManagementService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _privateKeyKey = 'user_private_key';
  static const _publicKeyKey = 'user_public_key';
  static const _conversationKeysPrefix = 'conv_key_';

  Future<void> initialize() async {
    // Check if keys exist, generate if not
    final privateKey = await _storage.read(key: _privateKeyKey);
    if (privateKey == null) {
      // Keys will be generated during registration
    }
  }

  Future<void> saveUserKeys({
    required String publicKey,
    required String privateKey,
  }) async {
    await _storage.write(key: _publicKeyKey, value: publicKey);
    await _storage.write(key: _privateKeyKey, value: privateKey);
  }

  Future<String?> getUserPublicKey() async {
    return await _storage.read(key: _publicKeyKey);
  }

  Future<String?> getUserPrivateKey() async {
    return await _storage.read(key: _privateKeyKey);
  }

  Future<void> saveConversationKey({
    required String conversationId,
    required String key,
  }) async {
    final keyId = const Uuid().v4();
    await _storage.write(
      key: '$_conversationKeysPrefix$keyId',
      value: jsonEncode({
        'conversationId': conversationId,
        'key': key,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<String?> getConversationKey(String keyId) async {
    final data = await _storage.read(key: '$_conversationKeysPrefix$keyId');
    if (data == null) return null;

    final map = jsonDecode(data);
    return map['key'];
  }

  Future<String?> getConversationKeyByConversationId(String conversationId) async {
    final allKeys = await _storage.readAll();
    
    for (final entry in allKeys.entries) {
      if (entry.key.startsWith(_conversationKeysPrefix)) {
        final map = jsonDecode(entry.value);
        if (map['conversationId'] == conversationId) {
          return map['key'];
        }
      }
    }
    
    return null;
  }

  Future<void> deleteConversationKey(String keyId) async {
    await _storage.delete(key: '$_conversationKeysPrefix$keyId');
  }

  Future<void> clearAllKeys() async {
    await _storage.deleteAll();
  }
}