import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/account/presentation/pages/account_page.dart';
import 'package:y_wallet/features/account/presentation/pages/change_password_page.dart';
import 'package:y_wallet/features/app_lock/presentation/pages/app_lock_page.dart';
import 'package:y_wallet/features/app_lock/presentation/pages/confirm_pin_page.dart';
import 'package:y_wallet/features/app_lock/presentation/pages/forgot_pin_otp_page.dart';
import 'package:y_wallet/features/app_lock/presentation/pages/forgot_pin_phone_page.dart';
import 'package:y_wallet/features/app_lock/presentation/pages/forgot_pin_reset_password_page.dart';
import 'package:y_wallet/features/app_lock/presentation/pages/forgot_pin_verify_password_page.dart';
import 'package:y_wallet/features/app_lock/presentation/pages/setup_pin_page.dart';
import 'package:y_wallet/features/app_lock/presentation/providers/app_lock_provider.dart';
import 'package:y_wallet/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:y_wallet/features/auth/presentation/pages/login_page.dart';
import 'package:y_wallet/features/auth/presentation/pages/otp_page.dart';
import 'package:y_wallet/features/auth/presentation/pages/register_page.dart';
import 'package:y_wallet/features/auth/presentation/pages/reset_password_page.dart';
import 'package:y_wallet/features/bill_payment/presentation/pages/bill_payment_hub_page.dart';
import 'package:y_wallet/features/bill_payment/presentation/pages/mobile_topup_confirm_page.dart';
import 'package:y_wallet/features/bill_payment/presentation/pages/mobile_topup_page.dart';
import 'package:y_wallet/features/bill_payment/presentation/pages/mobile_topup_result_page.dart';
import 'package:y_wallet/features/atm_withdraw/presentation/pages/atm_withdraw_page.dart';
import 'package:y_wallet/features/atm_withdraw/presentation/pages/atm_withdraw_confirm_page.dart';
import 'package:y_wallet/features/atm_withdraw/presentation/pages/atm_withdraw_result_page.dart';
import 'package:y_wallet/features/fraud_reports/presentation/pages/fraud_reports_page.dart';
import 'package:y_wallet/features/settings/presentation/pages/app_settings_page.dart';
import 'package:y_wallet/features/home/presentation/pages/home_page.dart';
import 'package:y_wallet/features/home/presentation/pages/home_shell_page.dart';
import 'package:y_wallet/features/notifications/presentation/pages/notifications_page.dart';
import 'package:y_wallet/features/kyc/presentation/pages/kyc_capture_page.dart';
import 'package:y_wallet/features/kyc/presentation/pages/kyc_data_page.dart';
import 'package:y_wallet/features/kyc/presentation/pages/kyc_intro_page.dart';
import 'package:y_wallet/features/kyc/presentation/pages/kyc_review_page.dart';
import 'package:y_wallet/features/kyc/presentation/pages/kyc_submitted_page.dart';
import 'package:y_wallet/features/splash/presentation/pages/splash_page.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';
import 'package:y_wallet/features/transactions/presentation/pages/transaction_details_page.dart';
import 'package:y_wallet/features/transactions/presentation/pages/transactions_page.dart';
import 'package:y_wallet/features/transfer/presentation/pages/transfer_confirm_page.dart';
import 'package:y_wallet/features/transfer/presentation/pages/transfer_page.dart';
import 'package:y_wallet/features/transfer/presentation/pages/transfer_result_page.dart';
import 'package:y_wallet/features/exchange/presentation/pages/exchange_confirm_page.dart';
import 'package:y_wallet/features/exchange/presentation/pages/exchange_page.dart';
import 'package:y_wallet/features/exchange/presentation/pages/exchange_result_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAppUnlocked = ref.watch(appUnlockedProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) async {
      final sessionStorage = ref.read(sessionStorageProvider);
      final hasSession = await sessionStorage.hasSession();
      final appLockEnabled = await sessionStorage.isAppLockEnabled();
      final location = state.uri.path;

      final guestOnlyRoutes = <String>{
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
        RouteNames.otp,
        RouteNames.resetPassword,
      };

      final alwaysAllowedRoutes = <String>{RouteNames.splash};

      final lockRoutes = <String>{
        RouteNames.appLock,
        RouteNames.setupPin,
        RouteNames.confirmPin,
        RouteNames.forgotPinVerifyPassword,
        RouteNames.forgotPinPhone,
        RouteNames.forgotPinOtp,
        RouteNames.forgotPinResetPassword,
      };

      final protectedRoutes = <String>{
        RouteNames.dashboard,
        RouteNames.transactions,
        RouteNames.transactionDetails,
        RouteNames.account,
        RouteNames.changePassword,
        RouteNames.notifications,
        RouteNames.appSettings,
        RouteNames.transfer,
        RouteNames.transferConfirm,
        RouteNames.transferResult,
        RouteNames.exchange,
        RouteNames.exchangeConfirm,
        RouteNames.exchangeResult,
        RouteNames.billPaymentHub,
        RouteNames.mobileTopup,
        RouteNames.mobileTopupConfirm,
        RouteNames.mobileTopupResult,
        RouteNames.atmWithdraw,
        RouteNames.atmWithdrawConfirm,
        RouteNames.atmWithdrawResult,
        RouteNames.fraudReports,
        RouteNames.kycIntro,
        RouteNames.kycData,
        RouteNames.kycCapture,
        RouteNames.kycReview,
        RouteNames.kycSubmitted,
      };

      final isGuestOnly = guestOnlyRoutes.contains(location);
      final isAlwaysAllowed = alwaysAllowedRoutes.contains(location);
      final isLockRoute = lockRoutes.contains(location);
      final isProtected = protectedRoutes.contains(location);

      if (!hasSession) {
        if (isProtected || isLockRoute) {
          return RouteNames.login;
        }
        return null;
      }

      if (hasSession && appLockEnabled && !isAppUnlocked) {
        if (location == RouteNames.splash) return RouteNames.appLock;
        if (isProtected || isGuestOnly || isAlwaysAllowed) return RouteNames.appLock;
        return null;
      }

      if (hasSession && isGuestOnly) {
        return RouteNames.dashboard;
      }

      if (hasSession && location == RouteNames.appLock && isAppUnlocked) {
        return RouteNames.dashboard;
      }

      if (hasSession && location == RouteNames.splash) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: RouteNames.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: RouteNames.register, builder: (context, state) => const RegisterPage()),
      GoRoute(path: RouteNames.forgotPassword, builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(
        path: RouteNames.otp,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            final map = Map<String, dynamic>.from(extra);
            return OtpPage(
              phoneNumber: (map['phoneNumber'] ?? '').toString(),
              flow: (map['flow'] ?? 'register').toString(),
            );
          }
          return OtpPage(phoneNumber: extra is String ? extra : '');
        },
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            final map = Map<String, dynamic>.from(extra);
            return ResetPasswordPage(
              phoneNumber: (map['phoneNumber'] ?? '').toString(),
              otpCode: (map['otpCode'] ?? '').toString(),
            );
          }
          return const ResetPasswordPage(phoneNumber: '', otpCode: '');
        },
      ),
      GoRoute(
        path: RouteNames.setupPin,
        builder: (context, state) {
          final resetKey = state.uri.queryParameters['reset'] ?? 'default';
          return SetupPinPage(key: ValueKey(resetKey));
        },
      ),
      GoRoute(
        path: RouteNames.confirmPin,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! String) return const SetupPinPage();
          return ConfirmPinPage(firstPin: extra);
        },
      ),
      GoRoute(path: RouteNames.appLock, builder: (context, state) => const AppLockPage()),
      GoRoute(path: RouteNames.forgotPinVerifyPassword, builder: (context, state) => const ForgotPinVerifyPasswordPage()),
      GoRoute(path: RouteNames.forgotPinPhone, builder: (context, state) => const ForgotPinPhonePage()),
      GoRoute(
        path: RouteNames.forgotPinOtp,
        builder: (context, state) {
          final extra = state.extra;
          final phoneNumber = extra is String ? extra : '';
          return ForgotPinOtpPage(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: RouteNames.forgotPinResetPassword,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            final map = Map<String, dynamic>.from(extra);
            return ForgotPinResetPasswordPage(
              phoneNumber: (map['phoneNumber'] ?? '').toString(),
              otpCode: (map['otpCode'] ?? '').toString(),
            );
          }
          final phoneNumber = extra is String ? extra : '';
          return ForgotPinResetPasswordPage(phoneNumber: phoneNumber, otpCode: '');
        },
      ),
      GoRoute(
        path: RouteNames.transactionDetails,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! TransactionEntity) return const TransactionsPage();
          return TransactionDetailsPage(transaction: extra);
        },
      ),
      GoRoute(path: RouteNames.changePassword, builder: (context, state) => const ChangePasswordPage()),
      GoRoute(path: RouteNames.notifications, builder: (context, state) => const NotificationsPage()),
      GoRoute(path: RouteNames.appSettings, builder: (context, state) => const AppSettingsPage()),
      GoRoute(path: RouteNames.transfer, builder: (context, state) => const TransferPage()),
      GoRoute(path: RouteNames.transferConfirm, builder: (context, state) => const TransferConfirmPage()),
      GoRoute(path: RouteNames.transferResult, builder: (context, state) => const TransferResultPage()),
      GoRoute(path: RouteNames.exchange, builder: (context, state) => const ExchangePage()),
      GoRoute(path: RouteNames.exchangeConfirm, builder: (context, state) => const ExchangeConfirmPage()),
      GoRoute(path: RouteNames.exchangeResult, builder: (context, state) => const ExchangeResultPage()),
      GoRoute(path: RouteNames.billPaymentHub, builder: (context, state) => const BillPaymentHubPage()),
      GoRoute(path: RouteNames.mobileTopup, builder: (context, state) => const MobileTopupPage()),
      GoRoute(path: RouteNames.mobileTopupConfirm, builder: (context, state) => const MobileTopupConfirmPage()),
      GoRoute(path: RouteNames.mobileTopupResult, builder: (context, state) => const MobileTopupResultPage()),
      GoRoute(path: RouteNames.atmWithdraw, builder: (context, state) => const AtmWithdrawPage()),
      GoRoute(path: RouteNames.atmWithdrawConfirm, builder: (context, state) => const AtmWithdrawConfirmPage()),
      GoRoute(path: RouteNames.atmWithdrawResult, builder: (context, state) => const AtmWithdrawResultPage()),
      GoRoute(path: RouteNames.fraudReports, builder: (context, state) => const FraudReportsPage()),
      GoRoute(
        path: RouteNames.kycIntro,
        builder: (context, state) {
          final extra = state.extra;
          return KycIntroPage(phoneNumber: extra is String ? extra : null);
        },
      ),
      GoRoute(
        path: RouteNames.kycData,
        builder: (context, state) {
          final extra = state.extra;
          return KycDataPage(phoneNumber: extra is String ? extra : null);
        },
      ),
      GoRoute(
        path: RouteNames.kycCapture,
        builder: (context, state) {
          final extra = state.extra;
          return KycCapturePage(phoneNumber: extra is String ? extra : null);
        },
      ),
      GoRoute(
        path: RouteNames.kycReview,
        builder: (context, state) {
          final extra = state.extra;
          return KycReviewPage(phoneNumber: extra is String ? extra : null);
        },
      ),
      GoRoute(
        path: RouteNames.kycSubmitted,
        builder: (context, state) {
          final extra = state.extra;
          return KycSubmittedPage(phoneNumber: extra is String ? extra : null);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.dashboard, builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.transactions, builder: (context, state) => const TransactionsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: RouteNames.account, builder: (context, state) => const AccountPage()),
            ],
          ),
        ],
      ),
    ],
  );
});
