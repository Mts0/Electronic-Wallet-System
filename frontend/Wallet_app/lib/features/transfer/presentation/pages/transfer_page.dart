import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/finance/widgets/operation_entry_page.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:y_wallet/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:y_wallet/features/transfer/presentation/controllers/transfer_flow_controller.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

class TransferPage extends ConsumerStatefulWidget {
  const TransferPage({super.key});

  @override
  ConsumerState<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends ConsumerState<TransferPage> {
  final _formKey = GlobalKey<FormState>();

  final _walletNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final _walletFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _notesFocus = FocusNode();

  bool _didPrefill = false;

  @override
  void dispose() {
    _walletNumberController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _walletFocus.dispose();
    _amountFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSessionExpiredFromFlow() async {
    ref.read(transferFlowProvider.notifier).clearValidationState();
    await ref.read(authControllerProvider.notifier).logout();

    if (!mounted) return;
    context.go(RouteNames.login);
  }

  void _goBackSafely() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.dashboard);
    }
  }

  void _clearPrecheckState() {
    ref.read(transferFlowProvider.notifier).clearValidationState();
  }

  String? _validateWalletNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'أدخل رقم محفظة المستلم';
    if (text.length < 4) return 'رقم المحفظة غير صحيح';
    return null;
  }

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'أدخل المبلغ';

    final amount = double.tryParse(text);
    if (amount == null) return 'أدخل مبلغًا صحيحًا';
    if (amount <= 0) return 'يجب أن يكون المبلغ أكبر من صفر';

    return null;
  }

  Future<void> _showInfoDialog({
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151C2E),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _continue(_AccountDropdownItem? selectedItem) async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final form = ref.read(transferFormProvider);
    if (form.fromAccountId == null ||
        form.currencyId == null ||
        selectedItem == null) {
      await _showInfoDialog(
        title: 'الحساب مطلوب',
        message: 'اختر الحساب المرسل قبل المتابعة',
      );
      return;
    }

    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (enteredAmount > selectedItem.balance) {
      await _showInfoDialog(
        title: 'الرصيد غير كافٍ',
        message:
        'الرصيد المتاح في هذا الحساب هو ${_formatAmount(selectedItem.balance)} ${selectedItem.currencyCode}، ولا يمكن تحويل مبلغ أكبر منه.',
      );
      return;
    }

    final precheckPassed =
    await ref.read(transferFlowProvider.notifier).precheckTransfer(
      fromAccountId: selectedItem.accountId.toString(),
      toWalletNumber: _walletNumberController.text.trim(),
      currencyCode: selectedItem.currencyCode,
      amount: enteredAmount,
    );

    if (!precheckPassed) return;

    ref.read(transferFormProvider.notifier).setWalletNumber(
      _walletNumberController.text.trim(),
    );
    ref.read(transferFormProvider.notifier).setAmount(
      _amountController.text.trim(),
    );
    ref.read(transferFormProvider.notifier).setNotes(
      _notesController.text.trim(),
    );

    if (!mounted) return;
    context.push(RouteNames.transferConfirm);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final transferState = ref.watch(transferFormProvider);
    final flowState = ref.watch(transferFlowProvider);

    ref.listen<TransferFlowState>(
      transferFlowProvider,
          (previous, next) {
        if (previous?.requiresLogin != true && next.requiresLogin) {
          _handleSessionExpiredFromFlow();
        }
      },
    );

    if (!_didPrefill) {
      _didPrefill = true;
      _walletNumberController.text = transferState.toWalletNumber;
      _amountController.text = transferState.amount;
      _notesController.text = transferState.notes;
    }

    return OperationEntryPage(
      title: 'تحويل مالي',
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
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        data: (wallet) {
          final accounts = wallet.accounts;
          final items = List<_AccountDropdownItem>.generate(
            accounts.length,
                (index) => _AccountDropdownItem.fromAccount(
              account: accounts[index],
              index: index,
            ),
          );

          _AccountDropdownItem? selectedItem;
          for (final item in items) {
            if (item.accountId == transferState.fromAccountId) {
              selectedItem = item;
              break;
            }
          }

          final enteredAmount =
              double.tryParse(_amountController.text.trim()) ?? 0;
          final hasSelectedAccount = selectedItem != null;
          final insufficientBalance = hasSelectedAccount &&
              enteredAmount > 0 &&
              enteredAmount > selectedItem.balance;

          return Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF12192B).withOpacity(0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const _FieldLabel(text: 'الحساب المرسل'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<_AccountDropdownItem>(
                    value: selectedItem,
                    items: items
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
                      ref.read(transferFormProvider.notifier).setSourceAccount(
                        accountId: value.accountId,
                        currencyId: value.currencyId,
                        accountName: value.name,
                        currencyCode: value.currencyCode,
                        accountNumber: value.accountNumber,
                      );
                      _clearPrecheckState();
                      setState(() {});
                    },
                    isExpanded: true,
                    dropdownColor: const Color(0xFF151C2E),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'اختر الحساب',
                    ),
                  ),
                  if (selectedItem != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الرصيد المتاح: ${_formatAmount(selectedItem.balance)} ${selectedItem.currencyCode}',
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
                  const _FieldLabel(text: 'رقم محفظة المستلم'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _walletNumberController,
                    focusNode: _walletFocus,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearPrecheckState(),
                    onFieldSubmitted: (_) => _amountFocus.requestFocus(),
                    validator: _validateWalletNumber,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'أدخل رقم المحفظة',
                      suffixIcon: flowState.isChecking
                          ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.1,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),
                  if ((flowState.inlineErrorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        flowState.inlineErrorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else if ((flowState.recipientName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.20),
                          ),
                        ),
                        child: Text(
                          'المستلم: ${flowState.recipientName}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _FieldLabel(text: 'المبلغ'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9.]'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      _clearPrecheckState();
                      setState(() {});
                    },
                    onFieldSubmitted: (_) => _notesFocus.requestFocus(),
                    validator: _validateAmount,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: transferState.fromCurrencyCode.isEmpty
                          ? 'أدخل المبلغ'
                          : 'أدخل المبلغ (${transferState.fromCurrencyCode})',
                    ),
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
                    controller: _notesController,
                    focusNode: _notesFocus,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _clearPrecheckState(),
                    onFieldSubmitted: (_) => _continue(selectedItem),
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
                      onPressed: flowState.isChecking
                          ? null
                          : () => _continue(selectedItem),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: flowState.isChecking
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                          : const Text(
                        'متابعة',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  const _FieldLabel({
    required this.text,
  });

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

  factory _AccountDropdownItem.fromAccount({
    required WalletAccountEntity account,
    required int index,
  }) {
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