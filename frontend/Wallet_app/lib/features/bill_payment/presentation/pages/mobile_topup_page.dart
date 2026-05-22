import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/features/bill_payment/presentation/controllers/mobile_topup_controller.dart';
import 'package:y_wallet/features/bill_payment/presentation/utils/mobile_operator_resolver.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:y_wallet/core/finance/widgets/operation_entry_page.dart';

class MobileTopupPage extends ConsumerStatefulWidget {
  const MobileTopupPage({super.key});

  @override
  ConsumerState<MobileTopupPage> createState() => _MobileTopupPageState();
}

class _MobileTopupPageState extends ConsumerState<MobileTopupPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  _AccountDropdownItem? _selectedAccount;
  bool _didPrefill = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }


  void _goBackSafely() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.billPaymentHub);
    }
  }

  MobileOperatorInfo get _operatorInfo => MobileOperatorResolver.resolve(_phoneController.text.trim());

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return 'أدخل رقم الهاتف';
    if (!MobileOperatorResolver.isValidTopupPhone(phone)) return 'أدخل رقم هاتف صحيح';
    return null;
  }

  String? _validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'أدخل المبلغ';
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) return 'أدخل مبلغًا صحيحًا';
    return null;
  }

  Future<void> _showInfoDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151C2E),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('حسنًا'))],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final selectedAccount = _selectedAccount;
    if (selectedAccount == null) {
      await _showInfoDialog('الحساب مطلوب', 'لا يوجد حساب YER متاح لاستخدام خدمة الشحن.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount > selectedAccount.balance) {
      await _showInfoDialog(
        'الرصيد غير كافٍ',
        'الرصيد المتاح في هذا الحساب هو ${selectedAccount.balance.toStringAsFixed(2)} ${selectedAccount.currencyCode}.',
      );
      return;
    }

    final operator = _operatorInfo;
    if (!operator.isKnown) {
      await _showInfoDialog('رقم غير مدعوم', 'لا يمكن تحديد شبكة رقم الهاتف المدخل.');
      return;
    }

    ref.read(mobileTopupFormProvider.notifier).setSourceAccount(
          accountId: selectedAccount.accountId,
          currencyId: selectedAccount.currencyId,
          accountName: selectedAccount.name,
          currencyCode: selectedAccount.currencyCode,
          accountNumber: selectedAccount.accountNumber,
        );
    ref.read(mobileTopupFormProvider.notifier).setPhoneNumber(
          value: _phoneController.text.trim(),
          operatorName: operator.name,
        );
    ref.read(mobileTopupFormProvider.notifier).setAmount(_amountController.text.trim());
    ref.read(mobileTopupFormProvider.notifier).setNotes(_notesController.text.trim());

    if (!mounted) return;
    context.push(RouteNames.mobileTopupConfirm);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final topupForm = ref.watch(mobileTopupFormProvider);

    if (!_didPrefill) {
      _didPrefill = true;
      _phoneController.text = topupForm.phoneNumber;
      _amountController.text = topupForm.amount;
      _notesController.text = topupForm.notes;
    }

    return OperationEntryPage(
      title: 'شحن الهاتف',
      onBack: _goBackSafely,
      body: walletState.when(
        loading: () => const SizedBox(
          height: 320,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox(
          height: 320,
          child: Center(
            child: Text(
              'تعذر تحميل الحسابات',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
        data: (wallet) {
          final accounts = wallet.accounts
              .where((a) => a.currencyCode.toUpperCase() == 'YER')
              .toList();
          final items = accounts
              .map((account) => _AccountDropdownItem.fromAccount(account: account))
              .toList();

          if (_selectedAccount == null && items.isNotEmpty) {
            if (topupForm.fromAccountId != null) {
              for (final item in items) {
                if (item.accountId == topupForm.fromAccountId) {
                  _selectedAccount = item;
                  break;
                }
              }
            }
            _selectedAccount ??= items.first;
          }

          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'خدمة الشحن متاحة فقط من حساب YER، ولم يتم العثور على حساب YER في المحفظة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textPrimary, height: 1.6),
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<_AccountDropdownItem>(
                  value: _selectedAccount,
                  decoration: const InputDecoration(labelText: 'الحساب المرسل (YER)'),
                  items: items
                      .map(
                        (item) => DropdownMenuItem<_AccountDropdownItem>(
                      value: item,
                      child: Text(
                        '${item.currencyCode} - ${item.accountNumber} - ${item.balance.toStringAsFixed(2)}',
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedAccount = value),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  validator: _validateAmount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('متابعة'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountDropdownItem {
  final int accountId;
  final int currencyId;
  final String name;
  final String currencyCode;
  final String accountNumber;
  final double balance;

  const _AccountDropdownItem({
    required this.accountId,
    required this.currencyId,
    required this.name,
    required this.currencyCode,
    required this.accountNumber,
    required this.balance,
  });

  factory _AccountDropdownItem.fromAccount({required WalletAccountEntity account}) {
    return _AccountDropdownItem(
      accountId: account.id,
      currencyId: account.currencyId,
      name: account.currencyName,
      currencyCode: account.currencyCode,
      accountNumber: account.accountNumber,
      balance: account.balance,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _AccountDropdownItem && other.accountId == accountId && other.currencyId == currencyId;
  }

  @override
  int get hashCode => Object.hash(accountId, currencyId);
}
