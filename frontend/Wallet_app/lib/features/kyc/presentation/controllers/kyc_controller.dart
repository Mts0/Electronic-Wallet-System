import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/kyc/domain/entities/kyc_entity.dart';

final kycFlowProvider = StateNotifierProvider.family<
    KycFlowController, AsyncValue<KycEntity>, String>((ref, phone) {
  final dio = ref.watch(dioProvider);
  return KycFlowController(
    dio: dio,
    phone: phone,
  );
});

final currentUserKycProvider = FutureProvider<KycEntity>((ref) async {
  final sessionStorage = ref.watch(sessionStorageProvider);
  final dio = ref.watch(dioProvider);

  final phone = await sessionStorage.getCurrentUserPhone();
  final cleanPhone = phone?.trim() ?? '';
  if (cleanPhone.isEmpty) {
    return KycEntity.notStarted(phoneNumber: '');
  }

  try {
    final response = await dio.get('/kyc/my');
    final json = _asMap(response.data);
    return _mapBackendKyc(json, fallbackPhone: cleanPhone);
  } on DioException catch (e) {
    if (_shouldTreatAsEmptyKyc(e)) {
      return KycEntity.notStarted(phoneNumber: cleanPhone);
    }
    throw Exception(_extractMessage(e, 'تعذر تحميل حالة KYC'));
  }
});

class KycFlowController extends StateNotifier<AsyncValue<KycEntity>> {
  KycFlowController({
    required Dio dio,
    required String phone,
  })  : _dio = dio,
        _phone = phone,
        super(AsyncValue.data(KycEntity.notStarted(phoneNumber: phone))) {
    load();
  }

  final Dio _dio;
  final String _phone;

  Future<void> load() async {
    try {
      final response = await _dio.get('/kyc/my');
      final entity = _mapBackendKyc(
        _asMap(response.data),
        fallbackPhone: _phone,
      );
      state = AsyncValue.data(entity);
    } on DioException catch (e, st) {
      if (_shouldTreatAsEmptyKyc(e)) {
        state = AsyncValue.data(KycEntity.notStarted(phoneNumber: _phone));
        return;
      }
      state = AsyncValue.error(Exception(_extractMessage(e, 'تعذر تحميل طلب KYC')), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveDraft({
    required KycDocumentType documentType,
    required String idNumber,
    required DateTime idExpiry,
    required String nationality,
    required String country,
    required String city,
    required String location,
    required String apartment,
  }) async {
    final current = state.value ?? KycEntity.notStarted(phoneNumber: _phone);

    try {
      final response = await _dio.post(
        '/kyc/me',
        data: {
          'id_type': documentType == KycDocumentType.nationalId ? 'NATIONAL_ID' : 'PASSPORT',
          'id_number': idNumber,
          'id_expiry': idExpiry.toIso8601String().split('T').first,
          'nationality': nationality,
          'country': country.trim().isEmpty ? null : country,
          'city': city,
          'location': location,
          'apartment': apartment.trim().isEmpty ? null : apartment,
        },
      );

      final next = _mapBackendKyc(_asMap(response.data), fallbackPhone: _phone).copyWith(
        country: _pickString(_asMap(response.data), 'country', fallback: country),
        city: _pickString(_asMap(response.data), 'city', fallback: city),
        location: _pickString(_asMap(response.data), 'location', fallback: location),
        apartment: _pickString(_asMap(response.data), 'apartment', fallback: apartment),
        idFrontImage: current.idFrontImage,
        idBackImage: current.idBackImage,
        selfieImage: current.selfieImage,
      );
      state = AsyncValue.data(next);
    } on DioException catch (e, st) {
      state = AsyncValue.error(Exception(_extractMessage(e, 'تعذر حفظ بيانات KYC')), st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveFrontImage(String value) async {
    final current = state.value ?? KycEntity.notStarted(phoneNumber: _phone);
    state = AsyncValue.data(current.copyWith(idFrontImage: value));
  }

  Future<void> saveBackImage(String value) async {
    final current = state.value ?? KycEntity.notStarted(phoneNumber: _phone);
    state = AsyncValue.data(current.copyWith(idBackImage: value));
  }

  Future<void> saveSelfieImage(String value) async {
    final current = state.value ?? KycEntity.notStarted(phoneNumber: _phone);
    state = AsyncValue.data(current.copyWith(selfieImage: value));
  }

  Future<void> submitForReview() async {
    final current = state.value ?? KycEntity.notStarted(phoneNumber: _phone);

    if (!current.hasDataStepCompleted) {
      throw Exception('أكمل بيانات KYC أولًا');
    }
    if (!current.hasAllImages) {
      throw Exception('أكمل رفع الصور الثلاث أولًا');
    }

    try {
      final formData = FormData.fromMap({
        'id_front': await MultipartFile.fromFile(current.idFrontImage!),
        'id_back': await MultipartFile.fromFile(current.idBackImage!),
        'selfie': await MultipartFile.fromFile(current.selfieImage!),
      });

      final response = await _dio.post('/kyc/me/upload', data: formData);
      final next = _mapBackendKyc(_asMap(response.data), fallbackPhone: _phone).copyWith(
        idFrontImage: current.idFrontImage,
        idBackImage: current.idBackImage,
        selfieImage: current.selfieImage,
      );
      state = AsyncValue.data(next);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'تعذر إرسال طلب KYC للمراجعة'));
    }
  }
}


bool _shouldTreatAsEmptyKyc(DioException e) {
  if (e.response?.statusCode == 404) {
    return true;
  }

  if (e.response?.statusCode == 403) {
    final message = _extractMessage(e, '').trim();
    if (message.contains('إكمال KYC') ||
        message.contains('اكمال KYC') ||
        message.contains('التحقق من الهوية') ||
        message.contains('KYC')) {
      return true;
    }
  }

  return false;
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return const {};
}

String _extractMessage(DioException e, String fallback) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return 'تعذر الاتصال بالخادم';
  }

  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final detail = map['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) return message;
  }
  if (data is String && data.trim().isNotEmpty) return data;
  return fallback;
}

KycEntity _mapBackendKyc(Map<String, dynamic> json, {required String fallbackPhone}) {
  final idType = (json['id_type'] ?? '').toString().toUpperCase();
  final status = (json['status'] ?? '').toString().toUpperCase();
  return KycEntity(
    phoneNumber: fallbackPhone,
    kycId: ((json['kyc_id'] ?? 0) as num?)?.toInt(),
    documentType: idType == 'PASSPORT' ? KycDocumentType.passport : KycDocumentType.nationalId,
    idNumber: (json['id_number'] ?? '').toString(),
    idExpiry: json['id_expiry'] == null ? null : DateTime.tryParse(json['id_expiry'].toString()),
    nationality: (json['nationality'] ?? '').toString(),
    country: _pickString(json, 'country'),
    city: _pickString(json, 'city'),
    location: _pickString(json, 'location'),
    apartment: _pickString(json, 'apartment'),
    idFrontImage: json['id_front_image']?.toString(),
    idBackImage: json['id_back_image']?.toString(),
    selfieImage: json['selfie_image']?.toString(),
    status: () {
      switch (status) {
        case 'DRAFT':
          return KycStatus.draft;
        case 'PENDING':
          return KycStatus.pending;
        case 'APPROVED':
          return KycStatus.approved;
        case 'REJECTED':
          return KycStatus.rejected;
        default:
          return KycStatus.notStarted;
      }
    }(),
    rejectionReason: json['rejection_reason']?.toString(),
  );
}

String _pickString(Map<String, dynamic> json, String key, {String fallback = ''}) {
  final value = json[key];
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}
