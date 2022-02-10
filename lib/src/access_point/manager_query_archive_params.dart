///
/// For quering archive params
///
/// Ex: shall wait for stanza or not
///

class ManagerQueryArchiveParams {
  DateTime? start;
  DateTime? end;
  String? beforeId;
  String? afterId;
  String? jid;
  bool includeGroup;
  String? id;

  ManagerQueryArchiveParams({
    this.start,
    this.end,
    this.beforeId,
    this.afterId,
    this.jid,
    this.includeGroup = false,
    this.id,
  });

  static ManagerQueryArchiveParams build({bool includeGroup = false}) {
    return ManagerQueryArchiveParams(includeGroup: includeGroup);
  }
}
