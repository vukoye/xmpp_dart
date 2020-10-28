import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:xmpp_stone/src/elements/XmppAttribute.dart';
import 'package:xmpp_stone/src/elements/XmppElement.dart';

class VCard extends XmppElement {
  var _imageData;

  img.Image _image;

  VCard(XmppElement element) {
    if (element != null) {
      element.children.forEach((child) => addChild(child));
    }
    name = 'vCard';
    addAttribute(XmppAttribute('xmlns', 'vcard-temp'));
    _parseImage();
  }

  String get fullName => getChild('FN')?.textValue;

  String get familyName => getChild('N')?.getChild('FAMILY')?.textValue;

  String get givenName => getChild('N')?.getChild('GIVEN')?.textValue;

  String get prefixName => getChild('N')?.getChild('PREFIX')?.textValue;

  String get nickName => getChild('NICKNAME')?.textValue;

  String get url => getChild('URL')?.textValue;

  String get bDay => getChild('BDAY')?.textValue;

  String get organisationName =>
      getChild('ORG')?.getChild('ORGNAME')?.textValue;

  String get organizationUnit =>
      getChild('ORG')?.getChild('ORGUNIT')?.textValue;

  String get title => getChild('TITLE')?.textValue;

  String get role => getChild('ROLE')?.textValue;

  String get jabberId => getChild('JABBERID')?.textValue;

  String getItem(String itemName) => getChild(itemName)?.textValue;

  dynamic get imageData => _imageData;

  img.Image get image => _image;

  String get imageType => getChild('PHOTO')?.getChild('TYPE')?.textValue;

  List<PhoneItem> get phones {
    var homePhones = <PhoneItem>[];
    children
        .where((element) =>
            (element.name == 'TEL' && element.getChild('HOME') != null))
        .forEach((element) {
      var typeString = element.children.firstWhere(
          (element) => (element.name != 'HOME' && element.name != 'NUMBER'),
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

  String get emailHome {
    var element = children.firstWhere(
        (element) =>
            (element.name == 'EMAIL' && element.getChild('HOME') != null),
        orElse: () => null);
    return element?.getChild('USERID')?.textValue;
  }

  String get emailWork {
    var element = children.firstWhere(
        (element) =>
            (element.name == 'EMAIL' && element.getChild('WORK') != null),
        orElse: () => null);
    return element?.getChild('USERID')?.textValue;
  }

  static PhoneType getPhoneTypeFromString(String phoneTypeString) {
    switch (phoneTypeString) {
      case 'VOICE':
        return PhoneType.VOICE;
        break;
      case 'FAX':
        return PhoneType.FAX;
        break;
      case 'PAGER':
        return PhoneType.PAGER;
        break;
      case 'MSG':
        return PhoneType.MSG;
        break;
      case 'CELL':
        return PhoneType.CELL;
        break;
      case 'VIDEO':
        return PhoneType.VIDEO;
        break;
      case 'BBS':
        return PhoneType.BBS;
        break;
      case 'MODEM':
        return PhoneType.MODEM;
        break;
      case 'ISDN':
        return PhoneType.ISDN;
        break;
      case 'PCS':
        return PhoneType.PCS;
        break;
      case 'PREF':
        return PhoneType.PREF;
        break;
    }
    return PhoneType.OTHER;
  }

  void _parseImage() {
    var base64Image = getChild('PHOTO')?.getChild('BINVAL')?.textValue;
    if (base64Image != null) {
      _imageData = base64.decode(base64Image);
      _image = img.decodeImage(_imageData);
    }
  }
}

class InvalidVCard extends VCard {
  InvalidVCard(XmppElement element) : super(element);
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
