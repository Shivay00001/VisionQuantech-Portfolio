import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme.dart';
import 'main.dart' show User;
import 'modules/auth/login_page.dart';
import 'modules/auth/signup_page.dart';
import 'modules/auth/forgot_password_page.dart';
import 'modules/home/home_page.dart';
import 'modules/courses/course_list_page.dart';
import 'modules/courses/course_detail_page.dart';
import 'modules/courses/my_courses_page.dart';
import 'modules/lessons/lesson_player_page.dart';
import 'modules/profile/profile_page.dart';

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdTech Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/courses': (context) => const CourseListPage(),
        '/my-courses': (context) => const MyCoursesPage(),
        '/profile': (context) => const ProfilePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/course-detail') {
          final courseId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => CourseDetailPage(courseId: courseId),
          );
        }
        if (settings.name == '/lesson-player') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => LessonPlayerPage(
              lessonId: args['lessonId'],
              courseId: args['courseId'],
            ),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    
    if (user == null) {
      return const LoginPage();
    }
    
    return const HomePage();
  }
}