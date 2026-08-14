/// **The planted R-21 violation** — the three shapes a hard file rejection
/// takes, one per function.
///
/// Under `features/planted/presentation/`, i.e. exactly where F1's certificate
/// uploaders will live and exactly where v1.0's `lib/presentation/forms/`-scoped
/// grep could not have looked.
library;

String pickWithHardFilter() =>
    'FileType.custom with allowedExtensions: <String>[pdf]';

bool rejectsByMime(String type) => type == mimeType;

const String mimeType = 'application/pdf';

bool rejectsByExtension(String name) => name.endsWith('.pdf');
