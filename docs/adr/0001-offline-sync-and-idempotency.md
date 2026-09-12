# ADR 0001: Offline Sync via Idempotent Submission + a Session State Machine

**Status:** Accepted.

## Context

A session is created and edited offline, then submitted. The submit must
survive a dropped connection, a double-tapped Submit/Retry, an app kill
mid-request, and the server's data having moved on since download. "Call the
API and set a `submitted` flag" fails all four.

## Decision

**1. One idempotency key per session, not per request.**
`count_sessions.idempotency_key` is generated once at session creation and
sent on every submit/retry. The backend keys its result cache on it, so a
replay returns the original response instead of creating a second server
session. Conflict responses are not cached — they write nothing server-side,
and caching one would trap the session in conflict forever.

**2. All status changes go through `CountSessionStateMachine.next()`.**
Pure, no I/O, throws on an illegal transition (e.g. `synced` → `syncStart`).
`SyncEngine` decides the transition, the repository just persists it — one
place holds the rules, and it unit-tests with zero mocking.

**3. Single-flight guard in the engine, not the UI.** `SyncEngine` holds a
`Set<String>` of in-flight session ids. Disabling a button only stops fast
double-taps; this also stops a reconnect-sync racing a manual retry.

**4. Crash recovery treats "still syncing" as safe to resend.** On startup,
sessions stuck in `syncing` reset to `pendingSync`. Safe precisely because of
decision 1 — even if the original request did reach the server.

## Consequences

- The assessment's named tests fall out directly: duplicate-submission
  prevention, version-conflict detection, state transitions.
- Every status write costs one indirection (engine → state machine →
  repository) — cheaper than re-deriving transition legality per call site.
- The guard is per-process; it does not cover the same account submitting
  from two devices. The server's own idempotency handling closes that — the
  client guard only avoids requests it already knows are redundant.

## Alternatives rejected

- **New key per retry** — not idempotent; a lost response still yields two
  sessions.
- **Backoff inside the engine** — deferred; currently retries on external
  triggers up to `kMaxSyncAttempts`. A real deployment wants backoff.
- **Conflict as a `Failure`** — a conflict is an expected response the UI
  must act on, so it is `SubmitConflict`, a sealed sibling of
  `SubmitAccepted`, not an error.
