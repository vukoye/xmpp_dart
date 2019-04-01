## XmppStone

Lightweight XMPP client library written completely in Dart.
My intention is to write simple to use library for future XMPP client based on Flutter.

This is actively developing library.
Currently supported:
 - RFC6120 - Extensible Messaging and Presence Protocol (XMPP): Core 
 - RFC6121 - Extensible Messaging and Presence Protocol (XMPP): Instant Messaging and Presence

Partly supported:
 - XEP-0030: Service Discovery

Actively working on: 
 - XEP-0054: vcard-temp
 - XEP-0153: vCard-Based Avatars
 - XEP-0085: Chat State Notifications

## Latest news

- 2019-04-01: adedd suport for SHA-1 and SHA-256 authentication alghoritms

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
