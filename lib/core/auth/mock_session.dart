/// Stand-in for real authentication — the assessment explicitly allows
/// mocking auth. A production build would source the employee id from the
/// signed-in user's token claims instead of a constant.
class MockSession {
  const MockSession._();

  static const employeeId = 'employee-001';
}
