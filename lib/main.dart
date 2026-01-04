import 'package:flutter/cupertino.dart';
import 'package:kconnect_mobile/app.dart';
import 'package:kconnect_mobile/injection.dart' show setupLocator;
import 'bootstrap/bootstrap.dart';

/// Точка входа в приложение K-Connect Mobile
///
/// Инициализирует зависимости, сервисы и запускает приложение.
/// Обеспечивает корректную последовательность инициализации компонентов.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация DI контейнера
  setupLocator();

  // Инициализация сервисов до запуска
  await AppBootstrap.init();

  runApp(const KConnectApp());
}
