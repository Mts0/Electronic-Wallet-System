import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAccountsStorage {
  LocalAccountsStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _accountsKey = 'local_accounts';

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final raw = _prefs.getString(_accountsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
        ),
      )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAccounts(List<Map<String, dynamic>> accounts) async {
    final encoded = jsonEncode(accounts);
    await _prefs.setString(_accountsKey, encoded);
  }

  Future<bool> accountExists(String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    final accounts = await getAccounts();

    return accounts.any(
          (account) => _normalizePhone(account['phone']?.toString() ?? '') == normalizedPhone,
    );
  }

  Future<Map<String, dynamic>?> getAccountByPhone(String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    final accounts = await getAccounts();

    for (final account in accounts) {
      final accountPhone = _normalizePhone(account['phone']?.toString() ?? '');
      if (accountPhone == normalizedPhone) {
        return account;
      }
    }

    return null;
  }

  Future<void> createAccount({
    required String fullName,
    required String phone,
    required String password,
    String? gender,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final accounts = await getAccounts();

    final alreadyExists = accounts.any(
          (account) => _normalizePhone(account['phone']?.toString() ?? '') == normalizedPhone,
    );

    if (alreadyExists) {
      throw Exception('account_already_exists');
    }

    final account = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'fullName': fullName.trim(),
      'phone': normalizedPhone,
      'password': password.trim(),
      'gender': gender?.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    accounts.add(account);
    await saveAccounts(accounts);
  }

  Future<void> saveAccount({
    required String fullName,
    required String phone,
    required String password,
    String? gender,
  }) async {
    await createAccount(
      fullName: fullName,
      phone: phone,
      password: password,
      gender: gender,
    );
  }

  Future<bool> validateLogin({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final normalizedPassword = password.trim();

    final accounts = await getAccounts();

    for (final account in accounts) {
      final accountPhone = _normalizePhone(account['phone']?.toString() ?? '');
      final accountPassword = (account['password'] ?? '').toString().trim();

      if (accountPhone == normalizedPhone && accountPassword == normalizedPassword) {
        return true;
      }
    }

    return false;
  }

  Future<void> updatePassword({
    required String phone,
    required String newPassword,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final accounts = await getAccounts();

    bool updated = false;

    final updatedAccounts = accounts.map((account) {
      final accountPhone = _normalizePhone(account['phone']?.toString() ?? '');

      if (accountPhone == normalizedPhone) {
        updated = true;
        return <String, dynamic>{
          ...account,
          'password': newPassword.trim(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
      }

      return account;
    }).toList();

    if (!updated) {
      throw Exception('account_not_found');
    }

    await saveAccounts(updatedAccounts);
  }

  Future<void> clearAllAccounts() async {
    await _prefs.remove(_accountsKey);
  }

  String _normalizePhone(String value) {
    return value.trim();
  }
}