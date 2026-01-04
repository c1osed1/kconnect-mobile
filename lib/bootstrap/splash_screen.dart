import 'package:flutter/cupertino.dart';
import 'package:kconnect_mobile/services/storage_service.dart';
import '../routes/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Экран загрузки приложения
///
/// Отображает логотип и индикатор загрузки во время проверки сессии пользователя.
/// Перенаправляет на главный экран или экран входа в зависимости от наличия активной сессии.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'K-Connect загружается...';

  @override
  void initState() {
    super.initState();
    setState(() => _status = 'initState called');
    _checkSession();
  }

  /// Проверяет наличие активной сессии и перенаправляет пользователя
  Future<void> _checkSession() async {
    setState(() => _status = '_checkSession started');
    final hasSession = await StorageService.hasActiveSession().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    setState(() => _status = 'after storage: $hasSession');

    if (!mounted) return;

    if (hasSession) {
      Navigator.pushReplacementNamed(context, RouteNames.mainTabs);
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'lib/assets/icons/logo.svg',
              width: 96,
              height: 96,
            ),
            const SizedBox(height: 24),
            const CupertinoActivityIndicator(radius: 16),
            const SizedBox(height: 24),
            Text(
              _status,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
