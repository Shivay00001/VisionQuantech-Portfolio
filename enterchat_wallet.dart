// lib/features/wallet/wallet_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../shared/models/wallet_account.dart';
import '../../shared/models/wallet_transaction.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final _supabase = Supabase.instance.client;
  final _storage = const FlutterSecureStorage();
  static const _pinKey = 'wallet_pin_hash';

  Future<WalletAccount?> getWalletAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('wallet_accounts')
          .select()
          .eq('user_id', userId)
          .single();

      return WalletAccount(
        accountId: response['id'],
        userId: response['user_id'],
        balance: (response['balance'] as num).toDouble(),
        currency: response['currency'] ?? 'USD',
        isPinSet: response['is_pin_set'] ?? false,
        isLocked: response['is_locked'] ?? false,
        failedPinAttempts: response['failed_pin_attempts'] ?? 0,
      );
    } catch (e) {
      print('[WalletService] Error getting wallet: $e');
      return null;
    }
  }

  Future<bool> createWalletAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('wallet_accounts').insert({
        'user_id': userId,
        'balance': 0.0,
        'currency': 'USD',
        'is_pin_set': false,
        'is_locked': false,
        'failed_pin_attempts': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('[WalletService] Error creating wallet: $e');
      return false;
    }
  }

  Future<bool> setupPin(String pin) async {
    try {
      if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
        throw Exception('PIN must be 6 digits');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final pinHash = _hashPin(pin);
      await _storage.write(key: _pinKey, value: pinHash);

      await _supabase
          .from('wallet_accounts')
          .update({'is_pin_set': true})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('[WalletService] Error setting up PIN: $e');
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      if (storedHash == null) return false;

      final inputHash = _hashPin(pin);
      final isValid = storedHash == inputHash;

      if (!isValid) {
        await _incrementFailedAttempts();
      } else {
        await _resetFailedAttempts();
      }

      return isValid;
    } catch (e) {
      print('[WalletService] Error verifying PIN: $e');
      return false;
    }
  }

  Future<void> _incrementFailedAttempts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final account = await getWalletAccount();
      if (account == null) return;

      final newAttempts = account.failedPinAttempts + 1;

      if (newAttempts >= 3) {
        await _supabase.from('wallet_accounts').update({
          'is_locked': true,
          'locked_until': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
          'failed_pin_attempts': newAttempts,
        }).eq('user_id', userId);
      } else {
        await _supabase
            .from('wallet_accounts')
            .update({'failed_pin_attempts': newAttempts})
            .eq('user_id', userId);
      }
    } catch (e) {
      print('[WalletService] Error incrementing failed attempts: $e');
    }
  }

  Future<void> _resetFailedAttempts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('wallet_accounts')
          .update({
            'failed_pin_attempts': 0,
            'is_locked': false,
            'locked_until': null,
          })
          .eq('user_id', userId);
    } catch (e) {
      print('[WalletService] Error resetting failed attempts: $e');
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<bool> topUpWallet({
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final account = await getWalletAccount();
      if (account == null) return false;

      // Process payment through PSP
      final paymentResult = await _processPayment(
        amount: amount,
        method: paymentMethod,
        details: paymentDetails,
      );

      if (!paymentResult['success']) {
        throw Exception('Payment failed');
      }

      // Update balance
      final newBalance = account.balance + amount;
      await _supabase
          .from('wallet_accounts')
          .update({'balance': newBalance})
          .eq('user_id', userId);

      // Record transaction
      await _recordTransaction(
        fromAccountId: 'SYSTEM',
        toAccountId: account.accountId,
        amount: amount,
        type: TransactionType.topup,
        referenceId: paymentResult['transactionId'],
      );

      return true;
    } catch (e) {
      print('[WalletService] Error topping up wallet: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _processPayment({
    required double amount,
    required String method,
    Map<String, dynamic>? details,
  }) async {
    // Integrate with Stripe/Razorpay/UPI
    // This is a placeholder - actual implementation needed
    
    if (method == 'UPI') {
      // Launch UPI intent
      return {
        'success': true,
        'transactionId': 'UPI_${DateTime.now().millisecondsSinceEpoch}',
      };
    } else if (method == 'CARD') {
      // Process card payment via Stripe
      return {
        'success': true,
        'transactionId': 'CARD_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    return {'success': false};
  }

  Future<bool> transferToUser({
    required String recipientUserId,
    required double amount,
    required String pin,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Verify PIN
      final pinValid = await verifyPin(pin);
      if (!pinValid) {
        throw Exception('Invalid PIN');
      }

      final senderAccount = await getWalletAccount();
      if (senderAccount == null) throw Exception('Sender account not found');

      if (senderAccount.balance < amount) {
        throw Exception('Insufficient balance');
      }

      // Get recipient account
      final recipientResponse = await _supabase
          .from('wallet_accounts')
          .select()
          .eq('user_id', recipientUserId)
          .single();

      final recipientAccount = WalletAccount(
        accountId: recipientResponse['id'],
        userId: recipientResponse['user_id'],
        balance: (recipientResponse['balance'] as num).toDouble(),
        currency: recipientResponse['currency'] ?? 'USD',
      );

      // Perform transfer (double-entry)
      final newSenderBalance = senderAccount.balance - amount;
      final newRecipientBalance = recipientAccount.balance + amount;

      // Update both accounts atomically
      await _supabase.rpc('transfer_funds', params: {
        'sender_id': userId,
        'recipient_id': recipientUserId,
        'amount': amount,
      });

      // Record transactions
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      
      await _recordTransaction(
        fromAccountId: senderAccount.accountId,
        toAccountId: recipientAccount.accountId,
        amount: amount,
        type: TransactionType.transfer,
        description: description,
        referenceId: transactionId,
      );

      return true;
    } catch (e) {
      print('[WalletService] Error transferring funds: $e');
      return false;
    }
  }

  Future<void> _recordTransaction({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required TransactionType type,
    String? description,
    String? referenceId,
  }) async {
    try {
      await _supabase.from('wallet_transactions').insert({
        'from_account_id': fromAccountId,
        'to_account_id': toAccountId,
        'amount': amount,
        'currency': 'USD',
        'type': type.name,
        'status': 'completed',
        'description': description,
        'reference_id': referenceId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[WalletService] Error recording transaction: $e');
    }
  }

  Future<List<WalletTransaction>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final account = await getWalletAccount();
      if (account == null) return [];

      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .or('from_account_id.eq.${account.accountId},to_account_id.eq.${account.accountId}')
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((item) {
        return WalletTransaction(
          transactionId: item['id'],
          fromAccountId: item['from_account_id'],
          toAccountId: item['to_account_id'],
          amount: (item['amount'] as num).toDouble(),
          currency: item['currency'] ?? 'USD',
          type: TransactionType.values.firstWhere(
            (e) => e.name == item['type'],
            orElse: () => TransactionType.transfer,
          ),
          status: TransactionStatus.values.firstWhere(
            (e) => e.name == item['status'],
            orElse: () => TransactionStatus.completed,
          ),
          description: item['description'],
          referenceId: item['reference_id'],
        );
      }).toList();
    } catch (e) {
      print('[WalletService] Error getting transaction history: $e');
      return [];
    }
  }

  Future<double> getBalance() async {
    final account = await getWalletAccount();
    return account?.balance ?? 0.0;
  }
}