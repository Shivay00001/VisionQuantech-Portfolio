import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/lesson.dart';
import '../../theme/theme.dart';

class LessonPlayerPage extends StatefulWidget {
  final String lessonId;
  final String courseId;

  const LessonPlayerPage({
    super.key,
    required this.lessonId,
    required this.courseId,
  });

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  Lesson? _currentLesson;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final user = context.read<User?>();
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final firestoreService = context.read<FirestoreService>();
      final lesson = await firestoreService.getLessonById(widget.lessonId, user.uid);

      if (lesson == null || lesson.ytId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This lesson is locked. Please enroll in the course first.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _currentLesson = lesson;
      });

      _controller = YoutubePlayerController.fromVideoId(
        videoId: lesson.ytId,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          enableCaption: true,
          captionLanguage: 'en',
          strictRelatedVideos: true,
          privacyEnhanced: true,
          playsInline: false,
        ),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(_currentLesson?.title ?? 'Loading...'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Video Player Frame
                  _buildVideoPlayer(),

                  // Lesson Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentLesson?.title ?? '',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.primaryNeon,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentLesson?.formattedDuration ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Next Lessons Section
                        _buildNextLessons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // YouTube Player
            YoutubePlayer(
              controller: _controller!,
              aspectRatio: 16 / 9,
            ),

            // Custom Glassmorphic Overlay (Top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextLessons() {
    return StreamBuilder<List<Lesson>>(
      stream: context.read<FirestoreService>().getLessonsByCourse(widget.courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final lessons = snapshot.data!;
        final currentIndex = lessons.indexWhere((l) => l.id == widget.lessonId);

        if (currentIndex == -1 || currentIndex >= lessons.length - 1) {
          return const SizedBox.shrink();
        }

        final nextLessons = lessons.skip(currentIndex + 1).take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Up Next',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ...nextLessons.map((lesson) => _buildNextLessonCard(lesson)),
          ],
        );
      },
    );
  }

  Widget _buildNextLessonCard(Lesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassBox(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryNeon,
          child: Icon(Icons.play_arrow, color: AppTheme.darkBg),
        ),
        title: Text(
          lesson.title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(lesson.formattedDuration),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryNeon),
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LessonPlayerPage(
                lessonId: lesson.id,
                courseId: widget.courseId,
              ),
            ),
          );
        },
      ),
    );
  }
}