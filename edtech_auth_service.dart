import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' show User;

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Convert Firebase User to App User
  User? _userFromFirebase(fb.User? user) {
    if (user == null) return null;
    return User(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName,
    );
  }
  
  // Auth State Stream
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().map(_userFromFirebase);
  }
  
  // Get Current User
  User? get currentUser {
    return _userFromFirebase(_auth.currentUser);
  }
  
  // Sign Up
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(displayName);
      
      // Create Firestore user document
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'enrolledCourses': [],
      });
      
      return _userFromFirebase(credential.user);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Sign In
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(credential.user);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Handle Auth Exceptions
  String _handleAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}