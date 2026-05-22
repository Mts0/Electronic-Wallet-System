import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/kyc/domain/entities/kyc_entity.dart';
import 'package:y_wallet/features/kyc/presentation/controllers/kyc_controller.dart';

class KycDataPage extends ConsumerStatefulWidget {
  const KycDataPage({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  ConsumerState<KycDataPage> createState() => _KycDataPageState();
}

class _KycDataPageState extends ConsumerState<KycDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _locationController = TextEditingController();
  final _apartmentController = TextEditingController();

  KycDocumentType? _selectedDocumentType;
  DateTime? _selectedExpiry;
  bool _isSubmitting = false;
  bool _didPrefill = false;
  String? _resolvedPhone;

  @override
  void initState() {
    super.initState();
    _resolvePhone();
  }

  Future<void> _resolvePhone() async {
    if (widget.phoneNumber != null && widget.phoneNumber!.trim().isNotEmpty) {
      setState(() => _resolvedPhone = widget.phoneNumber!.trim());
      return;
    }

    final sessionStorage = ref.read(sessionStorageProvider);
    final phone = await sessionStorage.getCurrentUserPhone();
    if (!mounted) return;
    setState(() => _resolvedPhone = phone?.trim());
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _nationalityController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(() => _selectedExpiry = picked);
    }
  }

  Future<void> _submit(String phone) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDocumentType == null) {
      await _showMessage('نوع الوثيقة مطلوب');
      return;
    }
    if (_selectedExpiry == null) {
      await _showMessage('تاريخ انتهاء الوثيقة مطلوب');
      return;
    }

    setState(() => _isSubmitting = true);
    await ref.read(kycFlowProvider(phone).notifier).saveDraft(
          documentType: _selectedDocumentType!,
          idNumber: _idNumberController.text.trim(),
          idExpiry: _selectedExpiry!,
          nationality: _nationalityController.text.trim(),
          country: _countryController.text.trim(),
          city: _cityController.text.trim(),
          location: _locationController.text.trim(),
          apartment: _apartmentController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    context.push(RouteNames.kycCapture, extra: phone);
  }

  Future<void> _showMessage(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151C2E),
        title: const Text('تنبيه', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('حسنًا')),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final phone = _resolvedPhone;
    if (phone == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final kycState = ref.watch(kycFlowProvider(phone));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('بيانات التحقق'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.dashboard);
            }
          },
        ),
      ),
      body: kycState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString(), style: const TextStyle(color: AppColors.textPrimary))),
        data: (kyc) {
          if (!_didPrefill) {
            _didPrefill = true;
            _selectedDocumentType = kyc.documentType;
            _selectedExpiry = kyc.idExpiry;
            _idNumberController.text = kyc.idNumber;
            _nationalityController.text = kyc.nationality;
            _countryController.text = kyc.country;
            _cityController.text = kyc.city;
            _locationController.text = kyc.location;
            _apartmentController.text = kyc.apartment;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<KycDocumentType>(
                    value: _selectedDocumentType,
                    decoration: const InputDecoration(labelText: 'نوع الوثيقة'),
                    items: const [
                      DropdownMenuItem(value: KycDocumentType.nationalId, child: Text('بطاقة شخصية')),
                      DropdownMenuItem(value: KycDocumentType.passport, child: Text('جواز سفر')),
                    ],
                    onChanged: (value) => setState(() => _selectedDocumentType = value),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _idNumberController,
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'أدخل رقم الوثيقة' : null,
                    decoration: const InputDecoration(labelText: 'رقم الوثيقة'),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickExpiryDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'تاريخ انتهاء الوثيقة'),
                      child: Text(
                        _selectedExpiry == null ? 'اختر التاريخ' : _formatDate(_selectedExpiry!),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nationalityController,
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'أدخل الجنسية' : null,
                    decoration: const InputDecoration(labelText: 'الجنسية'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: 'الدولة (اختياري)'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cityController,
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'أدخل المدينة' : null,
                    decoration: const InputDecoration(labelText: 'المدينة'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationController,
                    validator: (value) => (value?.trim().isEmpty ?? true) ? 'أدخل العنوان أو الموقع' : null,
                    decoration: const InputDecoration(labelText: 'الموقع / العنوان'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _apartmentController,
                    decoration: const InputDecoration(labelText: 'الشقة / المعلم (اختياري)'),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submit(phone),
                    child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                        : const Text('حفظ والمتابعة للصور'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
