void noFunc() {}
class XmppCommunicationCallback {
  Function onReady;
  Function onPing;
  Function onPresence;
  Function onPresenceSubscription;
  Function onMessage;
  Function onConnectionStatus;

  XmppCommunicationCallback(
      {this.onReady = noFunc,
      this.onPing = noFunc,
      this.onPresence = noFunc,
      this.onPresenceSubscription = noFunc,
      this.onMessage = noFunc,
      this.onConnectionStatus = noFunc});
}