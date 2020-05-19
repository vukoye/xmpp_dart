## XmppStone

Lightweight XMPP client library written completely in Dart.
My intention is to write simple to use library for future XMPP client based on Flutter.

This is actively developing library.
Currently supported:
 - RFC6120 - Extensible Messaging and Presence Protocol (XMPP): Core 
 - RFC6121 - Extensible Messaging and Presence Protocol (XMPP): Instant Messaging and Presence
 - XEP-0198 : Stream Management
 - XEP-0085: Chat State Notifications
Partly supported:
 - XEP-0030: Service Discovery

Actively working on: 


## Latest news


- 2020-05-02: Added Initial Support for XEP-0198 : Stream Management

- 2020-05-02: Added Initial Support for XEP-0085 : Chat State Notifications

- 2019-04-02: added support for: XEP-0054: vcard-temp

- 2019-04-01: added support for SHA-1 and SHA-256 authentication algorithm

## Usage

```dart
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

main() {
  xmpp.Connection connection = new xmpp.Connection("user@domain", "password", 5222);
  connection.open();
}
```

## Features and bugs

Work in progress
