class ConnectionManager {
  static ConnectionManager _instance;

  static ConnectionManager getInstance() {
    _instance ??= ConnectionManager();
    return _instance;
  }
}
