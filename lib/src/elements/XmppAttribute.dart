class XmppAttribute {
  String _name;
  String _value;

  get name => _name;

  set name(String value) {
    _name = value;
  }

  get value => _value;

  set value(String value) {
    _value = value;
  }

  XmppAttribute(String name, String value) {
    _name = name;
    _value = value;
  }
}
