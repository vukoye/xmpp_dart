## XmppStone

Lightweight XMPP client library written completely in Dart.
My intention is to write simple to use library for future XMPP client based on Flutter.

This is actively developing library.
Currently supported:
 - RFC6120 - Extensible Messaging and Presence Protocol (XMPP): Core (except for SCRAM SASL mechanisms for authentication)
 - RFC6121 - Extensible Messaging and Presence Protocol (XMPP): Instant Messaging and Presence

Currently actively working on:
 - XEP-0030: Service Discovery


## Usage

```dart
import 'package:xmppstone/xmppstone.dart' as xmpp;

main() {
  xmpp.Connection connection = new xmpp.Connection("user@domain", "password", 5222);
  connection.open();
}
```

## Features and bugs

Work in progress
