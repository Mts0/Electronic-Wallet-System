enum DataSourceMode {
  mock,
  remote,
}

class AppConfig {
  static const DataSourceMode dataSourceMode = DataSourceMode.remote;
  //10.0.2.2:8000
  /// Android emulator => http://10.0.2.2:8000
  /// Real device => replace with your backend LAN IP, e.g. http://192.168.1.10:8000
  static const String baseUrl = 'http://192.168.0.104:8000';

  static bool get useMock => dataSourceMode == DataSourceMode.mock;
  static bool get useRemote => dataSourceMode == DataSourceMode.remote;
}
