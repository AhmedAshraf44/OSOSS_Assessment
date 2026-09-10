/// Table name constants shared between [AppDatabase] and the DAOs that
/// query it, so a typo shows up as a compile error instead of a silent
/// empty result set.
class DbTables {
  const DbTables._();

  static const products = 'products';
  static const countSessions = 'count_sessions';
  static const countItems = 'count_items';
  static const syncConflicts = 'sync_conflicts';
}
