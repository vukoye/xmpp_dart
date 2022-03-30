abstract class XmppException {}

// class TimeoutException extends XmppException {}

class ResponseException extends XmppException {}

class FailWriteSocketException extends XmppException {}

class MessageStanzaException extends XmppException {}

class IqStanzaException extends XmppException {}

class InvalidJidMessageStanzaException extends MessageStanzaException {}

class InvalidJidIqStanzaException extends IqStanzaException {}

class SetFormConfigException extends XmppException {}
