class PrivacyLists {
  String? activeList;
  String? defaultList;
  List<String>? allPrivacyLists = [];

  PrivacyLists({this.activeList, this.defaultList, this.allPrivacyLists});

  @override
  String toString() {
    return '{'
        'activeList: $activeList, '
        'defaultList: $defaultList, '
        'allPrivacyLists: ${allPrivacyLists?.toString()}'
        '}';
  }
}
