/// The count session's single lifecycle status, matching the assessment's
/// suggested status list. Only [draft] is produced by Phase 2 (product
/// counting); the rest are driven by the sync engine and conflict flow.
enum CountSessionStatus {
  draft,
  readyToSubmit,
  pendingSync,
  syncing,
  conflict,
  synced,
  failed,
}
