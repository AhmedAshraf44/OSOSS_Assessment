import 'package:uuid/uuid.dart';

/// Generates client-side unique identifiers.
///
/// Used for both the local session id and the Idempotency-Key header. Both
/// are generated once, when a session is created, and reused on every retry
/// of that same session — that reuse is what makes retries safe (see
/// SyncEngine and the duplicate-submission-prevention test).
class IdGenerator {
  const IdGenerator();

  static const _uuid = Uuid();

  String generate() => _uuid.v4();
}
