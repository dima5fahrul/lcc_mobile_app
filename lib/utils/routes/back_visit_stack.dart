/// The visit model behind the app-level back policy (GOR-269).
///
/// This file is **pure Dart**. It imports nothing — not `package:flutter`, not
/// `go_router`, not the session — because the whole of GOR-269's back model is
/// answerable without any of them: *given where the citizen has been, what does
/// Back do?* Keeping it free of the framework is what lets
/// `test/utils/routes/back_visit_stack_test.dart` drive every invariant in
/// `fix-plan.md` § 9.2 with no `pumpWidget` at all, which is the primary
/// instrument `specs.md` § 7.7 names for Group D.
///
/// ## Why a visit stack and not "root is terminal"
///
/// `fix-plan.md` § 9.1 ruled `OQ-8`: **Back returns to the citizen's previous
/// location, and the app exits when and only when there is no previous
/// location.** The web source does exactly this — `navigateTo` assigns
/// `window.location.hash`, which *pushes*, and there is no `replaceState`
/// anywhere in `src/` — so the browser's back stack there is a plain visit
/// history that grows on every navigation, tab changes included.
///
/// The consequence worth stating out loud is that **the exit is derived, not
/// declared**. Nothing here knows that `/` is the start destination. `/` exits
/// because a fresh session has one entry and therefore no predecessor, and it
/// stops exiting the moment the citizen walks away from it and back
/// (`/` → `/wallet` → `/` → Back returns to `/wallet`). That is what makes
/// route 16 correct without anyone remembering to handle it —
/// `root-cause.md` § 9.2's forward test.
///
/// ## Locations, not routes
///
/// Entries are whole locations (`RouteMatchList.uri.toString()`), so
/// `/signin?from=%2Faccount` is a different entry from `/signin`. That is
/// deliberate: the query carries the post-sign-in intent, and a Back that
/// dropped it would land the citizen on a sign-in page that had forgotten where
/// they were going. It is also why [record] takes the **resolved** location and
/// never a requested one — see `I-1` on [record].
///
/// `security-review.md` § 2.2 measured what those strings can contain: the app
/// mounts exactly one parameterised route (`/news/:slug`, a public article
/// slug) and all eight protected paths are literal, parameter-free constants.
/// Nothing recorded here is sensitive on the current route table. That finding
/// is route-table-dependent rather than mechanism-dependent, so a future
/// parameterised protected route (a certificate keyed by case id, say) would
/// change it — and `SR-4` is why nothing in this file logs.
library;

/// A bounded, in-memory record of the locations the citizen has actually
/// landed on this session, newest last.
///
/// One instance lives for the life of the app, owned by `AppBackPolicy`. It is
/// **never persisted** (`I-7` / `FC-7`: `GOR-245` § 4.2 freezes the secure
/// storage key set at three, and a navigation journey has no business
/// outliving the session it belongs to).
class BackVisitStack {
  /// Creates an empty journey bounded at [bound] entries.
  BackVisitStack({this.bound = kDefaultBound})
      : assert(bound >= 2, 'a journey with no room for a predecessor is inert');

  /// The default depth bound.
  ///
  /// `I-4` sets a floor of 20 and leaves the value to the implementer. 20 is
  /// chosen rather than something larger because the bound's job is to stop
  /// Back degenerating into a two-hundred-press escape, and every extra entry
  /// past the point a citizen can remember is cost without benefit. The web is
  /// unbounded here; `root-cause.md` Ruling A′ is explicit that `L-10` does not
  /// reach a channel the source has no analogue for, so this is one place the
  /// port should not be faithful.
  static const int kDefaultBound = 20;

  /// Maximum entries retained. Oldest are evicted first.
  final int bound;

  final List<String> _entries = <String>[];

  /// The journey, oldest first. A defensive copy — callers may not mutate it.
  List<String> get entries => List<String>.unmodifiable(_entries);

  /// How deep the journey currently is.
  int get depth => _entries.length;

  /// Where the citizen is now, or null before the first location resolves.
  String? get current => _entries.isEmpty ? null : _entries.last;

  /// Where Back would take the citizen, or null when Back should exit the app.
  String? get predecessor =>
      _entries.length < 2 ? null : _entries[_entries.length - 2];

  /// Whether Back has somewhere to go. `false` is `I-8`'s exit condition.
  bool get hasPredecessor => _entries.length >= 2;

