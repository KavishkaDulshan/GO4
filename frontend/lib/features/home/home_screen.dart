import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../providers/search_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  CameraController? _cameraController;
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    // Reset any previous search state when returning to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).reset();
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      // Camera unavailable on this device / emulator
    }
  }

  Future<void> _captureAndSubmit() async {
    if (!_cameraReady || _cameraController == null) return;
    try {
      final xFile = await _cameraController!.takePicture();
      ref.read(searchProvider.notifier).captureImage(xFile.path);
      ref.read(searchProvider.notifier).submitSearch();
      if (mounted) context.push('/processing');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    ref.read(searchProvider.notifier).captureImage(xFile.path);
    ref.read(searchProvider.notifier).submitSearch();
    if (mounted) context.push('/processing');
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      ref.read(searchProvider.notifier).captureAudio(path);
      // Immediately submit a voice-only search so mic release triggers a result
      ref.read(searchProvider.notifier).submitSearch();
      if (mounted) context.push('/processing');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ─────────────────────────────────────────────
          if (_cameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white54),
                  SizedBox(height: 12),
                  Text('Starting camera…',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),

          // ── Top instruction bar ─────────────────────────────────────────
          Positioned(
            top: 52,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isRecording
                      ? 'Release to search by voice…'
                      : 'Tap camera · Hold mic to voice search',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),

          // ── Bottom controls ─────────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Hold-to-record mic
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: _ControlButton(
                    icon: Icons.mic,
                    active: _isRecording,
                    activeColor: Colors.redAccent,
                    label: 'Hold',
                  ),
                ),

                // Shutter
                GestureDetector(
                  onTap: _captureAndSubmit,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white24,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 36),
                  ),
                ),

                // Gallery picker
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: const _ControlButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.activeColor = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: active ? activeColor : Colors.white24,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
