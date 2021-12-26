///
/// Settings configuration for sending request and receiving response
///
/// Ex: shall wait for stanza or not
///

class XmppCommunicationConfig {
  final bool shallWaitStanza;

  const XmppCommunicationConfig({
    required this.shallWaitStanza,
  });

  static XmppCommunicationConfig build({bool shallWaitStanza = false}) {
    return XmppCommunicationConfig(shallWaitStanza: shallWaitStanza);
  }
}
