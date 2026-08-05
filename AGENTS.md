# AI Coding Agent Guidelines for Linkary

## Architecture Overview
Linkary is a Flutter modem management app using **Clean Architecture** with three layers:
- **Domain**: Entities, repositories (interfaces), use cases
- **Infrastructure**: Data sources, repository implementations, external services
- **Presentation**: Controllers (GetX), pages, widgets

**State Management**: GetX with reactive variables (`.obs`, `Rxn<T>` for nullable). Dependency injection via `Get.lazyPut()` in `lib/core/di/injection_container.dart`.

**Key Components**:
- 10 features in `lib/features/` (dashboard, modem_auth, data_usage, mac_filter, parental_control, settings, speed_limit, connected_devices, bill, voice_assistant)
- Shared core in `lib/core/` (currently underutilized - see technical debt)
- Modular structure with separate `modem_auth/` and `plans/` folders (legacy or planned)

## Critical Workflows
- **Build/Run**: Standard Flutter commands (`flutter run`, `flutter build apk`)
- **Theme Migration**: Run `python replace_theme.py` after UI changes to convert `Get.isDarkMode` to `Theme.of(context).brightness == Brightness.dark`
- **Analysis**: `flutter analyze` (avoids print statements in production)
- **Dependencies**: `flutter pub get` (remove unused like `dartz`)

## Project-Specific Patterns
- **Localization**: Arabic-first app (`locale: const Locale('ar')`), supports EN
- **Authentication**: Session-based via modem API, stored in `AuthController.currentUser?.sessionId`
- **API Communication**: HTTP client with base URL `'http://mobile.router'` (centralize in `core/utils/constants.dart`)
- **Error Handling**: `try/catch` with `throw Exception` (migrate to `Either<Failure, Success>` with `dartz`)
- **Session Management**: Violates Clean Architecture - access `Get.find<AuthController>().currentUser?.sessionId` in data sources (refactor to `SessionManager` in core)
- **Reactive State**: Use `.obs` for primitives, `Rxn<T>` for nullable objects, `RxList<T>` for lists
- **Controller Lifecycle**: Call `onClose()` to dispose timers/controllers (e.g., `dashboard_controller.dart`)
- **Imports**: Prefer `package:linkary/...` over relative paths for consistency
- **DI Registration**: Use `fenix: true` for controllers/usecases to persist across routes (inconsistent currently)

## Integration Points
- **Modem API**: RESTful endpoints at `http://mobile.router` for all features
- **Biometric Auth**: `local_auth` package for fingerprint/face unlock
- **Secure Storage**: `flutter_secure_storage` for sensitive data
- **Speech/Voice**: `speech_to_text` and `flutter_tts` for voice assistant
- **QR Code**: `qr_flutter` for generating/scanning codes
- **URL Launcher**: For opening external links
- **Crypto**: For hashing/passwords

## Key Files to Reference
- `lib/main.dart`: App initialization, theme setup, localization
- `lib/core/di/injection_container.dart`: All dependency registrations
- `lib/core/theme/app_theme.dart`: Light/dark theme definitions
- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart`: Example reactive controller with multiple data sources
- `docs/02_technical_debt.md`: Current issues and refactoring priorities
- `pubspec.yaml`: Dependencies and assets</content>
<parameter name="filePath">E:\Dev\AppsDev\Flutter Projects\linkary\AGENTS.md
