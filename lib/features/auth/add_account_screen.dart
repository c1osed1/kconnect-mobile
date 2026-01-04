/// Экран добавления нового аккаунта
///
/// Позволяет пользователю добавить дополнительный аккаунт в приложение.
/// Поддерживает вход с существующими учетными данными для добавления аккаунта.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/theme/app_gradients.dart';
import 'package:kconnect_mobile/theme/app_text_styles.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_event.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_state.dart';

/// Экран для добавления нового аккаунта в систему
///
/// Предоставляет интерфейс для ввода учетных данных и добавления
/// дополнительного аккаунта без выхода из текущего.
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
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

    context.read<AuthBloc>().add(LoginEvent(login, pass, isAddingAccount: true));
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
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          // Аккаунт успешно добавлен - перезагрузка UI произойдет автоматически через AuthBloc
        } else if (state is AuthError) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        return CupertinoPageScaffold(
          backgroundColor: AppColors.bgDark,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppColors.bgDark.withValues(alpha:0.8),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.back,
                color: CupertinoColors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            middle: Text(
              'Добавить аккаунт',
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
            ),
          ),
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
                          const SizedBox(height: 16),
                          Text(
                            'Добавьте новый аккаунт',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
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
                                  child: Text('Добавить аккаунт', style: AppTextStyles.button),
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
