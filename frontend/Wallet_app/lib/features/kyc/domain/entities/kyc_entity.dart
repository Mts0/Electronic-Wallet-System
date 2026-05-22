enum KycDocumentType {
  nationalId,
  passport,
}

enum KycStatus {
  notStarted,
  draft,
  pending,
  approved,
  rejected,
}

class KycEntity {
  final String phoneNumber;
  final int? kycId;
  final KycDocumentType? documentType;
  final String idNumber;
  final DateTime? idExpiry;
  final String nationality;
  final String country;
  final String city;
  final String location;
  final String apartment;
  final String? idFrontImage;
  final String? idBackImage;
  final String? selfieImage;
  final KycStatus status;
  final String? rejectionReason;

  const KycEntity({
    required this.phoneNumber,
    required this.kycId,
    required this.documentType,
    required this.idNumber,
    required this.idExpiry,
    required this.nationality,
    required this.country,
    required this.city,
    required this.location,
    required this.apartment,
    required this.idFrontImage,
    required this.idBackImage,
    required this.selfieImage,
    required this.status,
    required this.rejectionReason,
  });

  factory KycEntity.notStarted({required String phoneNumber}) {
    return KycEntity(
      phoneNumber: phoneNumber,
      kycId: null,
      documentType: null,
      idNumber: '',
      idExpiry: null,
      nationality: '',
      country: '',
      city: '',
      location: '',
      apartment: '',
      idFrontImage: null,
      idBackImage: null,
      selfieImage: null,
      status: KycStatus.notStarted,
      rejectionReason: null,
    );
  }

  bool get hasDataStepCompleted {
    return documentType != null &&
        idNumber.trim().isNotEmpty &&
        idExpiry != null &&
        nationality.trim().isNotEmpty &&
        city.trim().isNotEmpty &&
        location.trim().isNotEmpty;
  }

  bool get hasAllImages {
    return (idFrontImage?.isNotEmpty ?? false) &&
        (idBackImage?.isNotEmpty ?? false) &&
        (selfieImage?.isNotEmpty ?? false);
  }

  KycEntity copyWith({
    String? phoneNumber,
    int? kycId,
    KycDocumentType? documentType,
    bool clearDocumentType = false,
    String? idNumber,
    DateTime? idExpiry,
    bool clearIdExpiry = false,
    String? nationality,
    String? country,
    String? city,
    String? location,
    String? apartment,
    String? idFrontImage,
    bool clearIdFrontImage = false,
    String? idBackImage,
    bool clearIdBackImage = false,
    String? selfieImage,
    bool clearSelfieImage = false,
    KycStatus? status,
    String? rejectionReason,
    bool clearRejectionReason = false,
  }) {
    return KycEntity(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      kycId: kycId ?? this.kycId,
      documentType: clearDocumentType ? null : (documentType ?? this.documentType),
      idNumber: idNumber ?? this.idNumber,
      idExpiry: clearIdExpiry ? null : (idExpiry ?? this.idExpiry),
      nationality: nationality ?? this.nationality,
      country: country ?? this.country,
      city: city ?? this.city,
      location: location ?? this.location,
      apartment: apartment ?? this.apartment,
      idFrontImage: clearIdFrontImage ? null : (idFrontImage ?? this.idFrontImage),
      idBackImage: clearIdBackImage ? null : (idBackImage ?? this.idBackImage),
      selfieImage: clearSelfieImage ? null : (selfieImage ?? this.selfieImage),
      status: status ?? this.status,
      rejectionReason: clearRejectionReason ? null : (rejectionReason ?? this.rejectionReason),
    );
  }
}
