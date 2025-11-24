import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const VideoApp());
}

class VideoApp extends StatelessWidget {
  const VideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VideoPlayerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isVideoSelected = false;
  String? _fileName;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      // اختيار ملف الفيديو
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.single;
        
        // التأكد من التخلص من المتحكم السابق إذا وجد
        if (_controller != null) {
          await _controller!.dispose();
        }

        VideoPlayerController newController;

        if (kIsWeb) {
          // للويب: نستخدم المسار كـ Blob URL أو bytes إذا لزم الأمر
          // في الإصدارات الحديثة من file_picker للويب، path قد يكون null، لذا نستخدم bytes
          if (file.bytes != null) {
             // ملاحظة: video_player للويب يدعم الشبكة (network) بشكل أساسي.
             // للتبسيط هنا سنستخدم network إذا توفر مسار (blob url)
             // أو يمكن استخدام طريقة أخرى، لكن file_picker على الويب يعيد path كـ blob url أحياناً
             if (file.path != null) {
               newController = VideoPlayerController.networkUrl(Uri.parse(file.path!));
             } else {
               // fallback logic specifically for web bytes handling requires more complex setup
               // so we rely on path (blob url) which file_picker usually provides on web
               return; 
             }
          } else if (file.path != null) {
             newController = VideoPlayerController.networkUrl(Uri.parse(file.path!));
          } else {
            return;
          }
        } else {
          // للديسكوتوب والموبايل: نستخدم ملف محلي
          if (file.path != null) {
            newController = VideoPlayerController.file(File(file.path!));
          } else {
            return;
          }
        }

        setState(() {
          _fileName = file.name;
        });

        await newController.initialize();
        
        setState(() {
          _controller = newController;
          _isVideoSelected = true;
        });
        
        // تشغيل الفيديو تلقائياً
        _controller!.play();
      }
    } catch (e) {
      debugPrint("Error picking video: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الفيديو: $e')),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشغل الفيديو البسيط'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isVideoSelected && _controller != null && _controller!.value.isInitialized)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller!),
                        _ControlsOverlay(controller: _controller!, onToggle: _togglePlayPause),
                        VideoProgressIndicator(_controller!, allowScrubbing: true),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.video_library_outlined, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      'لم يتم اختيار فيديو بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('تحميل فيديو'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                  if (_isVideoSelected)
                    Text(
                      _fileName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onToggle;

  const _ControlsOverlay({required this.controller, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: ColoredBox(
        color: Colors.transparent,
        child: Center(
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 80.0,
                  ),
                ),
        ),
      ),
    );
  }
}
