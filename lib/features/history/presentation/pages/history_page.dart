/// History tab — P0 placeholder.
///
/// A **protected** path: `AppRoutes._protectedPaths` contains `/history`, so an
/// unauthenticated citizen is redirected to `/signin?from=%2Fhistory` before
/// this widget is ever built. The guard therefore lives in the router, not
/// here — a second in-page check would be dead code that could drift from the
/// real gate.
///
/// The real screen (`lcc-app/src/app/components/HistoryPage.tsx`: status
/// stats, filters, application list, detail view) is a later batch.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/shell/tab_placeholder.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPlaceholder(
      icon: Icons.history_outlined,
      title: 'history.title'.tr(),
      subtitle: 'history.subtitle'.tr(),
    );
  }
}
