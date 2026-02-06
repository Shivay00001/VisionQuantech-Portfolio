import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class PurchaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  // Enroll User in Course (Free Enrollment)
  Future<void> enrollUser({
    required String userId,
    required String courseId,
  }) async {
    final purchaseId = _uuid.v4();
    
    await _db.collection('purchases').doc(purchaseId).set({
      'id': purchaseId,
      'userId': userId,
      'courseId': courseId,
      'paymentStatus': 'completed',
      'paymentMethod': 'free',
      'amount': 0.0,
      'enrolledAt': FieldValue.serverTimestamp(),
    });
    
    // Update user's enrolled courses array
    await _db.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayUnion([courseId]),
    });
  }
  
  // Check if User is Enrolled
  Future<bool> isUserEnrolled({
    required String userId,
    required String courseId,
  }) async {
    final snapshot = await _db
        .collection('purchases')
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .where('paymentStatus', isEqualTo: 'completed')
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }
  
  // Get User Purchase History
  Stream<List<Map<String, dynamic>>> getUserPurchases(String userId) {
    return _db
        .collection('purchases')
        .where('userId', isEqualTo: userId)
        .orderBy('enrolledAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }
  
  // Unenroll User (Admin/Testing only)
  Future<void> unenrollUser({
    required String userId,
    required String courseId,
  }) async {
    final snapshot = await _db
        .collection('purchases')
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .get();
    
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    
    await _db.collection('users').doc(userId).update({
      'enrolledCourses': FieldValue.arrayRemove([courseId]),
    });
  }
}