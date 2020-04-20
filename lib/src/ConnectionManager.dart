class ConnectionManager {
  static ConnectionManager _instance;

  static ConnectionManager getInstance() {
    if (_instance == null) {
      _instance = ConnectionManager();
    }
    return _instance;
  }
}
