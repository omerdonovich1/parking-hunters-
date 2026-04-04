import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/report_provider.dart';
import '../../../services/location_service.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/success_animation.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int _currentStep = 0;
  double? _lat;
  double? _lng;
  String _address = 'Tap to get current location';
  bool _isGettingLocation = false;
  final _noteController = TextEditingController();
  double _estimatedMinutes = 30;
  bool _showSuccess = false;
  final LocationService _locationService = LocationService();

  @override
  void dispose() {
    _noteController.dispose();
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
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _lat = 32.0853;
        _lng = 34.7818;
        _address = 'Tel Aviv (demo location)';
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your location first')),
      );
      return;
    }
    await ref.read(reportProvider.notifier).submitReport(
      lat: _lat!,
      lng: _lng!,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      estimatedMinutes: _estimatedMinutes.toInt(),
    );
    final reportState = ref.read(reportProvider);
    if (reportState.isSuccess) {
      setState(() => _showSuccess = true);
      if (reportState.newBadgeId != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'New badge unlocked: ${reportState.newBadgeId!.replaceAll('_', ' ')}!',
                ),
                backgroundColor: Colors.amber.shade700,
                duration: const Duration(seconds: 4),
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
    _noteController.clear();
    setState(() {
      _currentStep = 0;
      _lat = null;
      _lng = null;
      _address = 'Tap to get current location';
      _estimatedMinutes = 30;
    });
    context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1219) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/map'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 20, color: textPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Report a Spot',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Step indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStepIndicator(isDark, textPrimary),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildCurrentStep(isDark, textPrimary),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: _buildNavigationButtons(reportState, isDark, textPrimary),
                ),
              ],
            ),
          ),
        ),
        if (_showSuccess)
          Positioned.fill(
            child: SuccessAnimation(onDismiss: _onSuccessDismissed),
          ),
      ],
    );
  }

  Widget _buildStepIndicator(bool isDark, Color textPrimary) {
    const steps = ['Location', 'Details', 'Submit'];
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _currentStep;
        final isCompleted = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppTheme.blue : lineColor,
                  ),
                ),
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? AppTheme.blue
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : const Color(0xFF94A3B8)),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive
                          ? AppTheme.blue
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : const Color(0xFF94A3B8)),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(bool isDark, Color textPrimary) {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep(isDark, textPrimary);
      case 1:
        return _buildDetailsStep(isDark, textPrimary);
      case 2:
        return _buildSummaryStep(isDark, textPrimary);
      default:
        return _buildLocationStep(isDark, textPrimary);
    }
  }

  Widget _buildLocationStep(bool isDark, Color textPrimary) {
    final surface = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textMuted = isDark ? const Color(0xFF8B9CB8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where is the spot?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use GPS to pinpoint your current location.',
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Map preview card
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: _lat != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.blue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppTheme.blue, size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location captured',
                        style: TextStyle(
                            color: const Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : const Color(0xFFCBD5E1),
                          size: 44),
                      const SizedBox(height: 10),
                      Text('No location yet',
                          style: TextStyle(color: textMuted, fontSize: 13)),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // Address pill
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: _lat != null ? AppTheme.blue : textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _address,
                  style: TextStyle(
                    color: _lat != null ? textPrimary : textMuted,
                    fontSize: 14,
                    fontWeight:
                        _lat != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isGettingLocation
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text('Getting location...',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.my_location_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Use Current Location',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailsStep(bool isDark, Color textPrimary) {
    final surface = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textMuted = isDark ? const Color(0xFF8B9CB8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add details',
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Optional photo and notes help others find it.',
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),

        Consumer(
          builder: (context, ref, _) {
            final reportState = ref.watch(reportProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _OutlineButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        isDark: isDark,
                        onTap: () => ref
                            .read(reportProvider.notifier)
                            .pickImage(fromCamera: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OutlineButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        isDark: isDark,
                        onTap: () => ref
                            .read(reportProvider.notifier)
                            .pickImage(fromCamera: false),
                      ),
                    ),
                  ],
                ),
                if (reportState.selectedImagePath != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.file(
                          File(reportState.selectedImagePath!),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => ref
                                .read(reportProvider.notifier)
                                .clearImage(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Photo added',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Note field
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Add a note (optional) — e.g. Blue zone, near pharmacy',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              prefixIcon:
                  Icon(Icons.notes_rounded, color: textMuted, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Available for how long?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: AppTheme.blue,
                    inactiveTrackColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                    thumbColor: AppTheme.blue,
                    overlayColor: AppTheme.blue.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _estimatedMinutes,
                    min: 15,
                    max: 120,
                    divisions: 7,
                    label: '${_estimatedMinutes.toInt()} min',
                    onChanged: (v) => setState(() => _estimatedMinutes = v),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_estimatedMinutes.toInt()}m',
                  style: const TextStyle(
                    color: AppTheme.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryStep(bool isDark, Color textPrimary) {
    final surface = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textMuted = isDark ? const Color(0xFF8B9CB8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ready to submit',
          style: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review your report before sending.',
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),

        _summaryCard('Location', _address, Icons.location_on_rounded, isDark, textPrimary, textMuted, surface),
        const SizedBox(height: 10),
        _summaryCard('Available for', '${_estimatedMinutes.toInt()} minutes', Icons.timer_rounded, isDark, textPrimary, textMuted, surface),
        if (_noteController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _summaryCard('Note', _noteController.text.trim(), Icons.notes_rounded, isDark, textPrimary, textMuted, surface),
        ],

        const SizedBox(height: 20),

        // Points reward card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.blue.withValues(alpha: 0.12),
                AppTheme.blue.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You earn +10 points!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thank you for helping the community',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon,
      bool isDark, Color textPrimary, Color textMuted, Color surface) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.blue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
      ReportState reportState, bool isDark, Color textPrimary) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          GestureDetector(
            onTap: () => setState(() => _currentStep--),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: reportState.isLoading
                  ? null
                  : () {
                      if (_currentStep == 0) {
                        if (_lat == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Please get your location first'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        setState(() => _currentStep = 1);
                      } else if (_currentStep == 1) {
                        setState(() => _currentStep = 2);
                      } else {
                        _submitReport();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: reportState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _currentStep < 2 ? 'Continue' : 'Submit Report',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.blue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  color: AppTheme.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
