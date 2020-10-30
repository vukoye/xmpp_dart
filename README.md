## XmppStone

Lightweight XMPP client library written completely in Dart.
My intention is to write simple to use library for future XMPP client based on Flutter.

__Supported documents:__
 - __RFC6120__: Extensible Messaging and Presence Protocol (XMPP): Core 
 - __RFC6121__: Extensible Messaging and Presence Protocol (XMPP): Instant Messaging and Presence
 - __XEP-0198__: Stream Management
 - __XEP-0085__: Chat State Notifications
 - __XEP-0318__: Best Practices for Client Initiated Presence Probes
 - __XEP-0280__: Message Carbons

__Partly supported:__
  - __XEP-0030__: Service Discovery
  - __XEP-0313__: Message Archive Management

__Actively working on:__ 
  - __XEP-0059__: Result Set Management
  - __XEP-0004__: Data Forms

## Latest news

 - 2020-10-30: Added support for XEP-0280: Message Carbons
 - 2020-10-30: Added initial support for XEP-0313: Message Archive Management
 - 2020-10-30: Added logging mechanism
 - 2020-07-23: Added support for XEP-0318: Best Practices for Client Initiated Presence Probes
 - 2020-05-02: Added initial support for XEP-0198 : Stream Management
 - 2020-05-02: Added initial support for XEP-0085 : Chat State Notifications
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
## Features

#### 1. Logging


###### Log level

Client can set logging level of the library with command:
```dart
Log.logLevel = LogLevel.VERBOSE;
```

###### XMPP traffic logging

Xmpp traffic can be enabled or disabled with:
```dart
Log.logXmpp = false
```

#### 2. Message Archive Management
*Feature is work in progress, API is subject to change.*

Initial implementation of Message Archive Management.

RST is not yet implemented.

Usage:

- Grabbing the module
```dart
connection.getMamModule()
```

- Querying all messages:

```dart
mamManager.queryAll();
```

- Querying messages based on date (All parameters are optional):

```dart
mamManager.queryByTime(start: startTime, end: endTime, jid: buddyJid);
```

- Querying messages based on messageId (All parameters are optional):
This method requires *urn:xmpp:mam:2#extended* to be supported by the serve, soon it will be available to check feature support.

```dart
mamManager.queryById(beforeId: beforeId, afterId: afterId, jid: buddyJid});
```

Checking capabilities of the server:
```dart
mamManager.isQueryByDateSupported
mamManager.isQueryByIdSupported
mamManager.isQueryByJidSupported
```