import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:y_wallet/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:y_wallet/features/wallet/presentation/widgets/wallet_page_indicator.dart';

class WalletCarouselSection extends ConsumerStatefulWidget {
  const WalletCarouselSection({super.key});

  @override
  ConsumerState<WalletCarouselSection> createState() =>
      _WalletCarouselSectionState();
}

class _WalletCarouselSectionState extends ConsumerState<WalletCarouselSection> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  double _currentPage = 0;
  int _currentIndex = 0;
  int? _configuredCount;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.76,
      initialPage: 0,
    );

    _currentPage = _pageController.initialPage.toDouble();

    _pageController.addListener(() {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      if (!_pageController.position.hasContentDimensions) return;

      final page =
          _pageController.page ?? _pageController.initialPage.toDouble();

      if (_currentPage == page) return;

      setState(() {
        _currentPage = page;
      });
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  double _safePageValue() {
    if (!_pageController.hasClients) {
      return _currentPage;
    }

    if (!_pageController.position.hasContentDimensions) {
      return _currentPage;
    }

    return _pageController.page ?? _currentPage;
  }

  void _configureInfiniteLoop(int count) {
    if (_configuredCount == count) return;

    _configuredCount = count;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;

      final targetPage = count * 1000;
      _pageController.jumpToPage(targetPage);

      setState(() {
        _currentPage = targetPage.toDouble();
        _currentIndex = 0;
      });

      ref.read(walletCarouselIndexProvider.notifier).state = 0;
      _restartAutoSlide(count);
    });
  }

  void _restartAutoSlide(int count) {
    _autoSlideTimer?.cancel();

    if (count <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      if (!_pageController.position.hasContentDimensions) return;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 820),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  List<WalletAccountEntity> _sortedAccounts(List<WalletAccountEntity> accounts) {
    final sorted = [...accounts];
    sorted.sort((a, b) {
      if (a.isPrimary == b.isPrimary) return 0;
      return a.isPrimary ? -1 : 1;
    });
    return sorted;
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1A2238),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);

    return walletState.when(
      loading: () {
        return Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView(
                controller: PageController(viewportFraction: 0.76),
                children: List.generate(
                  3,
                      (_) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildLoadingCard(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const WalletPageIndicator(
              length: 3,
              currentIndex: 0,
            ),
          ],
        );
      },
      error: (error, _) {
        return const SizedBox.shrink();
      },
      data: (wallet) {
        final accounts = _sortedAccounts(wallet.accounts);

        if (accounts.isEmpty) {
          return const SizedBox.shrink();
        }

        _configureInfiniteLoop(accounts.length);

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction != ScrollDirection.idle) {
                    _restartAutoSlide(accounts.length);
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    final current = page % accounts.length;

                    setState(() {
                      _currentIndex = current;
                    });

                    ref.read(walletCarouselIndexProvider.notifier).state =
                        current;
                    _restartAutoSlide(accounts.length);
                  },
                  itemBuilder: (context, index) {
                    final WalletAccountEntity item =
                    accounts[index % accounts.length];

                    final page = _safePageValue();

                    final rawDistance = (page - index).abs();
                    final distance = math.min(rawDistance, 1.0);

                    final scale = 1 - (distance * 0.22);
                    final translateY = distance * 18;
                    final opacity = 1 - (distance * 0.34);
                    final horizontalPadding = 6 + (distance * 4);

                    return Opacity(
                      opacity: opacity.clamp(0.58, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, translateY),
                        child: Transform.scale(
                          scale: scale.clamp(0.78, 1.0),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: WalletCard(
                              account: item,
                              isActive: rawDistance < 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            WalletPageIndicator(
              length: accounts.length,
              currentIndex: _currentIndex,
            ),
          ],
        );
      },
    );
  }
}