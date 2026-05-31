import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

bool isVideoPath(String path) {
  final lower = path.toLowerCase();
  return ['.mp4', '.mov', '.avi', '.mkv', '.m4v', '.3gp'].any(lower.endsWith);
}

// ── Full-screen media viewer ──────────────────────────────────────────────
class MediaViewerScreen extends StatefulWidget {
  final List<String> mediaPaths;
  final int initialIndex;
  const MediaViewerScreen({super.key, required this.mediaPaths, this.initialIndex = 0});
  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageCtrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Media pages
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.mediaPaths.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final path = widget.mediaPaths[i];
              return isVideoPath(path)
                  ? _VideoPage(path: path)
                  : _PhotoPage(path: path);
            },
          ),

          // ── Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  _circleBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                  const Spacer(),
                  if (widget.mediaPaths.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_current + 1} / ${widget.mediaPaths.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(width: 6),
                  _circleBtn(
                    isVideoPath(widget.mediaPaths[_current]) ? Icons.videocam_outlined : Icons.image_outlined,
                    null,
                  ),
                ],
              ),
            ),
          ),

          // ── Dots
          if (widget.mediaPaths.length > 1)
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.mediaPaths.length, (i) => GestureDetector(
                  onTap: () => _pageCtrl.animateToPage(i,
                      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 22 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: _current == i ? AppColors.accent : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// ── Photo page with pinch-zoom ────────────────────────────────────────────
class _PhotoPage extends StatelessWidget {
  final String path;
  const _PhotoPage({required this.path});

  // <-- Modified to handle network image paths
  @override
  Widget build(BuildContext context) => InteractiveViewer(
    minScale: 0.5, maxScale: 5.0,
    child: Center(
      child: (path.startsWith('http://') || path.startsWith('https://'))
          ? Image.network(path, fit: BoxFit.contain)
          : Image.file(File(path), fit: BoxFit.contain),
    ),
  );
}

// ── Video page ────────────────────────────────────────────────────────────
class _VideoPage extends StatefulWidget {
  final String path;
  const _VideoPage({required this.path});
  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _showCtrl = true;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) { if (mounted) setState(() => _initialized = true); })
      ..addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _dur(Duration d) => '${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    return GestureDetector(
      onTap: () => setState(() => _showCtrl = !_showCtrl),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          Center(child: AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl))),
          // Controls
          AnimatedOpacity(
            opacity: _showCtrl ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                // Progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    VideoProgressIndicator(_ctrl, allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.accent,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(_dur(_ctrl.value.position),
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                      const Spacer(),
                      Text(_dur(_ctrl.value.duration),
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                  ]),
                ),
                // Play/Pause
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: IconButton(
                    iconSize: 56,
                    icon: Icon(
                      _ctrl.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable: small video thumbnail widget ────────────────────────────────
class VideoThumbnailWidget extends StatefulWidget {
  final String path;
  final double height;
  const VideoThumbnailWidget({super.key, required this.path, this.height = 80});
  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) { _ctrl!.seekTo(Duration.zero); setState(() => _ready = true); }
      });
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: widget.height, width: double.infinity,
          color: AppColors.textPrimary,
          child: _ready
              ? AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!))
              : const SizedBox.expand(),
        ),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
        ),
        Positioned(
          bottom: 6, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.videocam, size: 10, color: Colors.white),
              SizedBox(width: 3),
              Text('Video', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ],
    );
  }
}