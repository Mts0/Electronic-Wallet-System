import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/kyc/presentation/controllers/kyc_controller.dart';

class KycCapturePage extends ConsumerStatefulWidget {
  const KycCapturePage({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  ConsumerState<KycCapturePage> createState() => _KycCapturePageState();
}

class _KycCapturePageState extends ConsumerState<KycCapturePage> {
  final ImagePicker _imagePicker = ImagePicker();
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

    final phone = await ref.read(sessionStorageProvider).getCurrentUserPhone();
    if (!mounted) return;
    setState(() => _resolvedPhone = phone?.trim());
  }

  Future<void> _pickImage(String phone, String target) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    final controller = ref.read(kycFlowProvider(phone).notifier);
    switch (target) {
      case 'front':
        await controller.saveFrontImage(picked.path);
        break;
      case 'back':
        await controller.saveBackImage(picked.path);
        break;
      case 'selfie':
        await controller.saveSelfieImage(picked.path);
        break;
    }
  }

  Future<void> _showMessage(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151C2E),
        title: const Text('تنبيه', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('حسنًا'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = _resolvedPhone;
    if (phone == null) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
    }

    final kycState = ref.watch(kycFlowProvider(phone));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('تصوير الوثائق')),
      body: kycState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString(), style: const TextStyle(color: AppColors.textPrimary))),
        data: (kyc) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'سيتم ارسال الوثيقة الى الادارة للمراجعة',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            _CaptureTile(
              title: 'صورة الهوية من الأمام',
              imagePath: kyc.idFrontImage,
              onTap: () => _pickImage(phone, 'front'),
            ),
            const SizedBox(height: 12),
            _CaptureTile(
              title: 'صورة الهوية من الخلف',
              imagePath: kyc.idBackImage,
              onTap: () => _pickImage(phone, 'back'),
            ),
            const SizedBox(height: 12),
            _CaptureTile(
              title: 'سيلفي مع الوثيقة',
              imagePath: kyc.selfieImage,
              onTap: () => _pickImage(phone, 'selfie'),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () async {
                final current = ref.read(kycFlowProvider(phone)).value;
                if (current == null || !current.hasAllImages) {
                  await _showMessage('أكمل الصور الثلاث قبل المتابعة');
                  return;
                }
                if (!mounted) return;
                context.push(RouteNames.kycReview, extra: phone);
              },
              child: const Text('مراجعة وإرسال'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(imagePath!), fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.photo_camera_outlined, color: AppColors.textSecondary, size: 34),
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onTap,
            child: Text(hasImage ? 'إعادة الالتقاط' : 'التقاط الصورة'),
          ),
        ],
      ),
    );
  }
}
