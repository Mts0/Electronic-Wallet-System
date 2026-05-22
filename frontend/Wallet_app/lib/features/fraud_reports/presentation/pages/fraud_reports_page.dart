import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';

class FraudReportItem {
  final int reportId;
  final String subject;
  final String description;
  final String? transactionReference;
  final String status;
  final DateTime? createdAt;

  const FraudReportItem({
    required this.reportId,
    required this.subject,
    required this.description,
    required this.transactionReference,
    required this.status,
    required this.createdAt,
  });

  factory FraudReportItem.fromJson(Map<String, dynamic> json) {
    return FraudReportItem(
      reportId: ((json['report_id'] ?? 0) as num).toInt(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      transactionReference: json['transaction_reference']?.toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}

final fraudReportsProvider = FutureProvider<List<FraudReportItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/fraud-reports/me');
  final raw = response.data;
  final items = raw is List
      ? raw
      : (raw is Map<String, dynamic>
          ? ((raw['items'] as List?) ?? (raw['data'] as List?) ?? const [])
          : const []);

  return items
      .whereType<Map>()
      .map((item) => FraudReportItem.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});

class FraudReportsPage extends ConsumerStatefulWidget {
  const FraudReportsPage({super.key});

  @override
  ConsumerState<FraudReportsPage> createState() => _FraudReportsPageState();
}

class _FraudReportsPageState extends ConsumerState<FraudReportsPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _goBackSafely() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.account);
    }
  }

  Future<void> _showInfoDialog(String title, String message) async {
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/fraud-reports/me',
        data: {
          'subject': _subjectController.text.trim(),
          if (_referenceController.text.trim().isNotEmpty)
            'transaction_reference': _referenceController.text.trim(),
          'description': _descriptionController.text.trim(),
        },
      );

      _subjectController.clear();
      _referenceController.clear();
      _descriptionController.clear();
      ref.invalidate(fraudReportsProvider);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showInfoDialog(
        'تم إرسال البلاغ',
        'تم إنشاء بلاغ الاحتيال بنجاح وسيتم مراجعته من الفريق المختص.',
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showInfoDialog(
        'تعذر إرسال البلاغ',
        _extractMessage(e),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showInfoDialog(
        'تعذر إرسال البلاغ',
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _extractMessage(DioException e) {
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
    return 'تعذر إرسال بلاغ الاحتيال';
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(fraudReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090F1E),
              Color(0xFF0A1122),
              Color(0xFF0B1020),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBackSafely,
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'شكوى احتيال',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
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
                      const Text(
                        'أرسل بلاغًا جديدًا',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _subjectController,
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'أدخل موضوع البلاغ'
                            : null,
                        decoration: const InputDecoration(labelText: 'الموضوع'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'مرجع العملية (اختياري)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 6,
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'أدخل وصف البلاغ'
                            : null,
                        decoration: const InputDecoration(labelText: 'الوصف'),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.2),
                                )
                              : const Text(
                                  'إرسال البلاغ',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'بلاغاتي السابقة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              reportsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12192B).withOpacity(0.98),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: AppColors.textPrimary, height: 1.6),
                  ),
                ),
                data: (reports) {
                  if (reports.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12192B).withOpacity(0.98),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: const Text(
                        'لا توجد بلاغات احتيال سابقة.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return Column(
                    children: reports
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReportTile(item: item),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.item});

  final FraudReportItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status.toUpperCase()) {
      'INVESTIGATING' => const Color(0xFFE6A23C),
      'RESOLVED' => AppColors.success,
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.subject,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((item.transactionReference ?? '').trim().isNotEmpty)
                _MetaBadge(text: 'المرجع: ${item.transactionReference}'),
              if (item.createdAt != null)
                _MetaBadge(text: _formatDateTime(item.createdAt!)),
              _MetaBadge(text: 'ID-${item.reportId}'),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'INVESTIGATING':
        return 'قيد التحقيق';
      case 'RESOLVED':
        return 'تم الحل';
      case 'PENDING':
      default:
        return 'قيد الانتظار';
    }
  }

  static String _formatDateTime(DateTime value) {
    return '${value.year}/${value.month}/${value.day}';
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
