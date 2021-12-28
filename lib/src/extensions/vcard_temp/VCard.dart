import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

enum TelephonePremiseType { WORK, HOME }
enum TelephoneVoiceType { VOICE, FAX, MSG }

class VCardTelephone {
  TelephonePremiseType? premiseType;
  TelephoneVoiceType? voiceType;
  String? number;
}

class VCard extends XmppElement {
  var _imageData;
  String? fullName;
  String? familyName;
  String? givenName;
  String? prefixName;
  String? nickName;
  String? url;
  String? bDay;
  String? organisationName;
  String? organisationUnit;
  String? title;
  String? role;
  String? jabberId;

  img.Image? _image;

  VCard(XmppElement? element) {
    if (element != null) {
      element.children.forEach((child) => addChild(child));
    }
    name = 'vCard';
    addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    _parseImage();
    _parseAttributes();
  }

  // TODO - START: getItem, imageData, image and phones, etc.. are not mapped yet.

  String? getItem(String itemName) => getChild(itemName)?.textValue;

  dynamic get imageData => _imageData;

  img.Image? get image => _image;

  String? get imageType => getChild('PHOTO')?.getChild('TYPE')?.textValue;

  List<PhoneItem> get phones {
    var homePhones = <PhoneItem>[];
    children
        .where((element) =>
            (element!.name == 'TEL' && element.getChild('HOME') != null))
        .forEach((element) {
      var typeString = element!.children.firstWhere(
          (element) => (element!.name != 'HOME' && element.name != 'NUMBER'),
          orElse: () => null);
      if (typeString != null) {
        var type = getPhoneTypeFromString(typeString.name);
        var number = element.getChild('NUMBER')?.textValue;
        if (number != null) {
          homePhones.add(PhoneItem(type, number));
        }
      }
    });
    return homePhones;
  }

  String? get emailHome {
    var element = children.firstWhere(
        (element) =>
            (element!.name == 'EMAIL' && element.getChild('HOME') != null),
        orElse: () => null);
    return element?.getChild('USERID')?.textValue;
  }

  String? get emailWork {
    var element = children.firstWhere(
        (element) =>
            (element!.name == 'EMAIL' && element.getChild('WORK') != null),
        orElse: () => null);
    return element?.getChild('USERID')?.textValue;
  }

  static PhoneType getPhoneTypeFromString(String? phoneTypeString) {
    switch (phoneTypeString) {
      case 'VOICE':
        return PhoneType.VOICE;
      case 'FAX':
        return PhoneType.FAX;
      case 'PAGER':
        return PhoneType.PAGER;
      case 'MSG':
        return PhoneType.MSG;
      case 'CELL':
        return PhoneType.CELL;
      case 'VIDEO':
        return PhoneType.VIDEO;
      case 'BBS':
        return PhoneType.BBS;
      case 'MODEM':
        return PhoneType.MODEM;
      case 'ISDN':
        return PhoneType.ISDN;
      case 'PCS':
        return PhoneType.PCS;
      case 'PREF':
        return PhoneType.PREF;
    }
    return PhoneType.OTHER;
  }

  // TODO - END: getItem, imageData, image and phones, etc.. are not mapped yet.

  void _parseImage() {
    var base64Image = getChild('PHOTO')?.getChild('BINVAL')?.textValue;
    if (base64Image != null) {
      _imageData = base64.decode(base64Image);
      _image = img.decodeImage(_imageData);
    }
  }

  void _parseAttributes() {
    fullName = getChild('FN')?.textValue;
    familyName = getChild('N')?.getChild('FAMILY')?.textValue;
    givenName = getChild('N')?.getChild('GIVEN')?.textValue;
    prefixName = getChild('N')?.getChild('PREFIX')?.textValue;
    nickName = getChild('NICKNAME')?.textValue;
    url = getChild('URL')?.textValue;
    bDay = getChild('BDAY')?.textValue;
    organisationName = getChild('ORG')?.getChild('ORGNAME')?.textValue;
    organisationUnit = getChild('ORG')?.getChild('ORGUNIT')?.textValue;
    title = getChild('TITLE')?.textValue;
    role = getChild('ROLE')?.textValue;
    jabberId = getChild('JABBERID')?.textValue;
  }

  XmppElement buildXMLWithAttributes() {
    var vCardElement = XmppElement();
    vCardElement.name = 'vCard';
    vCardElement.addAttribute(XmppAttribute('xmlns', 'vcard-temp'));

    var attrFN = XmppElement();
    attrFN.name = 'FN';
    attrFN.textValue = fullName;
    vCardElement.addChild(attrFN);

    var attrNickname = XmppElement();
    attrNickname.name = 'NICKNAME';
    attrNickname.textValue = nickName;
    vCardElement.addChild(attrNickname);

    var attrBDay = XmppElement();
    attrBDay.name = 'BDAY';
    attrBDay.textValue = fullName;
    vCardElement.addChild(attrBDay);
    return vCardElement;
  }
}

class InvalidVCard extends VCard {
  InvalidVCard(XmppElement? element) : super(element);
}

class UpdateAckVCard extends VCard {
  UpdateAckVCard(XmppElement element) : super(element);
}

class PhoneItem {
  PhoneType type;
  String phone;

  PhoneItem(this.type, this.phone);
}

enum PhoneType {
  VOICE,
  FAX,
  PAGER,
  MSG,
  CELL,
  VIDEO,
  BBS,
  MODEM,
  ISDN,
  PCS,
  PREF,
  OTHER
}
