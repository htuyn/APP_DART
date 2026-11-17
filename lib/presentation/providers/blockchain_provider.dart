import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/certificate_hasher.dart';
import '../../data/models/achievement_certificate_model.dart';
import '../../domain/blockchain/certificate_eligibility_engine.dart';
import '../../domain/repositories/i_blockchain_repository.dart';
import 'course_progress_provider.dart';
import 'gamification_provider.dart';

class BlockchainProvider extends ChangeNotifier with WidgetsBindingObserver {
  BlockchainProvider({
    required this.repository,
    required this.gamificationProvider,
    required this.courseProgressProvider,
    this.eligibilityEngine = const CertificateEligibilityEngine(),
    this.hasher = const CertificateHasher(),
    Connectivity? connectivity,
    Stream<List<ConnectivityResult>>? connectivityChanges,
  }) : _connectivity = connectivity ?? Connectivity() {
    gamificationProvider.addListener(_onProgressChanged);
    courseProgressProvider.addListener(_onProgressChanged);
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription =
        (connectivityChanges ?? _connectivity.onConnectivityChanged).listen(
      _onConnectivityChanged,
      onError: (Object error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
    _recomputeEligibility();
  }

  final IBlockchainRepository repository;
  final GamificationProvider gamificationProvider;
  final CourseProgressProvider courseProgressProvider;
  final CertificateEligibilityEngine eligibilityEngine;
  final CertificateHasher hasher;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<CertificateEligibility> _eligibleCertificates = const [];
  List<AchievementCertificateModel> _certificates = const [];
  String? _recipientAddress;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _disposed = false;

  List<CertificateEligibility> get eligibleCertificates =>
      List.unmodifiable(_eligibleCertificates);
  List<AchievementCertificateModel> get certificates =>
      List.unmodifiable(_certificates);
  String? get recipientAddress => _recipientAddress;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  List<AchievementCertificateModel> certificatesWithStatus(
    CertificateStatus status,
  ) => List.unmodifiable(
    _certificates.where((certificate) => certificate.status == status),
  );

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recipientAddress = await repository.loadRecipientAddress();
      _certificates = await repository.loadLocalCertificates();
      _recomputeEligibility();
      await synchronize();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      _notifyIfActive();
    }
  }

