import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../services/purchase_service.dart';
import '../../services/auth_service.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../theme/theme.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  bool _isEnrolling = false;

  Future<void> _handleEnrollment(BuildContext context) async {
    final user = context.read<User?>();
    if (user == null) return;

    setState(() => _isEnrolling = true);

    try {
      final purchaseService = context.read<PurchaseService>();
      await purchaseService.enrollUser(
        userId: user.uid,
        courseId: widget.courseId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully enrolled!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final purchaseService = context.read<PurchaseService>();
    final user = context.watch<User?>();

    return Scaffold(
      body: FutureBuilder<Course?>(
        future: firestoreService.getCourseById(widget.courseId),
        builder: (context, courseSnapshot) {
          if (courseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!courseSnapshot.hasData) {
            return const Center(child: Text('Course not found'));
          }

          final course = courseSnapshot.data!;

          return StreamBuilder<bool>(
            stream: user != null
                ? purchaseService
                    .getUserPurchases(user.uid)
                    .map((purchases) => purchases.any((p) => p['courseId'] == widget.courseId))
                : Stream.value(false),
            builder: (context, enrollmentSnapshot) {
              final isEnrolled = enrollmentSnapshot.data ?? false;

              return CustomScrollView(
                slivers: [
                  // App Bar with Image
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    backgroundColor: AppTheme.darkBg,
                    flexibleSpace: FlexibleSpaceBar(
                      background: CachedNetworkImage(
                        imageUrl: course.thumbUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Course Content
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.darkBg, AppTheme.cardBg],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              course.title,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 8),

                            // Meta Info
                            Row(
                              children: [
                                _buildChip(course.level, Icons.signal_cellular_alt),
                                const SizedBox(width: 8),
                                _buildChip('${course.totalLessons} Lessons', Icons.play_circle),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Description
                            Text(
                              'About this course',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),

                            // Enrollment Button
                            if (!isEnrolled)
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isEnrolling ? null : () => _handleEnrollment(context),
                                  child: _isEnrolling
                                      ? const CircularProgressIndicator()
                                      : const Text('Enroll Now'),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Lessons Section
                            Text(
                              'Course Content',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Lessons List
                  StreamBuilder<List<Lesson>>(
                    stream: firestoreService.getLessonsByCourse(widget.courseId),
                    builder: (context, lessonsSnapshot) {
                      if (lessonsSnapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!lessonsSnapshot.hasData || lessonsSnapshot.data!.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(child: Text('No lessons available')),
                        );
                      }

                      final lessons = lessonsSnapshot.data!;

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final lesson = lessons[index];
                            return LessonTile(
                              lesson: lesson,
                              isEnrolled: isEnrolled,
                              onTap: isEnrolled
                                  ? () {
                                      Navigator.of(context).pushNamed(
                                        '/lesson-player',
                                        arguments: {
                                          'lessonId': lesson.id,
                                          'courseId': widget.courseId,
                                        },
                                      );
                                    }
                                  : null,
                            );
                          },
                          childCount: lessons.length,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.glassBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryNeon),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class LessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool isEnrolled;
  final VoidCallback? onTap;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.isEnrolled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: AppTheme.glassBox(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEnrolled ? AppTheme.primaryNeon : AppTheme.glassBg,
          child: Icon(
            isEnrolled ? Icons.play_arrow : Icons.lock,
            color: isEnrolled ? AppTheme.darkBg : Colors.white54,
          ),
        ),
        title: Text(
          lesson.title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(lesson.formattedDuration),
        trailing: isEnrolled
            ? Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryNeon)
            : null,
        onTap: onTap,
      ),
    );
  }
}