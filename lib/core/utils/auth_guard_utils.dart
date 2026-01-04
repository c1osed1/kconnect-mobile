/// Утилиты для проверки аутентификации в экранах
///
/// Mixin для автоматической проверки наличия активной сессии
/// и перенаправления неавторизованных пользователей на экран входа.
library;

import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../routes/route_names.dart';

mixin AuthGuardMixin<T extends StatefulWidget> on State<T> {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _performAuthenticationCheck();
  }

  Future<void> _performAuthenticationCheck() async {
    try {
      final hasSession = await StorageService.hasActiveSession();
      if (hasSession) {
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
        onAuthenticated();
      } else {
        await _handleUnauthenticated();
      }
    } catch (e) {
      // Handle auth check error
      await _handleUnauthenticated();
    }
  }

  Future<void> _handleUnauthenticated() async {
    if (mounted) {
      Navigator.pushReplacementNamed(context, RouteNames.login);
    }
  }

  /// Вызывается когда проверка на вход успешна
  /// Переписывает субкласс для инициализации после аутентификации
  void onAuthenticated();

  /// Возвращает виджет загрузки во время аутентификации
  Widget buildAuthLoading() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
