/// Cloud API base URL. Overridable at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
/// See README.md "Configuration" for the full explanation (why this isn't
/// a `.env` file, and the right value per emulator/device target).
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
}
