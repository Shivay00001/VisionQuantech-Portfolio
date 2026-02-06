import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('🚀 Starting database seeding...');
  
  final firestore = FirebaseFirestore.instance;
  
  // Sample Courses Data
  final courses = [
    {
      'title': 'Complete Flutter Development',
      'description': 'Learn Flutter from scratch and build beautiful cross-platform apps. Master widgets, state management, Firebase integration, and deploy to Play Store and App Store.',
      'thumbUrl': 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
      'level': 'Beginner',
      'price': 0.0,
      'totalLessons': 5,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Advanced React & Next.js',
      'description': 'Master modern web development with React 18, Next.js 14, TypeScript, and build production-ready applications with best practices.',
      'thumbUrl': 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800',
      'level': 'Intermediate',
      'price': 0.0,
      'totalLessons': 4,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Python for Data Science',
      'description': 'Complete Python programming for data science, machine learning, and AI. Learn NumPy, Pandas, Matplotlib, Scikit-learn, and TensorFlow.',
      'thumbUrl': 'https://images.unsplash.com/photo-1526379095098-d400fd0bf935?w=800',
      'level': 'Advanced',
      'price': 0.0,
      'totalLessons': 6,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];
  
  // Sample Lessons Data (Replace with YOUR actual YouTube unlisted video IDs)
  final lessonsData = {
    'Complete Flutter Development': [
      {'title': 'Introduction to Flutter', 'ytId': 'YOUTUBE_VIDEO_ID_1', 'duration': 900},
      {'title': 'Widgets & Layouts', 'ytId': 'YOUTUBE_VIDEO_ID_2', 'duration': 1200},
      {'title': 'State Management Basics', 'ytId': 'YOUTUBE_VIDEO_ID_3', 'duration': 1500},
      {'title': 'Firebase Integration', 'ytId': 'YOUTUBE_VIDEO_ID_4', 'duration': 1800},
      {'title': 'Building Your First App', 'ytId': 'YOUTUBE_VIDEO_ID_5', 'duration': 2100},
    ],
    'Advanced React & Next.js': [
      {'title': 'React 18 New Features', 'ytId': 'YOUTUBE_VIDEO_ID_6', 'duration': 1100},
      {'title': 'Next.js App Router', 'ytId': 'YOUTUBE_VIDEO_ID_7', 'duration': 1400},
      {'title': 'Server Components', 'ytId': 'YOUTUBE_VIDEO_ID_8', 'duration': 1600},
      {'title': 'Authentication & Authorization', 'ytId': 'YOUTUBE_VIDEO_ID_9', 'duration': 1900},
    ],
    'Python for Data Science': [
      {'title': 'Python Fundamentals', 'ytId': 'YOUTUBE_VIDEO_ID_10', 'duration': 1000},
      {'title': 'NumPy Arrays', 'ytId': 'YOUTUBE_VIDEO_ID_11', 'duration': 1300},
      {'title': 'Pandas DataFrames', 'ytId': 'YOUTUBE_VIDEO_ID_12', 'duration': 1700},
      {'title': 'Data Visualization', 'ytId': 'YOUTUBE_VIDEO_ID_13', 'duration': 2000},
      {'title': 'Machine Learning Basics', 'ytId': 'YOUTUBE_VIDEO_ID_14', 'duration': 2200},
      {'title': 'Deep Learning with TensorFlow', 'ytId': 'YOUTUBE_VIDEO_ID_15', 'duration': 2500},
    ],
  };
  
  try {
    // Seed Courses
    print('📚 Seeding courses...');
    final courseIds = <String, String>{};
    
    for (var courseData in courses) {
      final courseRef = await firestore.collection('courses').add(courseData);
      courseIds[courseData['title'] as String] = courseRef.id;
      print('✅ Added course: ${courseData['title']}');
    }
    
    // Seed Lessons
    print('📖 Seeding lessons...');
    
    for (var entry in lessonsData.entries) {
      final courseTitle = entry.key;
      final lessons = entry.value;
      final courseId = courseIds[courseTitle];
      
      if (courseId == null) continue;
      
      for (var i = 0; i < lessons.length; i++) {
        final lessonData = lessons[i];
        await firestore.collection('lessons').add({
          'courseId': courseId,
          'title': lessonData['title'],
          'ytId': lessonData['ytId'],
          'order': i + 1,
          'duration': lessonData['duration'],
        });
        print('  ✅ Added lesson: ${lessonData['title']}');
      }
    }
    
    print('\n🎉 Database seeding completed successfully!');
    print('📊 Summary:');
    print('   - Courses: ${courses.length}');
    print('   - Total Lessons: ${lessonsData.values.fold(0, (sum, lessons) => sum + lessons.length)}');
    print('\n⚠️  IMPORTANT: Replace YOUTUBE_VIDEO_ID_X with your actual unlisted YouTube video IDs!');
    
  } catch (e) {
    print('❌ Error seeding database: $e');
  }
}

// Run this script with:
// dart scripts/seed_database.dart