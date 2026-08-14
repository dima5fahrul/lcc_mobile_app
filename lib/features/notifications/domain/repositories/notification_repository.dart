/// The notification inbox's repository contract — four calls, one bell.
///
/// | Source | Method | Endpoint | Envelope |
/// |---|---|---|---|
/// | `Layout.tsx:117` | [getNotifications] | `GET /me/notifications` | **paged** |
/// | `:114` | [getUnreadCount] | `GET /me/notifications/unread-count` | `{unread: int}` |
/// | `:134` | [markRead] | `POST /me/notifications/<id>/read` | bodyless |
/// | `:140` | [markAllRead] | `POST /me/notifications/read-all` | bodyless |
///
/// Three envelope shapes across four calls, and they are not interchangeable —
/// specs.md § 5 records that guessing the third is what produced the
/// shape-wrong `me-notifications-unread-count.json` fixture (§ 2.2 Finding H).
///
/// ## Tier 0 is NOT APPLICABLE to this feature, and that is a finding
///
/// Both POSTs go out with **no JSON body at all** (`endpoints.ts:138-139` call
/// `api.post(path)` with `body === undefined`, and `client.ts:240` only sets a
/// payload when `options.body !== undefined`). Payload equality over an empty
/// payload is vacuous, so B9a reports Tier 0 NOT APPLICABLE with that reason
/// rather than PASS (specs.md § 6.7, B9-AC-22). Recorded here so the ruling is
/// visible from the code it is about.
///
/// The `Content-Type` divergence § 6.8 describes — Flutter's `ApiClient._send`
/// sets `application/json` unconditionally, where the web sends no such header
/// on a bodyless POST — applies to both of these calls. `lib/core/network/**`
/// is behaviour-frozen, so it is recorded and **not** fixed here.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_entities.dart';

abstract class NotificationRepository {
  /// `GET /me/notifications?per_page=<n>` — **paged**, and the page block is
  /// deliberately discarded.
  ///
  /// `Layout.tsx:121` reads `inbox.data?.data ?? []` and nothing else: the bell
  /// menu has no pager, no infinite scroll and no total count, so `meta` has no
  /// consumer. Returning a `List` rather than a page object states that, where
  /// returning a page nobody reads would imply an affordance the menu does not
  /// have. The call still goes through `ApiClient.requestPaged`, because the
  /// **envelope** is paged whatever the caller wants from it.
  Future<Either<Failure, List<CitizenNotification>>> getNotifications({
    required int perPage,
  });

  /// `GET /me/notifications/unread-count` — the object `{"unread": <int>}`.
  ///
  /// `counter.data?.unread ?? 0` (`Layout.tsx:122`), so an absent or malformed
  /// value is 0 rather than an error.
  Future<Either<Failure, int>> getUnreadCount();

  /// `POST /me/notifications/<id>/read`, **no body**.
  ///
  /// Returns `Right(unit)` on success. The **caller ignores a failure on
  /// purpose** — `Layout.tsx:134` writes `.catch(() => undefined)`, so a failed
  /// mark-read neither blocks the navigation that has already happened nor
  /// surfaces anything to the citizen. The `Either` is still returned rather
  /// than swallowed here, so the decision to ignore it is made at the call site
  /// where it is visible and testable — the disposition `HelpRepository`
  /// already uses for `sendFaqFeedback`.
  Future<Either<Failure, Unit>> markRead(String id);

  /// `POST /me/notifications/read-all`, **no body**. `.catch(() => undefined)`
  /// at `Layout.tsx:140`, same disposition as [markRead].
  Future<Either<Failure, Unit>> markAllRead();
}
