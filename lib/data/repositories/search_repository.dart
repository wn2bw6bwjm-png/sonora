import 'package:drift/drift.dart';
import '../db/app_database.dart';

class SearchRepository {
  SearchRepository(this._db);
  final AppDatabase _db;

  Stream<List<String>> watchHistory() => (_db.select(_db.searchHistory)
        ..orderBy([(t) => OrderingTerm.desc(t.usedAt)])
        ..limit(10))
      .watch()
      .map((l) => l.map((e) => e.term).toList());

  Future<void> add(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    await _db.into(_db.searchHistory).insertOnConflictUpdate(
        SearchHistoryCompanion.insert(term: t, usedAt: DateTime.now()));
  }

  Future<void> clear() => _db.delete(_db.searchHistory).go();
}
