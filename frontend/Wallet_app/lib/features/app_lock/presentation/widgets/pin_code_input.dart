import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:y_wallet/app/theme/app_colors.dart';

enum PinInputStatus {
  idle,
  success,
  error,
}

class PinCodeInput extends StatefulWidget {
  const PinCodeInput({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.status = PinInputStatus.idle,
    this.successFilledCount = 0,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final PinInputStatus status;
  final int successFilledCount;

  @override
  State<PinCodeInput> createState() => PinCodeInputState();
}

class PinCodeInputState extends State<PinCodeInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String get value => _controller.text;

  void clearAll() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
    _focusNode.requestFocus();
  }

  void removeLast() {
    if (_controller.text.isEmpty) return;
    _controller.text = _controller.text.substring(0, _controller.text.length - 1);
    widget.onChanged?.call(_controller.text);
    setState(() {});
    _focusNode.requestFocus();
  }

  void requestKeyboard() {
    _focusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _borderColor(int index, int filledCount) {
    switch (widget.status) {
      case PinInputStatus.error:
        return AppColors.error;
      case PinInputStatus.success:
        return index < widget.successFilledCount
            ? AppColors.success
            : AppColors.cardBorder;
      case PinInputStatus.idle:
        if (index == filledCount && _focusNode.hasFocus) {
          return AppColors.primary;
        }
        if (index < filledCount) {
          return AppColors.primary;
        }
        return AppColors.cardBorder;
    }
  }

  Color _fillColor(int index) {
    switch (widget.status) {
      case PinInputStatus.error:
        return AppColors.error.withOpacity(0.10);
      case PinInputStatus.success:
        return index < widget.successFilledCount
            ? AppColors.success.withOpacity(0.10)
            : AppColors.inputFill;
      case PinInputStatus.idle:
        return AppColors.inputFill;
    }
  }

  void _handleChanged(String raw) {
    final sanitized = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (sanitized != raw) {
      _controller.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }

    widget.onChanged?.call(sanitized);
    setState(() {});

    if (sanitized.length == widget.length) {
      widget.onCompleted(sanitized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filledCount = _controller.text.length;

    return GestureDetector(
      onTap: requestKeyboard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    onChanged: _handleChanged,
                  ),
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: List.generate(widget.length, (index) {
                    final isFilled = index < filledCount;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index == widget.length - 1 ? 0 : 10,
                        ),
                        height: 68,
                        decoration: BoxDecoration(
                          color: _fillColor(index),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _borderColor(index, filledCount),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 140),
                          child: isFilled
                              ? const Text(
                            '•',
                            key: ValueKey('filled'),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: removeLast,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.backspace_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'مسح',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}