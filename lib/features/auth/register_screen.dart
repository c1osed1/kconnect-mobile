/// Экран регистрации нового пользователя
///
/// Предоставляет форму для создания нового аккаунта с валидацией полей.
/// Поддерживает автоматический вход после успешной регистрации и подтверждения email.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kconnect_mobile/theme/app_colors.dart';
import 'package:kconnect_mobile/theme/app_gradients.dart';
import 'package:kconnect_mobile/theme/app_text_styles.dart';
import 'package:kconnect_mobile/routes/route_names.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_event.dart';
import 'package:kconnect_mobile/features/auth/presentation/blocs/auth_state.dart';
import 'package:kconnect_mobile/core/utils/validators.dart';

/// Экран для регистрации нового пользователя в системе
///
/// Содержит форму с полями для ввода данных пользователя,
/// валидацию и обработку регистрации с последующим автоматическим входом.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String _savedEmail = '';
  String _savedPassword = '';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _doRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    //данные для автологина, убрать если появится рефреш токен
    _savedEmail = email;
    _savedPassword = password;

    context.read<AuthBloc>().add(RegisterEvent(username, email, password, name));
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('ОК'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Регистрация успешна!'),
        content: const Text(
          'Проверьте почту для подтверждения email (возможно письмо в спаме) и нажмите "Продолжить" для входа в систему.'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Продолжить'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.read<AuthBloc>().add(AutoLoginEvent(_savedEmail, _savedPassword));
            },
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
          Navigator.pushReplacementNamed(context, RouteNames.mainTabs);
        } else if (state is AuthRegistrationCompleted) {
          _showSuccessDialog();
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppGradients.primary.createShader(bounds),
                              child: const Text(
                                'Регистрация',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontFamily: 'Mplus',
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            _buildInputField(
                              controller: _usernameCtrl,
                              placeholder: 'Имя пользователя',
                              validator: Validators.validateUsername,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _emailCtrl,
                              placeholder: 'Email',
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _passwordCtrl,
                              placeholder: 'Пароль',
                              obscure: true,
                              validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _nameCtrl,
                              placeholder: 'Имя (необязательно)',
                              validator: Validators.validateName,
                            ),
                            const SizedBox(height: 32),
                            _buildRegisterButton(state),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, RouteNames.login),
                              child: Text(
                                'Уже есть аккаунт? Войти',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    String? Function(String?)? validator,
    bool obscure = false,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscure,
      style: AppTextStyles.bodyMedium,
      placeholderStyle: AppTextStyles.bodyMedium.copyWith(
        color: CupertinoColors.systemGrey,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildRegisterButton(AuthState state) {
    return state is AuthLoading
        ? const CupertinoActivityIndicator()
        : CupertinoButton.filled(
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            onPressed: _doRegister,
            child: Text('Создать аккаунт', style: AppTextStyles.button),
          );
  }
}
