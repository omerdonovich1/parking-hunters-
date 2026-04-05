import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  double? _lat;
  double? _lng;
  String _address = '';
  bool _isGettingLocation = false;
  bool _showSuccess = false;
  final LocationService _locationService = LocationService();

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanAnimController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final address = await _locationService.getAddressFromCoords(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _address = address;
      });
    } catch (_) {
      setState(() {
        _lat = 32.0853;
        _lng = 34.7818;
        _address = 'Tel Aviv (demo location)';
      });
    } finally {
      setState(() => _isGettingLocation = false);
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
      // 3-beat rising pattern: light → medium → heavy
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
    setState(() {
      _currentStep = 0;
      _lat = null;
      _lng = null;
      _address = '';
    });
    context.go('/');
  }

  void _nextStep() {
    if (_currentStep < 3) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
      // Auto-trigger AI scan when entering step 3
      if (_currentStep == 2) {
        Future.microtask(() => ref.read(reportProvider.notifier).scanWithAI());
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

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
                Expanded(child: _buildCurrentStep(reportState, s)),
                _buildBottomBar(reportState, s),
              ],
            ),
          ),
        ),
        if (_showSuccess)
          Positioned.fill(child: SuccessAnimation(onDismiss: _onSuccessDismissed)),
      ],
    );
  }

  Widget _buildHeader(AppStrings s) {
    final titles = [s.stepPinLocation, s.stepTakePhoto, s.stepAiScan, s.stepConfirm];
    final subs = [s.stepSubWhere, s.stepSubPhoto, s.stepSubAi, s.stepSubConfirm];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _currentStep == 0 ? context.go('/') : _prevStep(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_currentStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subs[_currentStep],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_currentStep + 1}/4',
            style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: isDone
                            ? const LinearGradient(colors: [AppTheme.orange, AppTheme.orange])
                            : null,
                        color: isDone ? null : Colors.white.withValues(alpha: 0.1),
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
                        ? [BoxShadow(color: AppTheme.orange.withValues(alpha: 0.5), blurRadius: 10)]
                        : [],
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(ReportState reportState, AppStrings s) {
    switch (_currentStep) {
      case 0:  return _buildLocationStep(s);
      case 1:  return _buildPhotoStep(reportState, s);
      case 2:  return _buildScanStep(reportState, s);
      case 3:  return _buildConfirmStep(reportState, s);
      default: return _buildLocationStep(s);
    }
  }

  // ── STEP 1: LOCATION ──────────────────────────────────────────────────────

  Widget _buildLocationStep(AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Map preview / GPS card
          _GlassCard(
            child: Column(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.card,
                        AppTheme.bg.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _lat != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.orange, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_outlined, color: Colors.white12, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                s.noLocationYet,
                                style: const TextStyle(color: Colors.white24, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _lat != null ? AppTheme.orange : Colors.white24,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _address.isEmpty ? s.tapToDetectLoc : _address,
                        style: TextStyle(
                          color: _lat != null ? Colors.white70 : Colors.white30,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OrangeButton(
            onTap: _isGettingLocation ? null : _getCurrentLocation,
            child: _isGettingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.my_location, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        s.detectMyLocation,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: PHOTO ─────────────────────────────────────────────────────────

  Widget _buildPhotoStep(ReportState reportState, AppStrings s) {
    final hasPhoto = reportState.selectedImagePath != null;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: _GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasPhoto
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(reportState.selectedImagePath!),
                            fit: BoxFit.cover,
                          ),
                          // Retake button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => ref.read(reportProvider.notifier).clearImage(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    color: Colors.black54,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.refresh, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(s.retake, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bottom label
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.neonGreen.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 13),
                                  const SizedBox(width: 5),
                                  Text(s.photoReady, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnim,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.orange.withValues(alpha: 0.15),
                                border: Border.all(color: AppTheme.orange.withValues(alpha: 0.4), width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: AppTheme.orange, size: 44),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.photoRequired,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.aiNeedsPhoto,
                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GlassOutlinedButton(
                  onTap: () => ref.read(reportProvider.notifier).pickImage(fromCamera: false),
                  icon: Icons.photo_library_outlined,
                  label: s.gallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _OrangeButton(
                  onTap: () => ref.read(reportProvider.notifier).pickImage(fromCamera: true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(s.openCamera, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── STEP 3: AI SCAN ───────────────────────────────────────────────────────

  Widget _buildScanStep(ReportState reportState, AppStrings s) {
    final hasResult = reportState.aiScanResult != null;
    final isScanning = reportState.isScanning;
    final result = reportState.aiScanResult;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // Photo with scan overlay
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
                      if (hasResult) _buildResultOverlay(result!, s),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (!hasResult && !isScanning)
            _OrangeButton(
              onTap: () async {
                await ref.read(reportProvider.notifier).scanWithAI();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(s.scanWithAi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          if (isScanning) const _ScanShimmerCard(),
          if (hasResult) _buildResultCard(result!, s),
          if (reportState.error != null && !isScanning) ...[
            const SizedBox(height: 8),
            _GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reportState.error!,
                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(reportProvider.notifier).scanWithAI(),
                    child: Text(s.retry, style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 13)),
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
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: AppTheme.orange.withValues(alpha: 0.08)),
            Positioned(
              top: _scanAnim.value * 300,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.orange.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultOverlay(AiScanResult result, AppStrings s) {
    final color = result.isFree ? AppTheme.neonGreen : AppTheme.neonRed;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            color: Colors.black.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(
                  result.isFree ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.isFree ? s.spotIsFree : s.spotIsTakenLabel,
                        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        result.reason,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${result.confidence}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(AiScanResult result, AppStrings s) {
    final isFree = result.isFree;
    final color = isFree ? AppTheme.neonGreen : AppTheme.neonRed;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(isFree ? Icons.check_circle : Icons.cancel, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                isFree ? s.freeSpotConfirmed : s.spotAppearsTaken,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Text('${result.confidence}%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          // Confidence bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.confidence / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(result.reason, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  // ── STEP 4: CONFIRM & SUBMIT ──────────────────────────────────────────────

  Widget _buildConfirmStep(ReportState reportState, AppStrings s) {
    final result = reportState.aiScanResult;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(Icons.location_on, s.locationLabel, _address.isEmpty ? s.tapToDetectLoc : _address),
                const Divider(color: Colors.white10, height: 24),
                _summaryRow(Icons.access_time, s.expiresIn, s.thirtyMinutes),
                if (result != null) ...[
                  const Divider(color: Colors.white10, height: 24),
                  _summaryRow(
                    Icons.auto_awesome,
                    s.aiResult,
                    '${result.isFree ? s.freeLabel : s.takenLabel} · ${result.confidence}% ${s.confidenceLabel}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Points card
          _GlassCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.orange, Color(0xFF007799)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🎯', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.plusTenPoints, style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(s.thanksForHelping, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (reportState.isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.orange))
          else
            _OrangeButton(
              onTap: _submitReport,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(s.submitReport, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          if (reportState.error != null) ...[
            const SizedBox(height: 12),
            Text(reportState.error!, style: const TextStyle(color: AppTheme.neonRed, fontSize: 13), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.orange, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(ReportState reportState, AppStrings s) {
    final canNext = switch (_currentStep) {
      0 => _lat != null,
      1 => reportState.selectedImagePath != null,
      2 => reportState.aiScanResult != null && !reportState.isScanning,
      _ => true,
    };

    if (_currentStep == 3) return const SizedBox.shrink(); // submit is inside the step

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: _OrangeButton(
        onTap: canNext ? _nextStep : null,
        child: Text(
          _currentStep == 2 ? s.continueToSubmit : s.continue_,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

// ── Shared UI Components ───────────────────────────────────────────────────

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
                ? const LinearGradient(colors: [AppTheme.energy, Color(0xFFBB0055)])
                : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [BoxShadow(color: AppTheme.energy.withValues(alpha: _pressed ? 0.25 : 0.45), blurRadius: _pressed ? 8 : 18, offset: const Offset(0, 6))]
                : [],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _GlassOutlinedButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;

  const _GlassOutlinedButton({required this.onTap, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white60, size: 18),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
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
            // Status row skeleton
            Row(
              children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 10),
                Container(width: 140, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const Spacer(),
                Container(width: 40, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar skeleton
            Container(
              height: 6,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 12),
            // Reason text skeleton — two lines
            Container(width: double.infinity, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(width: 180, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            // Label below
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.orange.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI scanning your photo…',
                    style: TextStyle(color: AppTheme.orange.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
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
