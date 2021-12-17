import 'dart:async';

import 'package:tuple/tuple.dart';

import '../../Connection.dart';
import '../../data/privacy_list.dart';
import '../../data/privacy_list_item.dart';
import '../../data/privacy_lists.dart';
import '../../elements/XmppElement.dart';
import '../../elements/forms/QueryElement.dart';
import '../../elements/privacy_lists/active_element.dart';
import '../../elements/privacy_lists/default_element.dart';
import '../../elements/privacy_lists/list_element.dart';
import '../../elements/privacy_lists/privacy_list_item_element.dart';
import '../../elements/stanzas/AbstractStanza.dart';
import '../../elements/stanzas/IqStanza.dart';
import '../../features/servicediscovery/ServiceDiscoveryNegotiator.dart';

const feature_not_supported_error =
    'The "Privacy Lists" feature not supported by your server';

class PrivacyListsManager {
  final Connection _connection;
  final Map<String, Tuple2<Function(IqStanza), Completer?>>
      _unrespondedStanzas = {};

  final StreamController<String> _listsUpdatesController =
      StreamController.broadcast();

  Stream<String> get listsChangesStream => _listsUpdatesController.stream;

  static final Map<Connection, PrivacyListsManager> _instances = {};

  PrivacyListsManager(this._connection) {
    _connection.inStanzasStream.listen(_processStanza);
  }

  static PrivacyListsManager getInstance(Connection connection) {
    var manager = _instances[connection];
    if (manager == null) {
      manager = PrivacyListsManager(connection);
      _instances[connection] = manager;
    }
    return manager;
  }

  void _processStanza(AbstractStanza? stanza) {
    if (stanza == null) return;

    if (stanza is IqStanza) {
      var unrespondedStanza = _unrespondedStanzas[stanza.id];
      if (unrespondedStanza != null) {
        if (stanza.type == IqStanzaType.ERROR) {
          var errorElement = stanza.getChild('error');
          var errorType = errorElement?.attributes
              .firstWhere((xmppAttribute) => xmppAttribute.name == 'type')
              .value;
          var errorDescription = errorElement?.children.first.name;
          unrespondedStanza.item2
              ?.completeError(Exception('$errorType: $errorDescription'));
        } else {
          unrespondedStanza.item2
              ?.complete(unrespondedStanza.item1.call(stanza));
        }

        _unrespondedStanzas.remove(stanza.id);
      } else {
        //TODO unchecked part cause test server doesn't support this part, check and fix if need on alive server
        if (stanza.type == IqStanzaType.SET && stanza.id != null) {
          if (stanza.getChild('query') != null) {
            var queryElement = stanza.getChild('query');
            var listElement = queryElement?.getChild('list');
            if ('jabber:iq:privacy' ==
                    queryElement?.getAttribute('xmlns')?.value &&
                listElement != null) {
              var listName = listElement.getAttribute('name')?.value;
              if (listName != null && listName.isNotEmpty) {
                _onPrivacyListChanged(listName);
                _sendResultToServer(stanza.id!);
              }
            }
          }
        }
      }
    }
  }

  bool isPrivacyListsSupported() {
    return ServiceDiscoveryNegotiator.getInstance(_connection)
        .isFeatureSupported('jabber:iq:privacy');
  }

  Future<PrivacyLists> getAllLists() {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<PrivacyLists>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      var result = PrivacyLists()..allPrivacyLists = [];

      var queryElement = resultStanza.getChild('query');
      queryElement?.children.forEach((listElement) {
        if (listElement.name == 'active') {
          result.activeList = listElement.getAttribute('name')?.value;
        } else if (listElement.name == 'default') {
          result.defaultList = listElement.getAttribute('name')?.value;
        } else if (listElement.name == 'list') {
          result.allPrivacyLists!
              .add(listElement.getAttribute('name')?.value ?? 'unknown');
        }
      });

      return result;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<List<PrivacyListItem>> getListByName(String name) {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<List<PrivacyListItem>>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.GET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    queryStanza.addChild(ListElement(name));
    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      var result = <PrivacyListItem>[];

      var queryElement = resultStanza.getChild('query');
      queryElement?.children.first.children.forEach((listElement) {
        result.add(PrivacyListItemElement.fromXml(listElement).item);
      });

      return result;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<void> setActiveList(String name) {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<void>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    queryStanza.addChild(ActiveElement(name));
    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      return;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<void> declineActiveList() {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<void>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    queryStanza.addChild(XmppElement()..name = 'active');
    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      return;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<void> setDefaultList(String name) {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<void>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    queryStanza.addChild(DefaultElement(name));
    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      return;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<void> declineDefaultList() {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<void>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    queryStanza.addChild(XmppElement()..name = 'default');
    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      return;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<void> createPrivacyList(PrivacyList privacyList) {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<void>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    var listStanza = ListElement(privacyList.name);

    if (privacyList.items != null && privacyList.items!.isNotEmpty) {
      privacyList.items?.forEach((privacyListItem) {
        listStanza.addItem(PrivacyListItemElement(item: privacyListItem));
      });
    }

    queryStanza.addChild(listStanza);
    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      return;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  Future<void> removePrivacyList(String name) {
    if (!isPrivacyListsSupported()) {
      return Future.error(Exception(feature_not_supported_error));
    }

    var completer = Completer<void>();

    var iqStanza = IqStanza(AbstractStanza.getRandomId(), IqStanzaType.SET)
      ..fromJid = _connection.fullJid;

    var queryStanza = QueryElement();
    queryStanza.setXmlns('jabber:iq:privacy');
    queryStanza.addChild(ListElement(name));

    iqStanza.addChild(queryStanza);

    _unrespondedStanzas[iqStanza.id!] = Tuple2((resultStanza) {
      return;
    }, completer);

    _connection.writeStanza(iqStanza);

    return completer.future;
  }

  void _onPrivacyListChanged(String listName) {
    _listsUpdatesController.add(listName);
  }

  void _sendResultToServer(String id) {
    var resultStanza = IqStanza(id, IqStanzaType.RESULT)
      ..fromJid = _connection.fullJid;

    _connection.writeStanza(resultStanza);
  }
}
