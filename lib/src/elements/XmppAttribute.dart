class XmppAttribute {
  String _name;
  String _value;

  String get name => _name;

  set name(String value) {
    _name = value;
  }

  String get value => _value;

  set value(String value) {
    _value = value;
  }

  XmppAttribute(String name, String value) {
    _name = name;
    _value = value;
  }
}
