// lib/models/course.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String thumbUrl;
  final String level;
  final double price;
  final int totalLessons;
  final DateTime? createdAt;
  
  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbUrl,
    required this.level,
    required this.price,
    required this.totalLessons,
    this.createdAt,
  });
  
  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbUrl: data['thumbUrl'] ?? '',
      level: data['level'] ?? 'Beginner',
      price: (data['price'] ?? 0).toDouble(),
      totalLessons: data['totalLessons'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'thumbUrl': thumbUrl,
      'level': level,
      'price': price,
      'totalLessons': totalLessons,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// lib/models/lesson.dart
class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String ytId;
  final int order;
  final int duration; // in seconds
  
  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.ytId,
    required this.order,
    required this.duration,
  });
  
  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lesson(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      ytId: data['ytId'] ?? '',
      order: data['order'] ?? 0,
      duration: data['duration'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'ytId': ytId,
      'order': order,
      'duration': duration,
    };
  }
  
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  bool get isLocked => ytId.isEmpty;
}