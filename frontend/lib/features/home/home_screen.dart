import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/theme/app_theme.dart';
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

  // ── Input capture ─────────────────────────────────────────────────────────

  Future<void> _captureImage() async {
    if (!_cameraReady || _cameraController == null) return;
    try {
      final xFile = await _cameraController!.takePicture();
      ref.read(searchProvider.notifier).captureImage(xFile.path);
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
    }
  }

  // ── Text search bottom sheet ──────────────────────────────────────────────

  Future<void> _openTextSearch() async {
    final ctrl = TextEditingController();
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search by text',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. red running shoes size 10',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                ),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
          ],
        ),
      ),
    );

    if (submitted != null && submitted.isNotEmpty && mounted) {
      ref.read(searchProvider.notifier).captureText(submitted);
      _goSearch();
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _goSearch() {
    ref.read(searchProvider.notifier).analyzeInputs();
    context.push('/processing');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final hasImage = state.capturedImagePath != null;
    final hasAudio = state.capturedAudioPath != null;
    final hasText  = state.capturedText != null && state.capturedText!.isNotEmpty;
    final hasInput = hasImage || hasAudio || hasText;

    final instruction = _isRecording
        ? 'Release to finish recording…'
        : hasImage && hasAudio
            ? 'Both inputs ready — tap Search!'
            : hasImage
                ? 'Image captured · Hold mic to add voice hint'
                : hasAudio
                    ? 'Voice recorded · Tap camera for photo too'
                    : hasText
                        ? 'Text ready — tap Search!'
                        : 'Tap camera · Hold mic · Or type your query';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ──────────────────────────────────────────────
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

          // ── Captured-image overlay (dim camera + show thumbnail) ────────
          if (hasImage)
            Positioned.fill(
              child: Container(color: Colors.black54),
            ),
          if (hasImage)
            Positioned.fill(
              child: Opacity(
                opacity: 0.5,
                child: Image.file(
                  File(state.capturedImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
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
                  instruction,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // ── Input badges (top-right area) ───────────────────────────────
          Positioned(
            top: 96,
            right: 16,
            child: Column(
              children: [
                if (hasImage)
                  _InputBadge(
                    icon: Icons.image,
                    label: 'Photo',
                    color: AppTheme.primary,
                    onClear: () =>
                        ref.read(searchProvider.notifier).clearImage(),
                  ),
                if (hasAudio) ...[
                  if (hasImage) const SizedBox(height: 8),
                  _InputBadge(
                    icon: Icons.mic,
                    label: 'Audio',
                    color: Colors.orange,
                    onClear: () =>
                        ref.read(searchProvider.notifier).clearAudio(),
                  ),
                ],
                if (hasText) ...[
                  if (hasImage || hasAudio) const SizedBox(height: 8),
                  _InputBadge(
                    icon: Icons.keyboard,
                    label: 'Text',
                    color: Colors.purple,
                    onClear: () =>
                        ref.read(searchProvider.notifier).clearText(),
                  ),
                ],
              ],
            ),
          ),

          // ── Search button (appears when inputs are ready) ───────────────
          if (hasInput)
            Positioned(
              bottom: 152,
              left: 40,
              right: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.5),
                ),
                icon: const Icon(Icons.search, size: 20),
                label: const Text(
                  'Search',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: _goSearch,
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
                    hasBadge: hasAudio && !_isRecording,
                  ),
                ),

                // Shutter
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: hasImage ? AppTheme.primary : Colors.white,
                          width: 4),
                      color: hasImage
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : Colors.white24,
                    ),
                    child: Icon(
                      hasImage ? Icons.replay : Icons.camera_alt,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

                // Gallery picker (shows green badge when image is loaded via gallery)
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: const _ControlButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    hasBadge: false,
                  ),
                ),

                // Text search
                GestureDetector(
                  onTap: _openTextSearch,
                  child: _ControlButton(
                    icon: Icons.keyboard_alt_outlined,
                    label: 'Type',
                    hasBadge: hasText,
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final Color    activeColor;
  final bool     hasBadge;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.active      = false,
    this.activeColor = Colors.white24,
    this.hasBadge    = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: active ? activeColor : Colors.white24,
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            if (hasBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _InputBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onClear;

  const _InputBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 13, color: color),
          ),
        ],
      ),
    );
  }
}
