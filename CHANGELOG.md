## 0.3.3
- bug fixing

## 0.3.2
- bug fixing

## 0.3.1
- bug fixing

## 0.3.0
- Added Support for
 - __XEP-0280__: Message Carbons
 - __XEP-0313__: Message Archive Management
 - Added logging level mechanism
 - Optimisation and bug fixing

## 0.2.9
- bug fixing

## 0.2.8
- updating xml lib version

## 0.2.7
- bug fixing

## 0.2.6
- bug fixing

## 0.2.5
- bug fixing
## 0.2.4

- Added Support for
  - XEP-0318: Best Practices for Client Initiated Presence Probes

## 0.2.3

- Bug fixing

## 0.2.1

Introducing optional parameter for domain name in account settings

## 0.2.0

- Added support for
 - XEP-0198: Stream Management
 - XEP-0085: Chat State Notifications

## 0.1.5

- Openfire bug fixed (temporary fix)

## 0.1.4

- Fixing some bugs

## 0.1.3

- Initial published version

## 0.4.4-dev.5

- Update dependencies to the latest possible versions;

## 0.4.4-dev.4

- update dependencies to latest possible versions;

## 0.4.4-dev.3

- Revert `descendants` processing (fix some issues on the different Chat Servers);
- Fix `MessageArchiveManager` query date fields are not in `xep-0082` format (thanks [HaoCherHong](https://github.com/HaoCherHong/));
- Bug fix to xep-0030 support (thanks [HaoCherHong](https://github.com/HaoCherHong/));
- Fix auto-fixable lint warnings (thanks [tanukijs](https://github.com/tanukijs));

## 0.4.4-dev.2

- Fix establishing a connection with some XMPP servers;
- Fixed bug in roster result processing, thanks to [annarekonvald](https://github.com/annarekonvald) ([#77](https://github.com/vukoye/xmpp_dart/pull/77));
- Fix removing Connection by key, thanks to [seoyong-lim](https://github.com/seoyong-lim) ([#78](https://github.com/vukoye/xmpp_dart/pull/78));

## 0.4.4-dev.1

- Improvements for establishing a connection;
- Make WebSocket parameters configurable (see `XmppAccountSettings` for new parameters `wsPath` and `wsProtocols`).
- Update dependencies to the latest possible versions;