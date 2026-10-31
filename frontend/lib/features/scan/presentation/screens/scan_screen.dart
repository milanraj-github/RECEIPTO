import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/scan/presentation/widgets/ai_pulse_point.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/features/scan/presentation/providers/scan_provider.dart';
import 'package:receipto/features/scan/data/repositories/scan_repository.dart';
import 'package:receipto/features/scan/presentation/screens/preview_scan_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isCameraPermissionGranted = true;
  bool _isCameraInitializing = false;
  bool _isFlashSupported = true;
  bool _isRearCamera = true;
  bool _isBatchMode = false;
  final List<File> _batchFiles = [];

  // Camera Flash Modes cycle: Off(0) -> Auto(1) -> On(2) -> Off(0)
  // Stored as the current FlashMode enum directly for reliable hardware mapping
  FlashMode _currentFlashMode = FlashMode.off;

  IconData get _flashIcon {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
      case FlashMode.always:
        return Icons.flash_on;
    }
  }

  Color get _flashColor {
    if (!_isFlashSupported || !_isRearCamera) return Colors.white30;
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Colors.white54;
      case FlashMode.auto:
        return AppColors.primary;
      case FlashMode.torch:
      case FlashMode.always:
        return AppColors.secondary;
    }
  }


  FlashMode _nextFlashMode(FlashMode current) {
    // Cycle: Off -> Auto -> On (torch) -> Off
    switch (current) {
      case FlashMode.off:
        return FlashMode.auto;
      case FlashMode.auto:
        return FlashMode.torch;
      case FlashMode.torch:
      case FlashMode.always:
        return FlashMode.off;
    }
  }

  static const double scanningRectWidthRatio = 0.78;
  static const double scanningRectHeightRatio = 0.48;

  @override
  void initState() {
    super.initState();

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_scannerController);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _initCamera();
  }

  @override
  void dispose() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.setFlashMode(FlashMode.off).catchError((_) {});
    }
    _cameraController?.dispose();
    _scannerController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;

    try {
      // Ensure camera permission is granted
      final status = await Permission.camera.request();
      debugPrint('[Flash] Camera permission status: $status');
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _isCameraPermissionGranted = false;
            _isCameraInitializing = false;
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isCameraPermissionGranted = false;
          _isCameraInitializing = false;
        });
        return;
      }

      final backIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = backIndex != -1 ? backIndex : 0;

      await _setupCameraController();
    } catch (e) {
      debugPrint('[Flash] Error in _initCamera: $e');
      if (mounted) {
        setState(() {
          _isCameraPermissionGranted = false;
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _setupCameraController() async {
    if (_cameras.isEmpty) return;

    // Detect whether the selected camera is rear-facing (only rear supports flash)
    final selectedCamera = _cameras[_cameraIndex];
    final isRear = selectedCamera.lensDirection == CameraLensDirection.back;

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();

      // Print required debug logs on successful initialization
      debugPrint('Camera Initialized');
      debugPrint('Camera Description: ${selectedCamera.toString()}');
      debugPrint('Current Lens: ${selectedCamera.lensDirection}');
      debugPrint('Current Flash Mode: $_currentFlashMode');

      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (_) {}

      try {
        await _cameraController!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isCameraPermissionGranted = true;
          _isCameraInitializing = false;
          _isRearCamera = isRear;
        });

        // Crucial Fix: Apply flash mode only AFTER the first frame is drawn so that
        // the CameraPreview surface/texture is fully attached on the Android side.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Add a brief delay to ensure native driver finishes pipeline binding
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            final modeToApply = isRear ? _currentFlashMode : FlashMode.off;
            final flashOk = await _applyFlashModeHardware(modeToApply);
            setState(() {
              _isFlashSupported = flashOk || !isRear;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[Flash] Camera setup failed: $e');
      if (mounted) {
        setState(() {
          _isCameraPermissionGranted = false;
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.isEmpty || _isCameraInitializing) return;

    // Turn off torch before flipping to avoid hardware state conflict
    if (_currentFlashMode == FlashMode.torch) {
      await _applyFlashModeHardware(FlashMode.off);
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _setupCameraController();
  }

  /// HARDWARE-ONLY: Applies flash mode directly to the CameraController.
  /// Does NOT call setState — safe to call inside async chains without triggering rebuilds.
  Future<bool> _applyFlashModeHardware(FlashMode mode) async {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      debugPrint('[Flash] Cannot apply $mode — controller not ready.');
      return false;
    }

    debugPrint('[Flash] Applying $mode ...');
    try {
      await ctrl.setFlashMode(mode);
      debugPrint('[Flash] ✅ Applied $mode successfully.');

      // Print required debug logs matching mode names exactly
      if (mode == FlashMode.off) {
        debugPrint('Flash Mode -> OFF');
      } else if (mode == FlashMode.auto) {
        debugPrint('Flash Mode -> AUTO');
      } else if (mode == FlashMode.torch) {
        debugPrint('Flash Mode -> TORCH');
      } else if (mode == FlashMode.always) {
        debugPrint('Flash Mode -> ALWAYS');
      }

      return true;
    } on CameraException catch (e) {
      debugPrint('[Flash] ❌ CameraException applying $mode: ${e.code} — ${e.description}');
      debugPrint('Any exception from setFlashMode(): $e');

      // Gracefully fallback if FlashMode.auto is not supported
      if (mode == FlashMode.auto && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto Flash is not supported on this device.'),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 2),
          ),
        );
        // Fallback to OFF
        _currentFlashMode = FlashMode.off;
        await ctrl.setFlashMode(FlashMode.off);
      }

      return false;
    } catch (e) {
      debugPrint('[Flash] ❌ Unknown error applying $mode: $e');
      debugPrint('Any exception from setFlashMode(): $e');
      return false;
    }
  }

  /// Cycles flash mode: Off -> Auto -> On (torch) -> Off
  /// Called when user taps the flash button.
  Future<void> _cycleFlashMode() async {
    debugPrint('Flash button pressed');
    debugPrint('Flash button tapped');
    if (!_isRearCamera) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash is not available on the front camera.'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final next = _nextFlashMode(_currentFlashMode);
    debugPrint('[Flash] Cycle: $_currentFlashMode -> $next');

    // Apply to hardware FIRST before updating UI
    final ok = await _applyFlashModeHardware(next);

    if (mounted) {
      setState(() {
        _currentFlashMode = next;
        _isFlashSupported = ok || next == FlashMode.off; // off always succeeds conceptually
      });
    }

    if (!ok && next != FlashMode.off && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash is not supported on this device.'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Selects a specific flash mode from the popup menu.
  Future<void> _selectFlashMode(FlashMode mode) async {
    debugPrint('Flash mode selected');
    if (!_isRearCamera) return;
    debugPrint('[Flash] Select from menu: $mode');

    final ok = await _applyFlashModeHardware(mode);

    if (mounted) {
      setState(() {
        _currentFlashMode = mode;
        _isFlashSupported = ok || mode == FlashMode.off;
      });
    }

    if (!ok && mode != FlashMode.off && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash is not supported on this device.'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Shows a native-style popup menu for selecting flash mode.
  void _showFlashMenu(BuildContext context) {
    debugPrint('Opening flash menu');
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<FlashMode>(
      context: context,
      position: position,
      color: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      items: [
        PopupMenuItem<FlashMode>(
          value: FlashMode.off,
          child: _flashMenuItem(
            icon: Icons.flash_off,
            label: 'Off',
            color: Colors.white54,
            selected: _currentFlashMode == FlashMode.off,
          ),
        ),
        PopupMenuItem<FlashMode>(
          value: FlashMode.auto,
          child: _flashMenuItem(
            icon: Icons.flash_auto,
            label: 'Auto',
            color: AppColors.primary,
            selected: _currentFlashMode == FlashMode.auto,
          ),
        ),
        PopupMenuItem<FlashMode>(
          value: FlashMode.torch,
          child: _flashMenuItem(
            icon: Icons.flash_on,
            label: 'On',
            color: AppColors.secondary,
            selected: _currentFlashMode == FlashMode.torch,
          ),
        ),
      ],
    ).then((selected) {
      if (selected != null) {
        _selectFlashMode(selected);
      }
    });
  }

  Widget _flashMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool selected,
  }) {
    return Row(
      children: [
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? color : Colors.white38, size: 16),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? color : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _triggerCapture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCameraInitializing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera preview is not ready.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // For capture: if user selected torch (On), switch to FlashMode.always so it fires during capture.
    // For auto and off, leave as-is — the camera driver handles it.
    final previewMode = _currentFlashMode;
    if (_isRearCamera && _isFlashSupported && previewMode == FlashMode.torch) {
      debugPrint('[Flash] Switching torch -> always for capture...');
      await _applyFlashModeHardware(FlashMode.always);
    }

    // Show full screen shutter flash feedback
    _flashController.forward().then((_) {
      _flashController.reverse();
    });

    try {
      debugPrint('[Flash] Taking picture...');
      final XFile rawImage = await _cameraController!.takePicture();
      debugPrint('[Flash] Picture captured.');

      // Restore preview flash mode after capture
      if (_isRearCamera && _isFlashSupported && previewMode == FlashMode.torch) {
        debugPrint('[Flash] Restoring torch mode after capture...');
        await _applyFlashModeHardware(FlashMode.torch);
      }

      final File file = File(rawImage.path);

      if (_isBatchMode) {
        setState(() {
          _batchFiles.add(file);
        });
        ref.read(scanProvider.notifier).setCapturedImages(_batchFiles);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Page ${_batchFiles.length} captured! Snap next or review.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E202C),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 230, left: 24, right: 24),
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.4)),
              ),
            ),
          );
        }
        return;
      }

      ref.read(scanProvider.notifier).setCapturedImage(file);

      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PreviewScanScreen(imageFile: file),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      // Restore flash mode on error
      if (_isRearCamera && _isFlashSupported && previewMode == FlashMode.torch) {
        await _applyFlashModeHardware(FlashMode.torch);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Opens the batch review screen with all sequentially captured pages
  void _openBatchReview() {
    if (_batchFiles.isEmpty) return;
    ref.read(scanProvider.notifier).setCapturedImages(_batchFiles);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PreviewScanScreen(
          imageFile: _batchFiles.first,
          batchFiles: List.from(_batchFiles),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      if (mounted && (ref.read(scanProvider).isAccepted || ref.read(scanProvider).capturedImages == null)) {
        setState(() {
          _batchFiles.clear();
        });
      }
    });
  }

  /// Universal Document & File Upload Picker: supports Images (jpg, png, heic), PDFs, Documents, File Manager
  Future<void> _triggerUpload() async {
    try {
      final file = await ref.read(scanRepositoryProvider).selectReceiptFile();
      if (file != null) {
        ref.read(scanProvider.notifier).setCapturedImage(file);

        if (mounted) {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => PreviewScanScreen(imageFile: file),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;
    final frameWidth = MediaQuery.of(context).size.width * scanningRectWidthRatio;
    final frameHeight = MediaQuery.of(context).size.height * scanningRectHeightRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          Positioned.fill(
            child: _isCameraPermissionGranted && _cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : Container(
                    color: AppColors.background,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
          ),

          // 2. Full-Width Premium Dark Glass Header Bar (Profile Avatar, Receipto Title, Notification, Flash Mode Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Profile Avatar (Left)
                              GestureDetector(
                                onTap: () {
                                  StatefulNavigationShell.of(context).goBranch(4);
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Receipto Title
                              Text(
                                'Receipto',
                                style: Theme.of(context).textTheme.headlineMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              // Notification Button
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 22),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 4),

                              // Flash Mode Button: Tap to cycle Off->Auto->On->Off, long press for menu
                              Builder(
                                builder: (btnCtx) => GestureDetector(
                                  onTap: _cycleFlashMode,
                                  onLongPress: () => _showFlashMenu(btnCtx),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      _flashIcon,
                                      color: _flashColor,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. "AI Detecting..." Status Pill & Guidance Text Below Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // AI Detecting... Status Pill with AIPulsePoint
                GlassCard(
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AIPulsePoint(),
                      const SizedBox(width: 10),
                      Text(
                        'AI Detecting...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Align Receipt text
                Text(
                  'Align receipt within the frame',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 4. Original Neon Cyan Scanner Frame with Thin Grid Lines, Floating AI Dots & Animated Scan Line
          Center(
            child: Container(
              width: frameWidth,
              height: frameHeight,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Thin 3x3 Grid Lines inside the frame
                  CustomPaint(
                    size: Size(frameWidth, frameHeight),
                    painter: GridPainter(),
                  ),

                  // Floating Glowing AI Dots inside the scan frame
                  const Positioned(
                    top: 30,
                    left: 40,
                    child: AIPulsePoint(delay: 0),
                  ),
                  const Positioned(
                    top: 120,
                    right: 50,
                    child: AIPulsePoint(delay: 500),
                  ),
                  const Positioned(
                    bottom: 40,
                    left: 60,
                    child: AIPulsePoint(delay: 1000),
                  ),

                  // Corner Accents
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),

                  // Animated Horizontal Scan Line Sweep
                  AnimatedBuilder(
                    animation: _scannerAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scannerAnimation.value * (frameHeight - 4),
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.laserCyan,
                                AppColors.prismMagenta,
                                AppColors.laserCyan,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.laserCyan.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: AppColors.prismMagenta.withValues(alpha: 0.6),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Shutter Flash Feedback Overlay (Wrapped in IgnorePointer to prevent touch blocking)
          IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _flashAnimation.value,
                  child: Container(color: Colors.white),
                );
              },
            ),
          ),

          // 6. Unified Camera Bottom Panel: Batch Review Badge + Mode Switcher + Shutter Controls
          Positioned(
            bottom: 95, // Positioned comfortably above Bottom Navigation Bar
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Batch Review Action Button (shown when batch has captured pages)
                if (_isBatchMode && _batchFiles.isNotEmpty) ...[
                  GestureDetector(
                    onTap: _openBatchReview,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_batchFiles.length}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Review ${_batchFiles.length} ${_batchFiles.length == 1 ? "Page" : "Pages"}',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _batchFiles.clear();
                              });
                              ref.read(scanProvider.notifier).resetCapturedImage();
                            },
                            child: const Icon(Icons.close_rounded, color: Colors.black87, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Single vs Batch Mode Segmented Pill (strictly placed ABOVE shutter controls)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Single Mode
                          GestureDetector(
                            onTap: () {
                              if (_isBatchMode) {
                                setState(() {
                                  _isBatchMode = false;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_isBatchMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.crop_portrait_rounded,
                                    size: 14,
                                    color: !_isBatchMode ? Colors.black : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Single',
                                    style: GoogleFonts.inter(
                                      color: !_isBatchMode ? Colors.black : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: !_isBatchMode ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Batch Mode (Multi-Page)
                          GestureDetector(
                            onTap: () {
                              if (!_isBatchMode) {
                                setState(() {
                                  _isBatchMode = true;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isBatchMode ? AppColors.secondary : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_motion_rounded,
                                    size: 14,
                                    color: _isBatchMode ? Colors.black : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Batch (Multi-Page)',
                                    style: GoogleFonts.inter(
                                      color: _isBatchMode ? Colors.black : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: _isBatchMode ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  if (_batchFiles.isNotEmpty) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_batchFiles.length}',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Consolidated Premium Glass Control Panel (Upload, Capture, Flip Camera)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Upload Button (Images, PDFs, Documents, File Manager)
                          IconButton(
                            icon: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 26),
                            onPressed: _triggerUpload,
                            tooltip: 'Upload Receipt (Image/PDF/Doc)',
                          ),

                          // Center Manual Shutter Capture Button
                          GestureDetector(
                            onTap: _triggerCapture,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isBatchMode ? AppColors.secondary : Colors.white,
                                      width: 3.5,
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isBatchMode ? AppColors.secondary : Colors.white,
                                      ),
                                      child: _isBatchMode
                                          ? const Center(
                                              child: Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 24,
                                                color: Colors.black,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                if (_isBatchMode && _batchFiles.isNotEmpty)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                      child: Center(
                                        child: Text(
                                          '${_batchFiles.length}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Flip Camera Button (Right)
                          IconButton(
                            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white, size: 26),
                            onPressed: _flipCamera,
                            tooltip: 'Flip Camera',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    // Top corners: Laser Cyan glow; Bottom corners: Prism Magenta / Neon Pink glow
    final cornerColor = isTop ? AppColors.laserCyan : AppColors.prismMagenta;

    return Align(
      alignment: alignment,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: cornerColor.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          border: Border(
            top: isTop ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
            left: isLeft ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
            right: !isLeft ? BorderSide(color: cornerColor, width: 3.5) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    final stepX = size.width / 3;
    final stepY = size.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(stepX * i, 0), Offset(stepX * i, size.height), paint);
      canvas.drawLine(Offset(0, stepY * i), Offset(size.width, stepY * i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
