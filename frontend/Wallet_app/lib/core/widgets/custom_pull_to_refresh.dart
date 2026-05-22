import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:y_wallet/app/theme/app_colors.dart';

class CustomPullToRefresh extends StatefulWidget {
  const CustomPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.triggerDistance = 108,
    this.maxPullDistance = 150,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double triggerDistance;
  final double maxPullDistance;

  @override
  State<CustomPullToRefresh> createState() => _CustomPullToRefreshState();
}

class _CustomPullToRefreshState extends State<CustomPullToRefresh>
    with TickerProviderStateMixin {
  late final AnimationController _settleController;
  late final AnimationController _spinController;

  Animation<double>? _settleAnimation;

  double _pullExtent = 0;
  bool _isRefreshing = false;
  bool _isDragging = false;
  Timer? _wheelSettleTimer;

  @override
  void initState() {
    super.initState();

    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
      final animation = _settleAnimation;
      if (animation == null) return;

      setState(() {
        _pullExtent = animation.value;
      });
    });

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _wheelSettleTimer?.cancel();
    _settleController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _setPullExtent(double value) {
    _settleController.stop();
    _wheelSettleTimer?.cancel();

    setState(() {
      _pullExtent = value.clamp(0, widget.maxPullDistance);
    });
  }

  void _animateTo(double target) {
    _settleController.stop();

    _settleAnimation = Tween<double>(
      begin: _pullExtent,
      end: target.clamp(0, widget.maxPullDistance),
    ).animate(
      CurvedAnimation(
        parent: _settleController,
        curve: Curves.easeOutCubic,
      ),
    );

    _settleController.forward(from: 0);
  }

  void _scheduleDesktopSettle() {
    _wheelSettleTimer?.cancel();
    _wheelSettleTimer = Timer(const Duration(milliseconds: 130), () {
      if (!mounted || _isRefreshing || _isDragging) return;

      if (_pullExtent >= widget.triggerDistance) {
        _triggerRefresh();
      } else {
        _animateTo(0);
      }
    });
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;

    _wheelSettleTimer?.cancel();

    setState(() {
      _isRefreshing = true;
      _pullExtent = widget.triggerDistance + 10;
    });

    _spinController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (!mounted) return;

      _spinController.stop();
      _spinController.reset();

      setState(() {
        _isRefreshing = false;
      });

      _animateTo(0);
    }
  }

  bool _handleNotification(ScrollNotification notification) {
    if (_isRefreshing) return false;

    final metrics = notification.metrics;
    final atTop = metrics.pixels <= metrics.minScrollExtent + 0.5;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null && atTop) {
        _isDragging = true;
      }
    }

    if (notification is OverscrollNotification) {
      if (notification.overscroll < 0 &&
          metrics.pixels <= metrics.minScrollExtent + 0.5) {
        _setPullExtent(_pullExtent + (-notification.overscroll * 0.55));
        _scheduleDesktopSettle();
      } else if (_pullExtent > 0 && notification.overscroll > 0) {
        _setPullExtent(_pullExtent - (notification.overscroll * 0.55));
        _scheduleDesktopSettle();
      }
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;

      if (atTop && delta < 0) {
        _setPullExtent(_pullExtent + (-delta * 0.9));
        _scheduleDesktopSettle();
      } else if (_pullExtent > 0 && delta > 0) {
        _setPullExtent(_pullExtent - (delta * 0.9));
        _scheduleDesktopSettle();
      }
    }

    if (notification is ScrollEndNotification) {
      _isDragging = false;
      _wheelSettleTimer?.cancel();

      if (_pullExtent >= widget.triggerDistance) {
        _triggerRefresh();
      } else {
        _animateTo(0);
      }
    }

    return false;
  }

  double get _progress {
    return (_pullExtent / widget.triggerDistance).clamp(0.0, 1.0);
  }

  double get _visibleExtent {
    if (_isRefreshing) return widget.triggerDistance + 10;
    return _pullExtent;
  }

  @override
  Widget build(BuildContext context) {
    final indicatorTop = (_visibleExtent - 52).clamp(0.0, 54.0);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _visibleExtent,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, indicatorTop),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: (_visibleExtent <= 2 && !_isRefreshing) ? 0 : 1,
                  child: _RefreshOrb(
                    progress: _progress,
                    isRefreshing: _isRefreshing,
                    spinController: _spinController,
                  ),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, _visibleExtent),
          child: ScrollConfiguration(
            behavior: const _PullRefreshScrollBehavior(),
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleNotification,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

class _PullRefreshScrollBehavior extends MaterialScrollBehavior {
  const _PullRefreshScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

class _RefreshOrb extends StatelessWidget {
  const _RefreshOrb({
    required this.progress,
    required this.isRefreshing,
    required this.spinController,
  });

  final double progress;
  final bool isRefreshing;
  final AnimationController spinController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: spinController,
          builder: (context, child) {
            final angle = isRefreshing ? spinController.value * 2 * math.pi : 0.0;

            return Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: const Size(26, 26),
                painter: _RefreshPainter(
                  progress: progress,
                  color: progress >= 1 ? AppColors.primary : Colors.white,
                  refreshing: isRefreshing,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RefreshPainter extends CustomPainter {
  const _RefreshPainter({
    required this.progress,
    required this.color,
    required this.refreshing,
  });

  final double progress;
  final Color color;
  final bool refreshing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 3.5;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final startAngle = -math.pi / 2;
    final sweep = refreshing
        ? math.pi * 1.6
        : (math.pi * 1.8 * progress).clamp(0.16, math.pi * 1.8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      foregroundPaint,
    );

    final arrowAngle = startAngle + sweep;
    final arrowPoint = Offset(
      center.dx + radius * math.cos(arrowAngle),
      center.dy + radius * math.sin(arrowAngle),
    );

    final tangentAngle = arrowAngle + math.pi / 2;
    const headSize = 5.2;

    final p1 = Offset(
      arrowPoint.dx - headSize * math.cos(tangentAngle - 0.65),
      arrowPoint.dy - headSize * math.sin(tangentAngle - 0.65),
    );

    final p2 = Offset(
      arrowPoint.dx - headSize * math.cos(tangentAngle + 0.65),
      arrowPoint.dy - headSize * math.sin(tangentAngle + 0.65),
    );

    final arrowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(arrowPoint.dx, arrowPoint.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RefreshPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.refreshing != refreshing;
  }
}