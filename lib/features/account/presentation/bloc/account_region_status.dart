/// One region's position in the four-state contract (`ssd.md` § 7.3).
///
/// The same four members `NotificationsState` and `HelpState` use, lifted to
/// its own file because **three** BLoCs on this page need it and each is in its
/// own library. `initial` is distinct from `loading` for the reason those two
/// record: "nothing has been asked for" and "we asked and are waiting" are
/// different screens.
library;

enum RegionStatus { initial, loading, success, failure }
