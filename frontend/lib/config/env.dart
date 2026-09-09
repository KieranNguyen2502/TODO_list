class Env {
  // Override per environment, e.g.:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  //   flutter run --dart-define=API_BASE_URL=https://your-deployed-api.com
  // Defaults to the Android-emulator-to-host alias — see docs/environments.md
  // for the full local/emulator/physical-device/deployed matrix.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
