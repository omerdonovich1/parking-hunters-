import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/report_provider.dart';
import '../../../services/location_service.dart';
import '../../../services/ai_scan_service.dart';
import '../../../core/theme/app_theme.dart';
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
  String _address = 'Tap to detect location';
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
    await ref.read(reportProvider.notifier).submitReport(
      lat: _lat!,
      lng: _lng!,
      estimatedMinutes: 30,
    );
    final s = ref.read(reportProvider);
    if (s.isSuccess && mounted) {
      setState(() => _showSuccess = true);
      if (s.newBadgeId != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🏅 Badge unlocked: ${s.newBadgeId!.replaceAll('_', ' ')}!'),
                backgroundColor: AppTheme.neonYellow,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
      _address = 'Tap to detect location';
    });
    context.go('/');
  }

  void _nextStep() {
    if (_currentStep < 3) {
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStepIndicator(),
                const SizedBox(height: 8),
                Expanded(child: _buildCurrentStep(reportState)),
                _buildBottomBar(reportState),
              ],
            ),
          ),
        ),
        if (_showSuccess)
          Positioned.fill(child: SuccessAnimation(onDismiss: _onSuccessDismissed)),
      ],
    );
  }

  Widget _buildHeader() {
    const titles = ['Pin Location', 'Take Photo', 'AI Scan', 'Confirm'];
    final subs = [
      'Where is the free spot?',
      'Photograph the parking space',
      'Claude analyzes your photo',
      'Submit your report',
    ];
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

  Widget _buildCurrentStep(ReportState reportState) {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep();
      case 1:
        return _buildPhotoStep(reportState);
      case 2:
        return _buildScanStep(reportState);
      case 3:
        return _buildConfirmStep(reportState);
      default:
        return _buildLocationStep();
    }
  }

  // ── STEP 1: LOCATION ──────────────────────────────────────────────────────

  Widget _buildLocationStep() {
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
                              Icon(Icons.map_outlined, color: Colors.white12, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'No location yet',
                                style: TextStyle(color: Colors.white24, fontSize: 13),
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
                        _address,
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.my_location, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Detect My Location',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: PHOTO ─────────────────────────────────────────────────────────

  Widget _buildPhotoStep(ReportState reportState) {
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
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Retake', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 13),
                                  SizedBox(width: 5),
                                  Text('Photo ready', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                          const Text(
                            'Photo required',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AI needs a photo to verify the spot',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
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
                  label: 'Gallery',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _OrangeButton(
                  onTap: () => ref.read(reportProvider.notifier).pickImage(fromCamera: true),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Open Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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

  Widget _buildScanStep(ReportState reportState) {
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
                      if (hasResult) _buildResultOverlay(result!),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Scan with AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          if (isScanning)
            _GlassCard(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange),
                  ),
                  SizedBox(width: 12),
                  Text('AI is analyzing your photo...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          if (hasResult) _buildResultCard(result!),
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
                    child: const Text('Retry', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 13)),
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

  Widget _buildResultOverlay(AiScanResult result) {
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
                        result.isFree ? 'Spot is FREE' : 'Spot is TAKEN',
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

  Widget _buildResultCard(AiScanResult result) {
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
                isFree ? 'Free spot confirmed' : 'Spot appears taken',
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

  Widget _buildConfirmStep(ReportState reportState) {
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
                _summaryRow(Icons.location_on, 'Location', _address),
                const Divider(color: Colors.white10, height: 24),
                _summaryRow(Icons.access_time, 'Expires in', '30 minutes'),
                if (result != null) ...[
                  const Divider(color: Colors.white10, height: 24),
                  _summaryRow(
                    Icons.auto_awesome,
                    'AI Result',
                    '${result.isFree ? "Free" : "Taken"} · ${result.confidence}% confidence',
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
                    gradient: const LinearGradient(colors: [AppTheme.orange, Color(0xFFFF8C5A)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('🎯', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('+10 Points', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900, fontSize: 18)),
                    Text('Thank you for helping the community!', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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

  Widget _buildBottomBar(ReportState reportState) {
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
          _currentStep == 2 ? 'Continue to Submit' : 'Continue',
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

class _OrangeButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _OrangeButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(colors: [AppTheme.orange, Color(0xFFFF8C5A)])
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [BoxShadow(color: AppTheme.orange.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))]
              : [],
        ),
        child: Center(child: child),
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
