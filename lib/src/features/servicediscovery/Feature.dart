import '../../elements/nonzas/Nonza.dart';

class Feature extends Nonza {
  Feature() : super('feature');

  String? get xmppVar {
    return getAttribute('var')?.value;
  }
}
