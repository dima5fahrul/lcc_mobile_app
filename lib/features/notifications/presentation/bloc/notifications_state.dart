part of 'notifications_bloc.dart';

/// One region's position in the four-state contract (SSD § 7.3). Same four
/// members as `HelpState`'s, and `initial` is distinct from `loading` for the
/// same reason: "nothing has been asked for" and "we asked and are waiting"
/// are different screens.
enum RegionStatus { initial, loading, success, failure }

@freezed
abstract class NotificationsState with _$NotificationsState {
  const factory NotificationsState({
    /// The `isAuthenticated` prop — `Layout.tsx:98`. It gates both queries and
    /// it is what makes the signed-out bell show its dot (`:172`).
    @Default(false) bool isAuthenticated,

    /// `const [open, setOpen] = useState(false)` — `Layout.tsx:106`.
    @Default(false) bool open,

    /// `counter.data?.unread ?? 0` — `Layout.tsx:122`.
    ///
    /// The count has **no loading and no error surface**: the source reads only
    /// `.data`, so a pending or failed count renders as the last number it saw
    /// (0 before the first). That is why there is no `countStatus` here — a
    /// status nothing can render would be state the tests could assert and the
    /// citizen could never see.
    @Default(0) int unreadCount,

    /// `inbox.data?.data ?? []` — `Layout.tsx:121`.
    @Default(<CitizenNotification>[]) List<CitizenNotification> items,

    @Default(RegionStatus.initial) RegionStatus listStatus,

    /// `hasData` — `hooks.ts:56`. True once a list request has **succeeded**,
    /// and never false again.
    ///
    /// It is not the same question as `items.isNotEmpty`: a successful fetch
    /// that returns zero rows still counts, and it is what stops the second
    /// open from flashing the spinner over rows the citizen can already see.
    @Default(false) bool listLoaded,

    /// `refreshing` — `hooks.ts:67`. A refetch **with** data in hand. Nothing in
    /// the source renders it (the menu reads only `loading` and `error`), so it
    /// is carried to keep the two spinner cases distinguishable in a test
    /// rather than to draw anything.
    @Default(false) bool listRefreshing,
  }) = _NotificationsState;

  const NotificationsState._();

  // ── The bell ───────────────────────────────────────────────────────────────

  /// `(!isAuthenticated || unreadCount > 0)` — `Layout.tsx:172`.
  ///
  /// **The signed-out bell shows the dot.** That reads like a defect and is
  /// not: it is confirmed against the frozen baseline in `en/02-service.png`,
  /// `en/04-wallet.png` and `en/06-help.png`, all of which are signed-out
  /// captures with an amber dot top-right. A port that hid it would fail Tier 3
  /// against a reference that already exists.
  bool get showsDot => !isAuthenticated || unreadCount > 0;

  // ── The menu header ────────────────────────────────────────────────────────

  /// `isAuthenticated && unreadCount > 0` — `Layout.tsx:189`. Gates **both**
  /// the "Mark all as read" button and the count pill; they are one branch in
  /// the source, not two.
  ///
  /// Note the asymmetry with [showsDot], which is `||` where this is `&&`. Two
  /// idioms for one number in one shell, and specs.md § 2.2 Finding B rules
  /// that they must not be unified.
  bool get showsMarkAllRead => isAuthenticated && unreadCount > 0;

  // ── The menu body: the four states, in the order `Layout.tsx:225-282`
  // evaluates them ───────────────────────────────────────────────────────────

  /// `!isAuthenticated` — `:208`. Checked **before** loading, so a signed-out
  /// citizen never sees a spinner for a request that was never enabled.
  bool get showsSignInPrompt => !isAuthenticated;

  /// `inbox.loading` — `:225`. `initial` counts, so the frame between the tap
  /// and the handler running shows the spinner and not "You're all caught up".
  bool get listLoading =>
      listStatus == RegionStatus.loading || listStatus == RegionStatus.initial;

  /// `inbox.error` — `:229`. Wins over stale rows: the source checks it before
  /// `items.length === 0` and before rendering the list.
  bool get listFailed => listStatus == RegionStatus.failure;

  /// `items.length === 0` — `:241`, reached only after loading and error.
  bool get listEmpty =>
      listStatus == RegionStatus.success && items.isEmpty;

  // ── Folding ────────────────────────────────────────────────────────────────

  /// Folds an inbox response in.
  ///
  /// A failure sets the error status and **keeps the rows**, because
  /// `useQuery` calls `setError` without touching `data` (`hooks.ts:74-79`).
  /// Nothing renders them in that state today — the error branch wins — but
  /// discarding them here would be this port inventing a behaviour, and it
  /// would change what a subsequent successful retry has to redraw.
  NotificationsState withList(
    Either<Failure, List<CitizenNotification>> response,
  ) =>
      response.fold(
        (Failure _) => copyWith(
          listStatus: RegionStatus.failure,
          listRefreshing: false,
        ),
        (List<CitizenNotification> rows) => copyWith(
          listStatus: RegionStatus.success,
          listLoaded: true,
          listRefreshing: false,
          items: rows,
        ),
      );
}
