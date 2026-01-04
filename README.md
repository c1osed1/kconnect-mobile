# K-Connect Mobile

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

K-Connect - это социальная платформа для общения, обмена контентом и прослушивания музыки. Приложение разработано на Flutter для кроссплатформенной работы на iOS и Android.

## Функциональность

- **Аутентификация и аккаунты**: Регистрация, вход, управление несколькими аккаунтами
- **Лента новостей**: Просмотр постов, комментарии, лайки
- **Музыкальный плеер**: Прослушивание музыки, плейлисты, избранное
- **Мессенджер**: Чаты и сообщения в реальном времени
- **Профили пользователей**: Персонализация профилей, статистика, подписки
- **Персонализация**: Поддержка управления акцентным цветом приложения

## Требования

- Flutter SDK: ^3.9.2
- Dart: ^3.9.2
- Android Studio или Xcode для сборки

## Установка и запуск

1. Убедитесь, что Flutter установлен:
   ```bash
   flutter doctor
   ```

2. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/emokidnevermore/kconnect-mobile-test.git
   cd kconnect-mobile-test
   ```

3. Установите зависимости:
   ```bash
   flutter pub get
   ```

4. Запустите приложение:
   ```bash
   flutter run
   ```

## Сборка

### Android APK
```bash
flutter build apk --release
```

### iOS (требуется macOS с Xcode)
```bash
flutter build ios --release
```

## Архитектура

Приложение построено с использованием:

- **BLoC Pattern** для управления состоянием
- **Clean Architecture** с разделением на слои (presentation, domain, data)
- **Dependency Injection** через GetIt
- **HTTP клиент Dio** для API запросов
- **WebSocket** для real-time событий
- **SharedPreferences** для локального хранения

## Структура проекта

```
lib/
├── app.dart                    # Главный виджет приложения
├── bootstrap/                  # Инициализация приложения
├── core/                       # Общие компоненты и утилиты
├── features/                   # Функциональные модули
│   ├── auth/                   # Аутентификация
│   ├── feed/                   # Лента новостей
│   ├── music/                  # Музыкальный плеер
│   ├── messages/               # Мессенджер
│   ├── profile/                # Профили пользователей
│   └── ...
├── services/                   # Сервисы (API, WebSocket и т.д.)
├── theme/                      # Темы и стили
└── utils/                      # Утилиты
```

## API

Приложение взаимодействует с бэкенд API по адресу `https://k-connect.ru`.

## Лицензия

Этот проект распространяется под лицензией MIT. Подробности см. в файле [LICENSE](LICENSE).
