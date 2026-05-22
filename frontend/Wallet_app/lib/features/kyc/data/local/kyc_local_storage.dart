import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:y_wallet/features/kyc/domain/entities/kyc_entity.dart';

class KycLocalStorage {
  KycLocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _kycRecordsKey = 'kyc_records_v1';

  Future<KycEntity> getKycByPhone(String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    final map = await _readAll();

    final raw = map[normalizedPhone];
    if (raw is Map<String, dynamic>) {
      return KycEntity.fromJson(raw);
    }

    if (raw is Map) {
      return KycEntity.fromJson(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return KycEntity.notStarted(phoneNumber: normalizedPhone);
  }

  Future<KycEntity> saveDraft({
    required String phone,
    required KycDocumentType documentType,
    required String idNumber,
    required DateTime idExpiry,
    required String nationality,
  }) async {
    final current = await getKycByPhone(phone);

    final updated = current.copyWith(
      phoneNumber: _normalizePhone(phone),
      documentType: documentType,
      idNumber: idNumber.trim(),
      idExpiry: idExpiry,
      nationality: nationality.trim(),
      status: KycStatus.draft,
      clearRejectionReason: true,
    );

    await _saveRecord(updated);
    return updated;
  }

  Future<KycEntity> saveImages({
    required String phone,
    String? idFrontImage,
    String? idBackImage,
    String? selfieImage,
  }) async {
    final current = await getKycByPhone(phone);

    final updated = current.copyWith(
      idFrontImage: idFrontImage,
      idBackImage: idBackImage,
      selfieImage: selfieImage,
      status: KycStatus.draft,
      clearRejectionReason: true,
    );

    await _saveRecord(updated);
    return updated;
  }

  Future<KycEntity> submitForReview(String phone) async {
    final current = await getKycByPhone(phone);

    final updated = current.copyWith(
      status: KycStatus.approved,
      clearRejectionReason: true,
    );

    await _saveRecord(updated);
    return updated;
  }

  Future<void> _saveRecord(KycEntity entity) async {
    final map = await _readAll();
    map[_normalizePhone(entity.phoneNumber)] = entity.toJson();
    await _writeAll(map);
  }

  Future<Map<String, dynamic>> _readAll() async {
    final raw = _prefs.getString(_kycRecordsKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }

      return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> value) async {
    await _prefs.setString(_kycRecordsKey, jsonEncode(value));
  }

  String _normalizePhone(String value) {
    return value.trim();
  }
}