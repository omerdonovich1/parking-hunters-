import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/parking_spot_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/ai_scan_service.dart';
import 'demo_provider.dart';
import 'map_provider.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final aiScanServiceProvider = Provider<AiScanService>((ref) => AiScanService());

class ReportState {
  final bool isLoading;
  final bool isScanning; // AI scan in progress
  final bool isSuccess;
  final String? error;
  final String? selectedImagePath;
  final AiScanResult? aiScanResult;
  final String? newBadgeId;

  const ReportState({
    this.isLoading = false,
    this.isScanning = false,
    this.isSuccess = false,
    this.error,
    this.selectedImagePath,
    this.aiScanResult,
    this.newBadgeId,
  });

  ReportState copyWith({
    bool? isLoading,
    bool? isScanning,
    bool? isSuccess,
    String? error,
    String? selectedImagePath,
    AiScanResult? aiScanResult,
    String? newBadgeId,
    bool clearError = false,
    bool clearImage = false,
    bool clearScanResult = false,
    bool clearBadge = false,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
      selectedImagePath: clearImage ? null : (selectedImagePath ?? this.selectedImagePath),
      aiScanResult: clearScanResult ? null : (aiScanResult ?? this.aiScanResult),
      newBadgeId: clearBadge ? null : (newBadgeId ?? this.newBadgeId),
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final AiScanService _aiScanService;
  final Ref _ref;
  final ImagePicker _imagePicker = ImagePicker();

  ReportNotifier(
    this._firestoreService,
    this._storageService,
    this._aiScanService,
    this._ref,
  ) : super(const ReportState());

  Future<void> pickImage({bool fromCamera = true}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        // Clear previous scan result when new photo is taken
        state = state.copyWith(
          selectedImagePath: image.path,
          clearScanResult: true,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image: $e');
    }
  }

  /// Sends the photo to Claude Vision and returns the result.
  /// Automatically updates state with isScanning + aiScanResult.
  Future<AiScanResult?> scanWithAI() async {
    if (state.selectedImagePath == null) return null;
    state = state.copyWith(isScanning: true, clearError: true);
    final result = await _aiScanService.scanParkingPhoto(state.selectedImagePath!);
    state = state.copyWith(isScanning: false, aiScanResult: result, error: result.reason.contains('key not configured') || result.reason.contains('Could not reach') || result.reason.contains('failed') ? result.reason : null);
    return result;
  }

  Future<void> submitReport({
    required double lat,
    required double lng,
    String? note,
    int estimatedMinutes = 60,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Demo mode — simulate success without hitting Firebase
    if (_ref.read(demoModeProvider)) {
      await Future.delayed(const Duration(milliseconds: 800));
      final now = DateTime.now();
      final uuid = const Uuid().v4();
      final confidence = state.aiScanResult?.confidence ?? 70;
      final spot = ParkingSpot(
        id: uuid,
        lat: lat,
        lng: lng,
        reportedBy: 'demo_user',
        reportedAt: now,
        expiresAt: now.add(Duration(minutes: estimatedMinutes)),
        aiConfidence: confidence / 100.0,
        status: SpotStatus.available,
        note: note,
      );
      _ref.read(parkingSpotsProvider.notifier).addSpot(spot);
      await _ref.read(userProfileProvider.notifier).updatePoints(10);
      await _ref.read(userProfileProvider.notifier).incrementReports();
      state = state.copyWith(isLoading: false, isSuccess: true, clearImage: true, clearScanResult: true);
      return;
    }

    try {
      final userId = _ref.read(currentUserProvider)?.uid ?? 'anonymous';
      final now = DateTime.now();

      // Deduplication — if an active spot exists within 30m, refresh its timer instead
      final nearby = await _firestoreService.findNearbyActiveSpot(lat, lng);
      if (nearby != null) {
        await _firestoreService.refreshSpot(nearby.id, minutes: estimatedMinutes);
        await _ref.read(userProfileProvider.notifier).updatePoints(5);
        state = state.copyWith(isLoading: false, isSuccess: true, clearImage: true, clearScanResult: true);
        return;
      }

      final uuid = const Uuid().v4();

      // Upload photo
      String? photoUrl;
      if (state.selectedImagePath != null) {
        photoUrl = await _storageService.uploadSpotPhoto(
          userId: userId,
          reportId: uuid,
          localFilePath: state.selectedImagePath!,
        );
      }

      final confidence = (state.aiScanResult?.confidence ?? 70) / 100.0;

      final report = ParkingReport(
        id: uuid,
        spotId: uuid,
        userId: userId,
        lat: lat,
        lng: lng,
        photoUrl: photoUrl,
        note: note,
        estimatedAvailableUntil: now.add(Duration(minutes: estimatedMinutes)),
        createdAt: now,
        confirmedCount: 0,
        deniedCount: 0,
      );

      await _firestoreService.addParkingReport(report, aiConfidence: confidence);

      final spot = ParkingSpot(
        id: uuid,
        lat: lat,
        lng: lng,
        reportedBy: userId,
        reportedAt: now,
        expiresAt: now.add(Duration(minutes: estimatedMinutes)),
        aiConfidence: confidence,
        status: SpotStatus.available,
        photoUrl: photoUrl,
        note: note,
      );
      _ref.read(parkingSpotsProvider.notifier).addSpot(spot);

      final badgesBefore = _ref.read(userProfileProvider)?.badgeIds ?? [];
      await _ref.read(userProfileProvider.notifier).updatePoints(10);
      await _ref.read(userProfileProvider.notifier).incrementReports();
      final badgesAfter = _ref.read(userProfileProvider)?.badgeIds ?? [];
      final newBadge = badgesAfter.where((id) => !badgesBefore.contains(id)).firstOrNull;

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        clearImage: true,
        clearScanResult: true,
        newBadgeId: newBadge,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to submit: $e');
    }
  }

  void clearImage() => state = state.copyWith(clearImage: true, clearScanResult: true);

  void reset() => state = const ReportState();
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
    ref.watch(aiScanServiceProvider),
    ref,
  );
});
