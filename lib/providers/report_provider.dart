import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/parking_spot_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'demo_provider.dart';
import 'map_provider.dart';
import 'profile_provider.dart';
import 'auth_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class ReportState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String? selectedImagePath;
  final String? newBadgeId; // set when a badge is unlocked on submit

  const ReportState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.selectedImagePath,
    this.newBadgeId,
  });

  ReportState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    String? selectedImagePath,
    String? newBadgeId,
    bool clearError = false,
    bool clearImage = false,
    bool clearBadge = false,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
      selectedImagePath:
          clearImage ? null : (selectedImagePath ?? this.selectedImagePath),
      newBadgeId: clearBadge ? null : (newBadgeId ?? this.newBadgeId),
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final Ref _ref;
  final ImagePicker _imagePicker = ImagePicker();

  ReportNotifier(this._firestoreService, this._storageService, this._ref)
      : super(const ReportState());

  Future<void> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(selectedImagePath: image.path);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image: $e');
    }
  }

  Future<void> submitReport({
    required double lat,
    required double lng,
    String? note,
    required int estimatedMinutes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Demo mode: simulate a successful submission without hitting Firebase
    if (_ref.read(demoModeProvider)) {
      await Future.delayed(const Duration(milliseconds: 800));
      final now = DateTime.now();
      final uuid = const Uuid().v4();
      final spot = ParkingSpot(
        id: uuid,
        lat: lat,
        lng: lng,
        reportedBy: 'demo_user',
        reportedAt: now,
        expiresAt: now.add(Duration(minutes: estimatedMinutes)),
        confidence: 0.7,
        status: SpotStatus.available,
        note: note,
        confirmedCount: 0,
      );
      _ref.read(parkingSpotsProvider.notifier).addSpot(spot);
      await _ref.read(userProfileProvider.notifier).updatePoints(10);
      await _ref.read(userProfileProvider.notifier).incrementReports();
      state = state.copyWith(isLoading: false, isSuccess: true, clearImage: true);
      return;
    }

    try {
      final userId = _ref.read(currentUserProvider)?.uid ?? 'anonymous';
      final now = DateTime.now();
      final uuid = const Uuid().v4();

      // Upload photo if one was selected
      String? photoUrl;
      if (state.selectedImagePath != null) {
        photoUrl = await _storageService.uploadSpotPhoto(
          userId: userId,
          reportId: uuid,
          localFilePath: state.selectedImagePath!,
        );
      }

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

      await _firestoreService.addParkingReport(report);

      final spot = ParkingSpot(
        id: uuid,
        lat: lat,
        lng: lng,
        reportedBy: userId,
        reportedAt: now,
        expiresAt: now.add(Duration(minutes: estimatedMinutes)),
        confidence: 0.7,
        status: SpotStatus.available,
        photoUrl: photoUrl,
        note: note,
        confirmedCount: 0,
      );
      _ref.read(parkingSpotsProvider.notifier).addSpot(spot);

      final badgesBefore = _ref.read(userProfileProvider)?.badgeIds ?? [];
      await _ref.read(userProfileProvider.notifier).updatePoints(10);
      await _ref.read(userProfileProvider.notifier).incrementReports();
      final badgesAfter = _ref.read(userProfileProvider)?.badgeIds ?? [];

      // Detect newly unlocked badge
      final newBadge = badgesAfter
          .where((id) => !badgesBefore.contains(id))
          .firstOrNull;

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        clearImage: true,
        newBadgeId: newBadge,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit report: $e',
      );
    }
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  void reset() {
    state = const ReportState();
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return ReportNotifier(firestoreService, storageService, ref);
});
