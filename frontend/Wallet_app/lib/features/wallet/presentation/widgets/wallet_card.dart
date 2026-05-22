import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:flutter/services.dart';

class WalletCard extends StatefulWidget {
  const WalletCard({
    super.key,
    required this.account,
    required this.isActive,
  });

  final WalletAccountEntity account;
  final bool isActive;

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _isBalanceVisible = false;

  OverlayEntry? _copyToastEntry;

  void _showCopyToast(Offset globalPosition) {
    _copyToastEntry?.remove();

    _copyToastEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: globalPosition.dx - 45,
          top: globalPosition.dy - 52,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'تم النسخ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_copyToastEntry!);

    Future.delayed(const Duration(milliseconds: 1100), () {
      _copyToastEntry?.remove();
      _copyToastEntry = null;
    });
  }

  Future<void> _copyWalletNumber(Offset globalPosition) async {
    final walletNumber = widget.account.accountNumber.trim();
    if (walletNumber.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: walletNumber));

    if (!mounted) return;
    _showCopyToast(globalPosition);
  }

  @override
  void dispose() {
    _copyToastEntry?.remove();
    super.dispose();
  }


  String _accountIdFromNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      return digits.substring(digits.length - 4);
    }
    return value.replaceAll('*', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _WalletCardTheme.fromCurrency(widget.account.currencyCode);
    final accountId = _accountIdFromNumber(widget.account.accountNumber);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: 212,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isActive ? 0.22 : 0.12),
            blurRadius: widget.isActive ? 28 : 16,
            offset: Offset(0, widget.isActive ? 14 : 8),
          ),
          BoxShadow(
            color: theme.accent.withOpacity(widget.isActive ? 0.16 : 0.08),
            blurRadius: widget.isActive ? 18 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WalletBackgroundPainter(
                  currencyCode: widget.account.currencyCode,
                  accent: theme.accent,
                  isActive: widget.isActive,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.02),
                        Colors.transparent,
                        Colors.black.withOpacity(0.10),
                      ],
                      stops: const [0.0, 0.18, 0.58, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _EdgeGlowPainter(
                    accent: theme.accent,
                    isActive: widget.isActive,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.account.currencyCode,
                        style: TextStyle(
                          color: theme.codeColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'ID $accountId',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.account.currencyName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.96),
                      fontSize: 15.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الرصيد الحالي',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 13.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _BalanceText(
                      balance: widget.account.balance,
                      currencyCode: widget.account.currencyCode,
                      isVisible: _isBalanceVisible,
                      accent: theme.accent,
                    ),
                  ),
                  const Spacer(),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPressStart: (details) {
                              _copyWalletNumber(details.globalPosition);
                            },
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.account.accountNumber,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.86),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.26,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              _isBalanceVisible = !_isBalanceVisible;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.11),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Icon(
                              _isBalanceVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withOpacity(0.96),
                              size: 21,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceText extends StatelessWidget {
  const _BalanceText({
    required this.balance,
    required this.currencyCode,
    required this.isVisible,
    required this.accent,
  });

  final double balance;
  final String currencyCode;
  final bool isVisible;
  final Color accent;

  String _formatBalance(double value) {
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

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const Text(
        '••••••••',
        style: TextStyle(
          color: Colors.white,
          fontSize: 29,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        children: [
          TextSpan(
            text: _formatBalance(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCardTheme {
  const _WalletCardTheme({
    required this.gradient,
    required this.accent,
    required this.codeColor,
  });

  final List<Color> gradient;
  final Color accent;
  final Color codeColor;

  factory _WalletCardTheme.fromCurrency(String code) {
    switch (code) {
      case 'SAR':
        return const _WalletCardTheme(
          gradient: [
            Color(0xFF20A39A),
            Color(0xFF186D84),
            Color(0xFF123662),
          ],
          accent: Color(0xFF7EF3E1),
          codeColor: Color(0xFFF8FFFF),
        );
      case 'USD':
        return const _WalletCardTheme(
          gradient: [
            Color(0xFF2A84FF),
            Color(0xFF1D56D2),
            Color(0xFF10286F),
          ],
          accent: Color(0xFF76C4FF),
          codeColor: Color(0xFFE7F6FF),
        );
      case 'YER':
      default:
        return const _WalletCardTheme(
          gradient: [
            Color(0xFF17336F),
            Color(0xFF0D1D4A),
            Color(0xFF070E28),
          ],
          accent: Color(0xFFE2B86C),
          codeColor: Color(0xFFF0CB84),
        );
    }
  }
}

class _EdgeGlowPainter extends CustomPainter {
  const _EdgeGlowPainter({
    required this.accent,
    required this.isActive,
  });

  final Color accent;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(30),
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 1.5 : 1.0
      ..color = accent.withOpacity(isActive ? 0.18 : 0.10)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        isActive ? 6 : 4,
      );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(isActive ? 0.10 : 0.06);

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _EdgeGlowPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.isActive != isActive;
  }
}

class _WalletBackgroundPainter extends CustomPainter {
  const _WalletBackgroundPainter({
    required this.currencyCode,
    required this.accent,
    required this.isActive,
  });

  final String currencyCode;
  final Color accent;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    switch (currencyCode) {
      case 'SAR':
        _paintSar(canvas, size);
        break;
      case 'USD':
        _paintUsd(canvas, size);
        break;
      case 'YER':
      default:
        _paintYer(canvas, size);
        break;
    }
  }

  void _paintSar(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withOpacity(0.09);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = accent.withOpacity(isActive ? 0.20 : 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withOpacity(0.16);

    for (int i = 0; i < 7; i++) {
      final path = Path()
        ..moveTo(-20, size.height * (0.60 + i * 0.012))
        ..cubicTo(
          size.width * 0.05,
          size.height * (0.52 + i * 0.010),
          size.width * 0.18,
          size.height * (0.70 + i * 0.008),
          size.width * 0.38,
          size.height * (0.60 + i * 0.006),
        )
        ..cubicTo(
          size.width * 0.56,
          size.height * (0.48 + i * 0.004),
          size.width * 0.72,
          size.height * (0.60 + i * 0.004),
          size.width * 1.04,
          size.height * (0.46 + i * 0.003),
        );
      canvas.drawPath(path, wavePaint);
      if (i == 1) {
        canvas.drawPath(path, glowPaint);
      }
    }

    for (int i = 0; i < 26; i++) {
      final x = size.width * 0.48 + (i % 6) * 7 + i * 1.5;
      final y = size.height * 0.24 + (i % 5) * 8 + i * 0.7;
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 2) * 0.45, dotPaint);
    }

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withOpacity(0.10);

    final haloGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = accent.withOpacity(0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final haloRect = Rect.fromCircle(
      center: Offset(size.width * 0.73, size.height * 0.31),
      radius: 62,
    );

    canvas.drawArc(
      haloRect,
      -0.25,
      2.1,
      false,
      haloGlowPaint,
    );
    canvas.drawArc(
      haloRect,
      -0.10,
      2.0,
      false,
      haloPaint,
    );

    final emblemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(0.10);

    final trunkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.10);

    final palmCenter = Offset(size.width * 0.73, size.height * 0.29);

    canvas.drawLine(
      Offset(palmCenter.dx, palmCenter.dy + 12),
      Offset(palmCenter.dx, palmCenter.dy + 42),
      trunkPaint,
    );

    for (int i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + (i - 2.5) * 0.35;
      final end = Offset(
        palmCenter.dx + math.cos(angle) * 22,
        palmCenter.dy + math.sin(angle) * 22,
      );
      canvas.drawLine(palmCenter, end, trunkPaint);
    }

    final sword1 = Path()
      ..moveTo(size.width * 0.64, size.height * 0.43)
      ..quadraticBezierTo(
        size.width * 0.73,
        size.height * 0.52,
        size.width * 0.85,
        size.height * 0.46,
      );

    final sword2 = Path()
      ..moveTo(size.width * 0.85, size.height * 0.43)
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.52,
        size.width * 0.64,
        size.height * 0.46,
      );

    canvas.drawPath(sword1, emblemPaint);
    canvas.drawPath(sword2, emblemPaint);
  }

  void _paintUsd(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = accent.withOpacity(0.17);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..color = accent.withOpacity(isActive ? 0.18 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.09);

    final center = Offset(size.width * 0.76, size.height * 0.34);

    final circleRect = Rect.fromCircle(center: center, radius: 64);

    canvas.drawArc(circleRect, -0.28, 1.95, false, glowPaint);
    canvas.drawArc(circleRect, -0.16, 1.92, false, ringPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: Colors.white.withOpacity(0.11),
          fontSize: 118,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 8),
    );

    for (int i = 0; i < 6; i++) {
      final path = Path()
        ..moveTo(size.width * 0.08, size.height * (0.60 + i * 0.012))
        ..cubicTo(
          size.width * 0.22,
          size.height * (0.56 + i * 0.010),
          size.width * 0.36,
          size.height * (0.69 + i * 0.008),
          size.width * 0.50,
          size.height * (0.60 + i * 0.006),
        )
        ..cubicTo(
          size.width * 0.66,
          size.height * (0.51 + i * 0.004),
          size.width * 0.79,
          size.height * (0.60 + i * 0.004),
          size.width * 0.96,
          size.height * (0.49 + i * 0.003),
        );
      canvas.drawPath(path, wavePaint);
    }

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withOpacity(0.15);

    for (int i = 0; i < 18; i++) {
      final x = size.width * 0.62 + (i % 5) * 8 + i * 2.0;
      final y = size.height * 0.23 + (i % 4) * 9 + i * 0.7;
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 2) * 0.4, dotPaint);
    }
  }

  void _paintYer(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent.withOpacity(0.58);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withOpacity(0.05);

    final groundY = size.height * 0.72;

    final skyline = <Rect>[
      Rect.fromLTWH(size.width * 0.58, groundY - 40, 30, 40),
      Rect.fromLTWH(size.width * 0.64, groundY - 60, 34, 60),
      Rect.fromLTWH(size.width * 0.70, groundY - 86, 38, 86),
      Rect.fromLTWH(size.width * 0.77, groundY - 72, 34, 72),
      Rect.fromLTWH(size.width * 0.83, groundY - 98, 28, 98),
      Rect.fromLTWH(size.width * 0.88, groundY - 66, 24, 66),
    ];

    for (final rect in skyline) {
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, linePaint);

      final cols = math.max(1, (rect.width / 10).floor());
      final rows = math.max(2, (rect.height / 18).floor());

      for (int c = 0; c < cols; c++) {
        for (int r = 0; r < rows; r++) {
          final wx = rect.left + 4.5 + c * 10.0;
          final wy = rect.top + 7 + r * 16.0;
          canvas.drawRect(
            Rect.fromLTWH(wx, wy, 3.6, 5.0),
            Paint()..color = accent.withOpacity(0.34),
          );
        }
      }
    }

    canvas.drawLine(
      Offset(size.width * 0.56, groundY),
      Offset(size.width * 0.93, groundY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WalletBackgroundPainter oldDelegate) {
    return oldDelegate.currencyCode != currencyCode ||
        oldDelegate.accent != accent ||
        oldDelegate.isActive != isActive;
  }
}