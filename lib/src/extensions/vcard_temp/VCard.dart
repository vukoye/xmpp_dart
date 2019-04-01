import 'package:xmppstone/src/elements/XmppElement.dart';

class VCard extends XmppElement {
  String get fullName => getChild("FN").textValue;
  String get familyName => getChild("N")?.getChild("FAMILY")?.textValue;
  String get givenName => getChild("N")?.getChild("GIVEN")?.textValue;
  String get prefixName => getChild("N")?.getChild("PREFIX")?.textValue;

  String get nickName => getChild("NICKNAME").textValue;

  String get url => getChild("URL").textValue;

  String get bDay => getChild("BDAY").textValue;

  String get organisationName => getChild("ORG")?.getChild("ORGNAME")?.textValue;
  String get organizationUnit => getChild("ORG")?.getChild("ORGUNIT")?.textValue;

  String get title => getChild("TITLE").textValue;
  String get role => getChild("ROLE").textValue;

  String get jabberId => getChild("JABBERID").textValue;

  Map<PhoneType, String> get homePhones {

  }


  String get emailHome {
    var element =  children.firstWhere((element) => (element.name == "EMAIL" && element.getChild("HOME") != null), orElse: () => null);
    return element?.getChild("USERID")?.textValue;
  }

  String get emailWork {
    var element =  children.firstWhere((element) => (element.name == "EMAIL" && element.getChild("HOME") != null), orElse: () => null);
    return element?.getChild("USERID")?.textValue;
  }


}

enum PhoneType {
  VOICE, FAX, PAGER, MSG, CELL, VIDEO, BBS, MODEM, ISDN, PCS, PREF
}