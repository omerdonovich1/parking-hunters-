import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers/report_provider.dart';
import '../../../services/location_service.dart';
import '../../../services/ai_scan_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../providers/locale_provider.dart';
import 'widgets/success_animation.dart';

// Maximum allowed GPS accuracy in metres.
const double _kMaxAccuracyMeters = 15.0;
// How long to wait for a good GPS fix before giving up.
const Duration _kGpsTimeout = Duration(seconds: 15);

enum _FlowState {
  lockingGps,   // acquiring GPS ≤15m
  gpsFailed,    // could not get accuracy ≤15m in time
  waitingCamera,// camera picker open (or about to open)
  scanning,     // AI scan in progress
  rejected,     // AI says not a free spot
}

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with TickerProviderStateMixin {
  _FlowState _flow = _FlowState.lockingGps;
  double? _lat;
  double? _lng;
  double? _accuracy;
  String _address = '';
  bool _showSuccess = false;

  final LocationService _locationService = LocationService();

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _lockController;

  @override
  void initState() {
    super.initState();

    _scanAnimController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanAnimController);

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _lockController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

    // Kick off GPS lock immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _lockLocation());
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _pulseController.dispose();
    _lockController.dispose();
    super.dispose();
  }

  // ── GPS acquisition ────────────────────────────────────────────────────────

  Future<void> _lockLocation() async {
    setState(() => _flow = _FlowState.lockingGps);

    // On web Geolocator accuracy is capped by the browser; skip strict check.
    if (kIsWeb) {
      try {
        final pos = await _locationService.getCurrentPosition();
        await _onGpsLocked(pos);
      } catch (_) {
        if (mounted) setState(() => _flow = _FlowState.gpsFailed);
      }
      return;
    }

    // On native: stream positions until accuracy ≤ 15m or timeout.
    final completer = Completer<Position>();
    StreamSubscription<Position>? sub;

    sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(
      (pos) {
        if (!completer.isCompleted && pos.accuracy <= _kMaxAccuracyMeters) {
          completer.complete(pos);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    // Timeout fallback — accept whatever accuracy we have.
    Future.delayed(_kGpsTimeout, () {
      if (!completer.isCompleted) {
        sub?.cancel();
        completer.completeError('timeout');
      }
    });

    try {
      final pos = await completer.future;
      sub.cancel();
      if (!mounted) return;
      if (pos.accuracy > _kMaxAccuracyMeters) {
        setState(() => _flow = _FlowState.gpsFailed);
      } else {
        await _onGpsLocked(pos);
      }
    } catch (_) {
      sub?.cancel();
      // Try a single high-accuracy fallback before declaring failure.
      try {
        final pos = await _locationService.getCurrentPosition();
        if (!mounted) return;
        if (pos.accuracy <= _kMaxAccuracyMeters) {
          await _onGpsLocked(pos);
        } else {
          if (mounted) setState(() => _flow = _FlowState.gpsFailed);
        }
      } catch (e2) {
        if (mounted) setState(() => _flow = _FlowState.gpsFailed);
      }
    }
  }

  Future<void> _onGpsLocked(Position pos) async {
    HapticFeedback.mediumImpact();
    final address = await _locationService.getAddressFromCoords(
        pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _accuracy = pos.accuracy;
      _address = address;
      _flow = _FlowState.waitingCamera;
    });
    // Brief pause so user sees the "locked" state, then auto-open camera.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _openCamera();
  }

  // ── Camera ─────────────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    if (_lat == null) return;
    await ref.read(reportProvider.notifier).pickImage(fromCamera: true);
    if (!mounted) return;
    final imagePath = ref.read(reportProvider).selectedImagePath;
    if (imagePath != null) {
      setState(() => _flow = _FlowState.scanning);
      await _runAiScan();
    }
    // If imagePath == null, user cancelled — stay on waitingCamera.
  }

  // ── AI scan + auto-submit ──────────────────────────────────────────────────

  Future<void> _runAiScan() async {
    final result = await ref.read(reportProvider.notifier).scanWithAI();
    if (!mounted) return;

    if (result != null && result.isFree) {
      // Approved — auto-submit immediately.
      await _submitReport();
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _flow = _FlowState.rejected);
    }
  }

  Future<void> _submitReport() async {
    if (_lat == null || _lng == null) return;
    HapticFeedback.heavyImpact();
    await ref.read(reportProvider.notifier).submitReport(
      lat: _lat!,
      lng: _lng!,
      estimatedMinutes: 30,
    );
    final s = ref.read(reportProvider);
    if (s.isSuccess && mounted) {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.heavyImpact();
      setState(() => _showSuccess = true);
      if (s.newBadgeId != null) {
        final str = ref.read(appStringsProvider);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            showToast(context,
              type: ToastType.warning,
              title: str.badgeUnlocked,
              subtitle: s.newBadgeId!.replaceAll('_', ' '),
              duration: const Duration(seconds: 4),
            );
          }
        });
      }
    }
  }

  void _onSuccessDismissed() {
    setState(() => _showSuccess = false);
    ref.read(reportProvider.notifier).reset();
    context.go('/');
  }

  // ── Step index helper (for indicator) ────────────────────────────────────

  int get _stepIndex {
    switch (_flow) {
      case _FlowState.lockingGps:
      case _FlowState.gpsFailed:
        return 0;
      case _FlowState.waitingCamera:
        return 1;
      case _FlowState.scanning:
      case _FlowState.rejected:
        return 2;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final s = ref.watch(appStringsProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(s),
                _buildStepIndicator(),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(reportState, s)),
              ],
            ),
          ),
        ),
        if (_showSuccess)
          Positioned.fill(
              child: SuccessAnimation(onDismiss: _onSuccessDismissed)),
      ],
    );
  }

  Widget _buildHeader(AppStrings s) {
    final titles = [s.stepGpsLock, s.stepTakePhoto, s.stepAiScan];
    final subs   = [s.stepSubGps,  s.stepSubPhoto,  s.stepSubAi];
    final idx    = _stepIndex.clamp(0, 2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white54, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titles[idx],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text(subs[idx],
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12)),
              ],
            ),
          ),
          Text('${idx + 1}/3',
              style: const TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final idx = _stepIndex.clamp(0, 2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == idx;
          final isDone   = i < idx;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: isDone
                            ? const LinearGradient(
                                colors: [AppTheme.orange, AppTheme.orange])
                            : null,
                        color: isDone
                            ? null
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 28 : 20,
                  height: isActive ? 28 : 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppTheme.orange
                        : isDone
                            ? AppTheme.neonGreen
                            : Colors.white.withValues(alpha: 0.1),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: AppTheme.orange.withValues(alpha: 0.5),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : Text('${i + 1}',
                            style: TextStyle(
                                color:
                                    isActive ? Colors.white : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody(ReportState reportState, AppStrings s) {
    switch (_flow) {
      case _FlowState.lockingGps:
        return _buildGpsLockingView(s);
      case _FlowState.gpsFailed:
        return _buildGpsFailedView(s);
      case _FlowState.waitingCamera:
        return _buildWaitingCameraView(s);
      case _FlowState.scanning:
        return _buildScanningView(reportState, s);
      case _FlowState.rejected:
        return _buildRejectedView(reportState, s);
    }
  }

  // ── GPS LOCKING ────────────────────────────────────────────────────────────

  Widget _buildGpsLockingView(AppStrings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _lockController,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                // Outer spinning ring
                Transform.rotate(
                  angle: _lockController.value * 2 * 3.14159,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.neonGreen.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomPaint(
                        painter: _ArcPainter(
                            color: AppTheme.neonGreen,
                            progress: _lockController.value),
                      ),
                    ),
                  ),
                ),
                // Inner pulsing circle
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 80 + 8 * _pulseController.value,
                    height: 80 + 8 * _pulseController.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.neonGreen.withValues(
                          alpha: 0.08 + 0.04 * _pulseController.value),
                      border: Border.all(
                        color: AppTheme.neonGreen.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.my_location_rounded,
                    color: AppTheme.neonGreen, size: 34),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(s.lockingGps,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 600.ms),
          const SizedBox(height: 8),
          Text(s.stepSubGps,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 32),
          // Accuracy bar — shows "searching"
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(AppTheme.neonGreen),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('${s.gpsAccuracyLabel}: < ${_kMaxAccuracyMeters.toInt()}m',
              style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  // ── GPS FAILED ─────────────────────────────────────────────────────────────

  Widget _buildGpsFailedView(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonRed.withValues(alpha: 0.12),
                border: Border.all(
                    color: AppTheme.neonRed.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(Icons.location_off_rounded,
                  color: AppTheme.neonRed, size: 38),
            ),
            const SizedBox(height: 24),
            Text(s.gpsTooLow,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _OrangeButton(
              onTap: _lockLocation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(s.gpsRetry,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WAITING CAMERA ─────────────────────────────────────────────────────────

  Widget _buildWaitingCameraView(AppStrings s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GPS locked badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: AppTheme.neonGreen.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.neonGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${s.gpsLocked} · ${_accuracy != null ? '${_accuracy!.toStringAsFixed(0)}m' : ''}',
                  style: const TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.orange.withValues(alpha: 0.15),
                border: Border.all(
                    color: AppTheme.orange.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.camera_alt,
                  color: AppTheme.orange, size: 44),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.openingCamera,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s.stepSubPhoto,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 32),
          _OrangeButton(
            onTap: _openCamera,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(s.openCamera,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  // ── SCANNING ───────────────────────────────────────────────────────────────

  Widget _buildScanningView(ReportState reportState, AppStrings s) {
    final hasResult = reportState.aiScanResult != null;
    final isScanning = reportState.isScanning;
    final result = reportState.aiScanResult;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          if (reportState.selectedImagePath != null)
            Expanded(
              child: _GlassCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(reportState.selectedImagePath!),
                        fit: BoxFit.cover,
                      ),
                      if (isScanning) _buildScanOverlay(),
                      if (hasResult && result!.isFree)
                        _buildApprovedOverlay(result, s),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (isScanning) const _ScanShimmerCard(),
          if (hasResult && result!.isFree) ...[
            _GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.neonGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.aiAutoSubmitting,
                        style: const TextStyle(
                            color: AppTheme.neonGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.neonGreen),
                  ),
                ],
              ),
            ),
          ],
          if (reportState.error != null && !isScanning) ...[
            const SizedBox(height: 8),
            _GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(reportState.error!,
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: _runAiScan,
                    child: Text(s.retry,
                        style: const TextStyle(
                            color: AppTheme.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: _scanAnim,
      builder: (context, _) => Stack(
        children: [
          Container(color: AppTheme.orange.withValues(alpha: 0.08)),
          Positioned(
            top: _scanAnim.value * 300,
            left: 0, right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  AppTheme.orange.withValues(alpha: 0.8),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedOverlay(AiScanResult result, AppStrings s) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            color: Colors.black.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.neonGreen, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.freeSpotConfirmed,
                          style: const TextStyle(
                              color: AppTheme.neonGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      Text(result.reason,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          maxLines: 2),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.neonGreen.withValues(alpha: 0.5)),
                  ),
                  child: Text('${result.confidence}%',
                      style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── REJECTED ───────────────────────────────────────────────────────────────

  Widget _buildRejectedView(ReportState reportState, AppStrings s) {
    final result = reportState.aiScanResult;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          if (reportState.selectedImagePath != null)
            Expanded(
              child: _GlassCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(reportState.selectedImagePath!),
                        fit: BoxFit.cover,
                      ),
                      // Red tint overlay
                      Container(
                          color: AppTheme.neonRed.withValues(alpha: 0.12)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cancel_rounded,
                        color: AppTheme.neonRed, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.notAParkingSpot,
                          style: const TextStyle(
                              color: AppTheme.neonRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                    if (result != null)
                      Text('${result.confidence}%',
                          style: const TextStyle(
                              color: AppTheme.neonRed,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: result.confidence / 100,
                      backgroundColor: Colors.white12,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.neonRed),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(result.reason,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OrangeButton(
            onTap: () {
              ref.read(reportProvider.notifier).clearImage();
              setState(() => _flow = _FlowState.waitingCamera);
              _openCamera();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(s.retakeForApproval,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

// ── Arc painter for GPS lock animation ────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final Color color;
  final double progress;
  const _ArcPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -3.14159 / 2,
      3.14159 * 1.4, // ~252° arc
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ── Shared UI Components ────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _OrangeButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _OrangeButton({required this.onTap, required this.child});

  @override
  State<_OrangeButton> createState() => _OrangeButtonState();
}

class _OrangeButtonState extends State<_OrangeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [AppTheme.energy, Color(0xFFBB0055)])
                : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: AppTheme.energy.withValues(
                            alpha: _pressed ? 0.25 : 0.45),
                        blurRadius: _pressed ? 8 : 18,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

// ── Shimmer skeleton shown while AI scans ─────────────────────────────────────
class _ScanShimmerCard extends StatelessWidget {
  const _ScanShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.card,
      highlightColor: AppTheme.cardBorder,
      period: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 10),
                Container(
                    width: 140, height: 14,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6))),
                const Spacer(),
                Container(
                    width: 40, height: 20,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
                height: 6,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 12),
            Container(
                width: double.infinity, height: 11,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(
                width: 180, height: 11,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.orange.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(width: 8),
                  Text('AI scanning your photo…',
                      style: TextStyle(
                          color: AppTheme.orange.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
