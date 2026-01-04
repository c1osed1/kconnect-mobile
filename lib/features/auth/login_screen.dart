/// Экран входа в систему
///
/// Основной экран аутентификации для входа существующих пользователей.
/// Поддерживает вход по email или username с последующей навигацией к главному экрану.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/theme/app_gradients.dart';
import 'package:kconnect_mobile/theme/app_text_styles.dart';
import 'package:kconnect_mobile/routes/route_names.dart';
import 'package:kconnect_mobile/routes/app_router.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_event.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_state.dart';

/// Экран для входа пользователя в систему
///
/// Предоставляет форму для ввода учетных данных и осуществляет
/// переход к главному экрану приложения после успешной аутентификации.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _doLogin() {
    final login = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (login.isEmpty || pass.isEmpty) {
      _showError('Введите email/username и пароль');
      return;
    }

    context.read<AuthBloc>().add(LoginEvent(login, pass));
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Ошибка',
          style: AppTextStyles.body,
        ),
        content: Text(
          message,
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'ОК',
              style: AppTextStyles.button,
            ),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          AppRouter.navigatorKey.currentState?.pushReplacementNamed(RouteNames.mainTabs);
        } else if (state is AuthError) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        return CupertinoPageScaffold(
          backgroundColor: AppColors.bgDark,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppGradients.primary.createShader(bounds),
                            child: Text(
                              'K-Connect',
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 36,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          CupertinoTextField(
                            controller: _emailCtrl,
                            placeholder: 'Email или username',
                            style: AppTextStyles.bodyMedium,
                            placeholderStyle:
                                AppTextStyles.bodyMedium.copyWith(color: CupertinoColors.systemGrey),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: _passCtrl,
                            placeholder: 'Пароль',
                            obscureText: true,
                            style: AppTextStyles.bodyMedium,
                            placeholderStyle:
                                AppTextStyles.bodyMedium.copyWith(color: CupertinoColors.systemGrey),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(height: 32),
                          state is AuthLoading
                              ? const CupertinoActivityIndicator()
                              : CupertinoButton.filled(
                                  borderRadius: BorderRadius.circular(12),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                                  onPressed: _doLogin,
                                  child: Text('Войти', style: AppTextStyles.button),
                                ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, RouteNames.register),
                            child: Text(
                              'Нет аккаунта? Зарегистрируйся',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
