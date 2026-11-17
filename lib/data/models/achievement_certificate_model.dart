enum CertificateType {
  achievement(1),
  courseCompletion(2);

  const CertificateType(this.chainValue);
  final int chainValue;

  static CertificateType fromJson(Object? value) {
    final raw = value is num ? value.toInt() : int.tryParse('$value');
    return CertificateType.values.firstWhere(
      (type) => type.chainValue == raw,
      orElse: () => throw FormatException('Unknown certificate type: $value'),
    );
  }
}

enum CertificateStatus {
  eligible,
  requested,
  failed,
  pending,
  confirmed,
  revoked,
  unverified;

  static CertificateStatus fromJson(Object? value) =>
      CertificateStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => CertificateStatus.unverified,
      );
}

class AchievementCertificateModel {
  AchievementCertificateModel({
    required this.certificateId,
    required this.subjectId,
    required this.type,
    required this.achievementCode,
    required this.recipientAddress,
    required this.achievementHash,
    required Map<String, dynamic> criteriaSnapshot,
    required this.requestedAt,
    this.status = CertificateStatus.requested,
    this.issuedAt,
    this.transactionHash,
    this.blockNumber,
  }) : criteriaSnapshot = Map.unmodifiable(criteriaSnapshot);

  final String certificateId;
  final String subjectId;
  final CertificateType type;
  final String achievementCode;
  final String recipientAddress;
  final String achievementHash;
  final Map<String, dynamic> criteriaSnapshot;
  final DateTime requestedAt;
  final CertificateStatus status;
  final DateTime? issuedAt;
  final String? transactionHash;
  final int? blockNumber;

  AchievementCertificateModel copyWith({
    String? certificateId,
    String? subjectId,
    CertificateType? type,
    String? achievementCode,
    String? recipientAddress,
    String? achievementHash,
    Map<String, dynamic>? criteriaSnapshot,
    DateTime? requestedAt,
    CertificateStatus? status,
    DateTime? issuedAt,
    bool clearIssuedAt = false,
    String? transactionHash,
    bool clearTransactionHash = false,
    int? blockNumber,
    bool clearBlockNumber = false,
  }) => AchievementCertificateModel(
    certificateId: certificateId ?? this.certificateId,
    subjectId: subjectId ?? this.subjectId,
    type: type ?? this.type,
    achievementCode: achievementCode ?? this.achievementCode,
    recipientAddress: recipientAddress ?? this.recipientAddress,
    achievementHash: achievementHash ?? this.achievementHash,
    criteriaSnapshot: criteriaSnapshot ?? this.criteriaSnapshot,
    requestedAt: requestedAt ?? this.requestedAt,
    status: status ?? this.status,
    issuedAt: clearIssuedAt ? null : issuedAt ?? this.issuedAt,
    transactionHash: clearTransactionHash
        ? null
        : transactionHash ?? this.transactionHash,
    blockNumber: clearBlockNumber ? null : blockNumber ?? this.blockNumber,
  );

  Map<String, dynamic> toJson() => {
    'certificate_id': certificateId,
    'subject_id': subjectId,
    'certificate_type': type.chainValue,
    'achievement_code': achievementCode,
    'recipient_address': recipientAddress,
    'achievement_hash': achievementHash,
    'criteria_snapshot': criteriaSnapshot,
    'requested_at': requestedAt.toUtc().toIso8601String(),
    'status': status.name,
    'issued_at': issuedAt?.toUtc().toIso8601String(),
    'transaction_hash': transactionHash,
    'block_number': blockNumber,
  };

  factory AchievementCertificateModel.fromJson(Map<String, dynamic> json) =>
      AchievementCertificateModel(
        certificateId: json['certificate_id'] as String,
        subjectId: json['subject_id'] as String,
        type: CertificateType.fromJson(json['certificate_type']),
        achievementCode: json['achievement_code'] as String,
        recipientAddress: json['recipient_address'] as String,
        achievementHash: json['achievement_hash'] as String,
        criteriaSnapshot: json['criteria_snapshot'] is Map
            ? Map<String, dynamic>.from(json['criteria_snapshot'] as Map)
            : const {},
        requestedAt: DateTime.parse(json['requested_at'] as String),
        status: CertificateStatus.fromJson(json['status']),
        issuedAt: json['issued_at'] is String
            ? DateTime.tryParse(json['issued_at'] as String)
            : null,
        transactionHash: json['transaction_hash'] as String?,
        blockNumber: (json['block_number'] as num?)?.toInt(),
      );
}
