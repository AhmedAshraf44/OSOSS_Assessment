/// How the employee chose to resolve one conflicted product.
enum ConflictResolution {
  /// Keep the employee's physical count; resubmit it against the server's
  /// current version.
  keepMine,

  /// Discard the employee's count and adopt the server's current quantity
  /// instead.
  acceptServer,
}
