/// Service tab — P0 placeholder.
///
/// The real catalogue (`lcc-app/src/app/components/ServicePage.tsx`: category
/// filter, search, service grid) and the certificate sub-routes under
/// `/service/*` are the next batch. Copy comes from the already-ported
/// `service` namespace.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/shell/tab_placeholder.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPlaceholder(
      icon: Icons.grid_view_outlined,
      title: 'service.allServices'.tr(),
      subtitle: 'service.subtitle'.tr(),
    );
  }
}
