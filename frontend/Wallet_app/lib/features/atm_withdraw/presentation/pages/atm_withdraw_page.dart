import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/finance/widgets/operation_entry_page.dart';
import 'package:y_wallet/features/atm_withdraw/presentation/controllers/atm_withdraw_controller.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

class AtmWithdrawPage extends ConsumerStatefulWidget {
  const AtmWithdrawPage({super.key});

  @override
  ConsumerState<AtmWithdrawPage> createState() => _AtmWithdrawPageState();
}

class _AtmWithdrawPageState extends ConsumerState<AtmWithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _didPrefill = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _goBackSafely() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.dashboard);
    }
  }

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'أدخل المبلغ';
    final amount = double.tryParse(text);
    if (amount == null) return 'المبلغ غير صحيح';
    if (amount <= 0) return 'يجب أن يكون المبلغ أكبر من صفر';
    return null;
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151C2E),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  Future<void> _continue(
    _AccountDropdownItem? selectedAccount,
    BankOption? selectedBank,
  ) async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (selectedAccount == null) {
      await _showInfoDialog(
        title: 'الحساب مطلوب',
        message: 'اختر الحساب الذي سيتم الخصم منه قبل المتابعة',
      );
      return;
    }

    if (selectedBank == null) {
      await _showInfoDialog(
        title: 'البنك مطلوب',
        message: 'اختر البنك الذي ستنفذ منه عملية السحب بدون بطاقة',
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount > selectedAccount.balance) {
      await _showInfoDialog(
        title: 'الرصيد غير كافٍ',
        message:
            'الرصيد المتاح في هذا الحساب هو ${_formatAmount(selectedAccount.balance)} ${selectedAccount.currencyCode}، ولا يمكن طلب سحب بمبلغ أكبر منه.',
      );
      return;
    }

    ref.read(atmWithdrawFormProvider.notifier).setSourceAccount(
          accountId: selectedAccount.accountId,
          currencyId: selectedAccount.currencyId,
          accountName: selectedAccount.name,
          accountNumber: selectedAccount.accountNumber,
          currencyCode: selectedAccount.currencyCode,
        );
    ref.read(atmWithdrawFormProvider.notifier).setBank(
          bankId: selectedBank.bankId,
          bankName: selectedBank.name,
        );
    ref.read(atmWithdrawFormProvider.notifier).setAmount(
          _amountController.text.trim(),
        );
    ref.read(atmWithdrawFormProvider.notifier).setNote(
          _noteController.text.trim(),
        );

    context.push(RouteNames.atmWithdrawConfirm);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final banksState = ref.watch(atmBanksProvider);
    final formState = ref.watch(atmWithdrawFormProvider);

    if (!_didPrefill) {
      _didPrefill = true;
      _amountController.text = formState.amount;
      _noteController.text = formState.note;
    }

    return OperationEntryPage(
      title: 'سحب بدون بطاقة',
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
          final accountItems = wallet.accounts
              .map((account) => _AccountDropdownItem.fromAccount(account))
              .toList();

          _AccountDropdownItem? selectedAccount;
          for (final item in accountItems) {
            if (item.accountId == formState.accountId) {
              selectedAccount = item;
              break;
            }
          }
          selectedAccount ??= accountItems.isNotEmpty ? accountItems.first : null;

          final amount = double.tryParse(_amountController.text.trim()) ?? 0;
          final insufficientBalance =
              selectedAccount != null && amount > 0 && amount > selectedAccount.balance;

          return banksState.when(
            loading: () => const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Center(
              child: Text(
                error.toString(),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            data: (banks) {
              BankOption? selectedBank;
              for (final bank in banks) {
                if (bank.bankId == formState.bankId) {
                  selectedBank = bank;
                  break;
                }
              }
              selectedBank ??= banks.isNotEmpty ? banks.first : null;

              if (accountItems.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'لا توجد حسابات متاحة للسحب بدون بطاقة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary, height: 1.6),
                    ),
                  ),
                );
              }

              if (banks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'لا توجد بنوك مفعلة في الباك اند للسحب بدون بطاقة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary, height: 1.6),
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF12192B).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FieldLabel(text: 'الحساب المرسل'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<_AccountDropdownItem>(
                        value: selectedAccount,
                        isExpanded: true,
                        decoration: const InputDecoration(hintText: 'اختر الحساب'),
                        items: accountItems
                            .map(
                              (item) => DropdownMenuItem<_AccountDropdownItem>(
                                value: item,
                                child: Text(
                                  '${item.name} - ${item.currencyCode}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          ref.read(atmWithdrawFormProvider.notifier).setSourceAccount(
                                accountId: value.accountId,
                                currencyId: value.currencyId,
                                accountName: value.name,
                                accountNumber: value.accountNumber,
                                currencyCode: value.currencyCode,
                              );
                          setState(() {});
                        },
                        dropdownColor: const Color(0xFF151C2E),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selectedAccount != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'الرصيد المتاح: ${_formatAmount(selectedAccount.balance)} ${selectedAccount.currencyCode}',
                            style: TextStyle(
                              color: insufficientBalance
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontSize: 12.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const _FieldLabel(text: 'البنك'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<BankOption>(
                        value: selectedBank,
                        isExpanded: true,
                        decoration: const InputDecoration(hintText: 'اختر البنك'),
                        items: banks
                            .map(
                              (bank) => DropdownMenuItem<BankOption>(
                                value: bank,
                                child: Text(
                                  bank.code?.trim().isNotEmpty == true
                                      ? '${bank.name} (${bank.code})'
                                      : bank.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          ref.read(atmWithdrawFormProvider.notifier).setBank(
                                bankId: value.bankId,
                                bankName: value.name,
                              );
                          setState(() {});
                        },
                        dropdownColor: const Color(0xFF151C2E),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel(text: 'المبلغ'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        validator: _validateAmount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: selectedAccount == null
                              ? 'أدخل المبلغ'
                              : 'أدخل المبلغ (${selectedAccount.currencyCode})',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (insufficientBalance) ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'المبلغ المدخل أكبر من الرصيد المتاح',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const _FieldLabel(text: 'ملاحظة'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        minLines: 2,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'أدخل ملاحظة اختيارية',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _continue(selectedAccount, selectedBank),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'متابعة',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatAmount(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final reversed = whole.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(reversed[i]);
    }
    final formattedWhole = buffer.toString().split('').reversed.join();
    return '$formattedWhole.$decimal';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.4,
          fontWeight: FontWeight.w700,
        ),
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

  factory _AccountDropdownItem.fromAccount(WalletAccountEntity account) {
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
    return other is _AccountDropdownItem &&
        other.accountId == accountId &&
        other.currencyId == currencyId;
  }

  @override
  int get hashCode => Object.hash(accountId, currencyId);
}