  /// Records a **forward** visit to [location].
  ///
  /// Three invariants live in these few lines:
  ///
  /// * **`I-1` — the resolved location, not the requested one.** This method
  ///   cannot enforce that on its own; it is the caller's contract, and
  ///   `AppBackPolicy` honours it by reading
  ///   `GoRouterDelegate.currentConfiguration` *after* go_router has resolved
  ///   the match, i.e. post-`redirect`. An unauthenticated `go('/wallet')`
  ///   therefore records `/signin?from=%2Fwallet` — the screen the citizen
  ///   actually saw — and never `/wallet`, which they did not.
  /// * **`I-2` — consecutive duplicates collapse.** A rebuild, a refresh or a
  ///   re-entry into the location already on top must not deepen the journey,
  ///   or Back becomes a no-op that looks like the defect it replaced.
  /// * **`I-4` — bounded, oldest-first.**
  ///
  /// **`I-3` — non-consecutive duplicates do NOT collapse**, and that is an
  /// absence rather than a line of code: nothing here searches the journey for
  /// an earlier occurrence. `/` → `/wallet` → `/` keeps three entries. Adding
  /// such a search would silently reverse `OQ-8` and turn `AC-25` red, which is
  /// precisely why the invariant is written down as a thing not to do.
  void record(String location) {
    if (_entries.isNotEmpty && _entries.last == location) return; // I-2
    _entries.add(location);
    while (_entries.length > bound) {
      _entries.removeAt(0); // I-4 — oldest first
    }
  }

  /// Reconciles the journey with a **backward** movement to [location].
  ///
  /// A backward movement is one the citizen did not initiate as a new visit:
  /// either a navigator pop the framework performed for us (`/news/:slug`
  /// dropping to `/news`), or the policy's own Back navigation. Both must make
  /// the journey **shrink or stand still — never grow**. Routing them through
  /// [record] instead is the bug this method exists to prevent: Back would land
  /// on `/news`, the arrival would be recorded as a fresh visit, and the next
  /// Back press would walk the citizen *forward* into the article they had just
  /// left. That oscillation is `I-5` in its real form.
  ///
  /// Only the back dispatcher can tell a backward movement from a forward one —
  /// "Back was pressed" is not visible from the router's configuration alone,
  /// because `go('/news')` from a chevron and a navigator pop to `/news`
  /// produce an identical match list. So the caller declares which it is; this
  /// method does not guess.
  ///
  /// Three cases, in order:
  ///
  /// 1. **Already reconciled** — the policy popped this entry itself and then
  ///    navigated to it, so the head is already [location]. `I-5`.
  /// 2. **The ordinary retreat** — [location] is the recorded predecessor, so
  ///    drop the head.
  /// 3. **Neither** — a redirect intervened, or the framework popped to
  ///    somewhere the journey never recorded. Replace the head rather than
  ///    append, because the citizen moved back even though the journey cannot
  ///    say from where. Growing here would be the oscillation again.
  void retreat(String location) {
    if (_entries.isEmpty) {
      _entries.add(location);
      return;
    }
    if (_entries.last == location) return; // 1
    if (_entries.length >= 2 && _entries[_entries.length - 2] == location) {
      _entries.removeLast(); // 2
      return;
    }
    _entries[_entries.length - 1] = location; // 3
  }

  /// Drops the current location and returns the predecessor it uncovers, or
  /// null when there is none.
  ///
  /// Null is `I-8`: an empty or single-entry journey means Back has nowhere to
  /// go and the framework must be allowed to exit the app. `fix-plan.md`
  /// § 13.4 trigger 1 — an app that cannot be exited is worse than the defect —
  /// is the reason this returns null rather than clamping to the first entry.
  String? stepBack() {
    if (_entries.length < 2) return null;
    _entries.removeLast();
    return _entries.last;
  }

  /// Empties the journey — `I-6`, when an authenticated session ends.
  ///
  /// *When* that is, is `AppBackPolicy._onSessionChanged`'s call and not this
  /// method's: keying it to the literal `authenticated → unauthenticated`
  /// transition missed the token-expiry path entirely (code review `M-1`), so
  /// the trigger is now a latch on the session rather than one edge in
  /// `SessionBloc`.
  ///
  /// Cleared to **empty** rather than reset to the current location, and the
  /// difference is deliberate. At the moment a sign-out lands, the router may
  /// or may not have finished redirecting away from the protected screen the
  /// citizen was on; re-seeding would therefore be a race whose losing side
  /// puts a stale protected location back on the journey — the exact thing
  /// `I-6` exists to remove. Empty is unconditionally safe: Back at `/signin`
  /// exits (`AC-28`), and the next navigation starts a fresh journey.
  ///
  /// The cost, stated rather than hidden: for one navigation after a sign-out
  /// the citizen has no predecessor to return to. That is a strict reduction of
  /// what Back does, never a bounce, and it is the correct default for a
  /// session that has ended.
  void clear() => _entries.clear();
}
