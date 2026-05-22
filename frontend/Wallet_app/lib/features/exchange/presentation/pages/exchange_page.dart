import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/finance/widgets/operation_entry_page.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:y_wallet/features/exchange/presentation/controllers/exchange_controller.dart';
import 'package:y_wallet/features/exchange/presentation/controllers/exchange_quote_controller.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

class ExchangePage extends ConsumerStatefulWidget {
  const ExchangePage({super.key});

  @override
  ConsumerState<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends ConsumerState<ExchangePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountFocus = FocusNode();
  final _notesFocus = FocusNode();

  bool _didPrefill = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _amountFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSessionExpiredFromFlow() async {
    ref.read(exchangeQuoteProvider.notifier).clearQuoteState();
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

  void _clearQuoteState() {
    ref.read(exchangeQuoteProvider.notifier).clearQuoteState();
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

  Future<void> _continue({
    required _AccountDropdownItem? fromItem,
    required _AccountDropdownItem? toItem,
  }) async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (fromItem == null) {
      await _showInfoDialog(
        title: 'الحساب المصدر مطلوب',
        message: 'اختر الحساب الذي تريد المصارفة منه قبل المتابعة',
      );
      return;
    }

    if (toItem == null) {
      await _showInfoDialog(
        title: 'الحساب الهدف مطلوب',
        message: 'اختر الحساب الذي تريد استلام العملة فيه قبل المتابعة',
      );
      return;
    }

    if (fromItem.currencyCode == toItem.currencyCode) {
      await _showInfoDialog(
        title: 'اختيار غير صالح',
        message: 'يجب أن تكون العملة المصدر مختلفة عن العملة الهدف',
      );
      return;
    }

    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (enteredAmount > fromItem.balance) {
      await _showInfoDialog(
        title: 'الرصيد غير كافٍ',
        message:
            'الرصيد المتاح في هذا الحساب هو ${_formatAmount(fromItem.balance)} ${fromItem.currencyCode}، ولا يمكن تنفيذ مصارفة بمبلغ أكبر منه.',
      );
      return;
    }

    final quoteLoaded = await ref.read(exchangeQuoteProvider.notifier).loadQuote(
          baseCurrency: fromItem.currencyCode,
          targetCurrency: toItem.currencyCode,
        );

    if (!quoteLoaded) return;

    ref.read(exchangeFormProvider.notifier)
      ..setFromAccount(
        accountId: fromItem.accountId,
        currencyId: fromItem.currencyId,
        accountName: fromItem.name,
        currencyCode: fromItem.currencyCode,
        accountNumber: fromItem.accountNumber,
      )
      ..setToAccount(
        accountId: toItem.accountId,
        currencyId: toItem.currencyId,
        accountName: toItem.name,
        currencyCode: toItem.currencyCode,
        accountNumber: toItem.accountNumber,
      )
      ..setAmount(_amountController.text.trim())
      ..setNotes(_notesController.text.trim());

    if (!mounted) return;
    context.push(RouteNames.exchangeConfirm);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final formState = ref.watch(exchangeFormProvider);
    final quoteState = ref.watch(exchangeQuoteProvider);

    ref.listen<ExchangeQuoteState>(exchangeQuoteProvider, (previous, next) {
      if (previous?.requiresLogin != true && next.requiresLogin) {
        _handleSessionExpiredFromFlow();
      }
    });

    if (!_didPrefill) {
      _didPrefill = true;
      _amountController.text = formState.amount;
      _notesController.text = formState.notes;
    }

    return OperationEntryPage(
      title: 'المصارفة بين الحسابات',
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
          final accounts = wallet.accounts
              .where((account) => account.status.toUpperCase() == 'ACTIVE')
              .toList();
          final distinctCurrencies = accounts
              .map((account) => account.currencyCode.trim().toUpperCase())
              .where((code) => code.isNotEmpty)
              .toSet();

          if (accounts.length < 2 || distinctCurrencies.length < 2) {
            return const _NoEligibleAccountsCard();
          }

          final items = List<_AccountDropdownItem>.generate(
            accounts.length,
            (index) => _AccountDropdownItem.fromAccount(
              account: accounts[index],
              index: index,
            ),
          );

          _AccountDropdownItem? fromItem;
          for (final item in items) {
            if (item.accountId == formState.fromAccountId) {
              fromItem = item;
              break;
            }
          }
          fromItem ??= items.isNotEmpty ? items.first : null;

          var targetItems = items
              .where(
                (item) => fromItem == null
                    ? true
                    : item.accountId != fromItem.accountId &&
                        item.currencyCode != fromItem.currencyCode,
              )
              .toList();

          _AccountDropdownItem? toItem;
          for (final item in targetItems) {
            if (item.accountId == formState.toAccountId) {
              toItem = item;
              break;
            }
          }
          toItem ??= targetItems.isNotEmpty ? targetItems.first : null;

          if (formState.fromAccountId == null && fromItem != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(exchangeFormProvider.notifier).setFromAccount(
                    accountId: fromItem!.accountId,
                    currencyId: fromItem.currencyId,
                    accountName: fromItem.name,
                    currencyCode: fromItem.currencyCode,
                    accountNumber: fromItem.accountNumber,
                  );
            });
          }

          if (formState.toAccountId == null && toItem != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(exchangeFormProvider.notifier).setToAccount(
                    accountId: toItem!.accountId,
                    currencyId: toItem.currencyId,
                    accountName: toItem.name,
                    currencyCode: toItem.currencyCode,
                    accountNumber: toItem.accountNumber,
                  );
            });
          }

          final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0;
          final insufficientBalance =
              fromItem != null && enteredAmount > 0 && enteredAmount > fromItem.balance;

          final quote = quoteState.quote;
          final estimatedReceive =
              (quote != null && enteredAmount > 0) ? quote.estimateReceived(enteredAmount) : null;

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
                children: [
                  const _FieldLabel(text: 'الحساب المصدر'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<_AccountDropdownItem>(
                    value: fromItem,
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
                      ref.read(exchangeFormProvider.notifier)
                        ..setFromAccount(
                          accountId: value.accountId,
                          currencyId: value.currencyId,
                          accountName: value.name,
                          currencyCode: value.currencyCode,
                          accountNumber: value.accountNumber,
                        )
                        ..clearToAccount();
                      _clearQuoteState();
                      setState(() {});
                    },
                    isExpanded: true,
                    dropdownColor: const Color(0xFF151C2E),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(hintText: 'اختر الحساب المصدر'),
                  ),
                  if (fromItem != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الرصيد المتاح: ${_formatAmount(fromItem.balance)} ${fromItem.currencyCode}',
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
                  const _FieldLabel(text: 'الحساب الهدف'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<_AccountDropdownItem>(
                    value: toItem,
                    items: targetItems
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
                      ref.read(exchangeFormProvider.notifier).setToAccount(
                            accountId: value.accountId,
                            currencyId: value.currencyId,
                            accountName: value.name,
                            currencyCode: value.currencyCode,
                            accountNumber: value.accountNumber,
                          );
                      _clearQuoteState();
                      setState(() {});
                    },
                    isExpanded: true,
                    dropdownColor: const Color(0xFF151C2E),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(hintText: 'اختر الحساب الهدف'),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel(text: 'المبلغ المراد صرفه'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      _clearQuoteState();
                      ref.read(exchangeFormProvider.notifier).setAmount(
                            _amountController.text.trim(),
                          );
                      setState(() {});
                    },
                    onFieldSubmitted: (_) => _notesFocus.requestFocus(),
                    validator: _validateAmount,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: fromItem == null
                          ? 'أدخل المبلغ'
                          : 'أدخل المبلغ (${fromItem.currencyCode})',
                      suffixIcon: quoteState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.1),
                              ),
                            )
                          : null,
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
                    onChanged: (_) {
                      ref.read(exchangeFormProvider.notifier).setNotes(
                            _notesController.text.trim(),
                          );
                    },
                    onFieldSubmitted: (_) => _continue(fromItem: fromItem, toItem: toItem),
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(hintText: 'أدخل ملاحظة اختيارية'),
                  ),
                  if ((quoteState.inlineErrorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        quoteState.inlineErrorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  if (quote != null && estimatedReceive != null) ...[
                    const SizedBox(height: 14),
                    _QuoteSummaryCard(
                      fromCurrency: quote.baseCurrency,
                      toCurrency: quote.targetCurrency,
                      rate: quote.rateValue,
                      estimatedReceive: estimatedReceive,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: quoteState.isLoading
                          ? null
                          : () => _continue(fromItem: fromItem, toItem: toItem),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: quoteState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Text(
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

class _QuoteSummaryCard extends StatelessWidget {
  const _QuoteSummaryCard({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.estimatedReceive,
  });

  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final double estimatedReceive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص المصارفة',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _QuoteRow(
            label: 'سعر الصرف',
            value: '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency',
          ),
          const SizedBox(height: 8),
          _QuoteRow(
            label: 'المبلغ المتوقع استلامه',
            value: '${_ExchangePageState._formatAmount(estimatedReceive)} $toCurrency',
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: highlight ? AppColors.success : AppColors.textPrimary,
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
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

class _NoEligibleAccountsCard extends StatelessWidget {
  const _NoEligibleAccountsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لا توجد حسابات كافية للمصارفة',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'يجب أن يكون لديك حسابان نشطان بعملتين مختلفتين على الأقل حتى تتمكن من تنفيذ المصارفة بين الحسابات.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