  Future<void> setRecipientAddress(String address) async {
    final normalized = address.trim();
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(normalized)) {
      _errorMessage = 'Enter a valid Ethereum address.';
      _notifyIfActive();
      return;
    }
    try {
      await repository.saveRecipientAddress(normalized);
      _recipientAddress = normalized;
      _errorMessage = null;
      _notifyIfActive();
      await synchronize();
    } catch (error) {
      _errorMessage = error.toString();
      _notifyIfActive();
    }
  }

  /// Saves an eligible request locally. Issuer signing and issuance stay
  /// outside the Flutter app; network synchronization only verifies state.
  Future<AchievementCertificateModel?> requestCertificate(
    String eligibilityCode,
  ) async {
    final address = _recipientAddress;
    if (address == null || address.isEmpty) {
      _errorMessage = 'Save a recipient wallet address first.';
      _notifyIfActive();
      return null;
    }

    final matchingEligibility = _eligibleCertificates.where(
      (item) => item.code == eligibilityCode && item.eligible,
    );
    final eligibility = matchingEligibility.isEmpty
        ? null
        : matchingEligibility.first;
    if (eligibility == null) {
      _errorMessage = 'This certificate is not currently eligible.';
      _notifyIfActive();
      return null;
    }

    final existing = _certificates.where(
      (certificate) =>
          certificate.achievementCode == eligibility.code &&
          certificate.type == eligibility.type &&
          certificate.recipientAddress.toLowerCase() == address.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;

    try {
      final hash = hasher.hashCertificate(
        subjectId: address.toLowerCase(),
        certificateType: eligibility.type.chainValue,
        achievementCode: eligibility.code,
        criteriaSnapshot: eligibility.criteria,
      );
      final certificateId = hasher.createCertificateId(
        subjectId: address.toLowerCase(),
        certificateType: eligibility.type.chainValue,
        achievementCode: eligibility.code,
        criteriaSnapshot: eligibility.criteria,
      );
      final certificate = AchievementCertificateModel(
        certificateId: certificateId,
        subjectId: address.toLowerCase(),
        type: eligibility.type,
        achievementCode: eligibility.code,
        recipientAddress: address,
        achievementHash: hash,
        criteriaSnapshot: eligibility.criteria,
        requestedAt: DateTime.now().toUtc(),
        status: CertificateStatus.pending,
      );
      await repository.saveCertificateRequest(certificate);
      _upsertCertificate(certificate);
      _errorMessage = null;
      _notifyIfActive();
      unawaited(synchronize());
      return certificate;
    } catch (error) {
      _errorMessage = error.toString();
      _notifyIfActive();
      return null;
    }
  }

  Future<void> attachIssuerTransactionHash({
    required String certificateId,
    required String transactionHash,
  }) async {
    final normalizedHash = transactionHash.trim();
    if (!RegExp(r'^0x[0-9a-fA-F]{64}$').hasMatch(normalizedHash)) {
      _errorMessage = 'Enter a valid transaction hash.';
      _notifyIfActive();
      return;
    }
    final matches = _certificates.where(
      (certificate) =>
          certificate.certificateId.toLowerCase() == certificateId.toLowerCase(),
    );
    if (matches.isEmpty) return;

    final updated = matches.first.copyWith(
      transactionHash: normalizedHash,
      status: CertificateStatus.pending,
    );
    try {
      await repository.saveCertificateRequest(updated);
      _upsertCertificate(updated);
      _errorMessage = null;
      _notifyIfActive();
      await synchronize();
    } catch (error) {
      _errorMessage = error.toString();
      _notifyIfActive();
    }
  }

  Future<AchievementCertificateModel?> verifyCertificate(
    String certificateId,
  ) async {
    try {
      final refreshed = await repository.verifyCertificate(certificateId);
      if (refreshed == null) {
        _errorMessage = 'Certificate not found in local storage.';
        _notifyIfActive();
        return null;
      }
      _upsertCertificate(refreshed);
      _errorMessage = null;
      _notifyIfActive();
      return refreshed;
    } catch (error) {
      _errorMessage = error.toString();
      _notifyIfActive();
      rethrow;
    }
  }

  Future<void> synchronize() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _isLoading = true;
    _notifyIfActive();

    try {
      final refreshed = await repository.loadCertificates(
        recipientAddress: _recipientAddress,
      );
      _certificates = List.unmodifiable(refreshed);
      _errorMessage = null;
    } catch (error) {
      // Keep the local pending/eligible state intact while offline.
      _errorMessage = error.toString();
    } finally {
      _isSyncing = false;
      _isLoading = false;
      _notifyIfActive();
    }
  }

  Future<List<String>> findIssuedCertificateIds({
    required int fromBlock,
    required int toBlock,
  }) async {
    final address = _recipientAddress;
    if (address == null) return const [];
    try {
      return await repository.findIssuedCertificateIds(
        recipientAddress: address,
        fromBlock: fromBlock,
        toBlock: toBlock,
      );
    } catch (error) {
      _errorMessage = error.toString();
      _notifyIfActive();
      return const [];
    }
  }

  void _onProgressChanged() {
    _recomputeEligibility();
    _notifyIfActive();
  }

  void _recomputeEligibility() {
    final courseProgress = courseProgressProvider.progress;
    final achievements = eligibilityEngine.evaluateAchievements(
      gamification: gamificationProvider.progress,
      currentStreak: gamificationProvider.currentStreak,
      currentLevel: gamificationProvider.levelProgress.level,
      quizHistory: courseProgressProvider.quizHistory,
      courseProgress: courseProgress,
    );
    final course = eligibilityEngine.evaluateCourseCompletion(
      progress: courseProgress,
    );
    _eligibleCertificates = List.unmodifiable([
      ...achievements.where((item) => item.eligible),
      if (course.eligible) course,
    ]);
  }

  void _upsertCertificate(AchievementCertificateModel certificate) {
    final updated = List<AchievementCertificateModel>.of(_certificates);
    final index = updated.indexWhere(
      (item) =>
          item.certificateId.toLowerCase() ==
          certificate.certificateId.toLowerCase(),
    );
    if (index < 0) {
      updated.add(certificate);
    } else {
      updated[index] = certificate;
    }
    _certificates = List.unmodifiable(updated);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (hasNetwork && _hasPendingCertificates) unawaited(synchronize());
  }

  bool get _hasPendingCertificates => _certificates.any(
    (certificate) =>
        certificate.status == CertificateStatus.pending ||
        certificate.status == CertificateStatus.requested,
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasPendingCertificates) {
      unawaited(synchronize());
    }
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    gamificationProvider.removeListener(_onProgressChanged);
    courseProgressProvider.removeListener(_onProgressChanged);
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    unawaited(repository.dispose());
    super.dispose();
  }
}
