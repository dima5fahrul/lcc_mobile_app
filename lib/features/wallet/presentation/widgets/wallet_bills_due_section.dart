/// Bills due — **B6a ships the empty branch only.**
///
/// `WalletPage.tsx:264-382` has four branches: skeleton, error, empty, and the
/// populated card grid. The first, second and fourth all read `billsQuery`,
/// which is `GET /applications/?page=1&per_page=50` (`:104-108`) — B7a's
/// endpoint, B6b's consumer. specs.md § 2.3 puts the seam here, and `B6-AC-45`
/// proves it held: `grep -rn "application" lib/features/wallet -i` must return
/// only the documented `TODO(B6b)` stub, and `grep -rn "/applications"` must
/// return zero.
///
/// So this widget renders `:312-325` — the empty card — unconditionally, from
/// [kBillsDueB6b], the **named** constant `B6-AC-45` requires instead of an
/// inline `[]`. The distinction is not pedantry: an inline empty list is
/// indistinguishable from "this citizen has no bills", which is what the only
/// available test account happens to report (`applications total 0`) and is
/// **not** what the code means today.
///
/// ## The two hint strings, and which one is which
///
/// ```
/// {isAuthenticated
///   ? lang === "lo" ? "ຄ່າທຳນຽມທັງໝົດຂອງທ່ານຈ່າຍຄົບແລ້ວ."
///                   : "Every fee on your cases has been paid."
///   : t("signInBills")}                                    — :319-324
/// ```
///
/// Signed in gets the inlined ternary (relocated to `wallet.allBillsPaid` by
/// § 6.13(3)); signed out gets the namespaced `wallet.signInBills`. The
/// asymmetry is the source's.
///
/// ## `viewAll` is a live control that does nothing observable here
///
/// `:279` calls `billsQuery.refetch()` when signed in. B6a has no bills query,
/// so signed-in taps refetch nothing — an honest consequence of the split
/// rather than a dropped behaviour, and B6b restores it when the query exists.
/// Signed out it routes to sign-in, which **is** ported (`B6-AC-50`).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../bloc/wallet_bloc.dart' show kBillsDueB6b;
import 'wallet_panels.dart';

class WalletBillsDueSection extends StatelessWidget {
  const WalletBillsDueSection({
    super.key,
    required this.isAuthenticated,
    required this.onViewAll,
  });

  final bool isAuthenticated;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    // TODO(B6b): the skeleton / error / populated branches, from
    // `ListPendingBills` over B7a's `ApplicationRepository`.
    assert(
      kBillsDueB6b.isEmpty,
      'B6a has no bills source; the constant exists to name that.',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        WalletSectionHeader(
          title: 'wallet.billsDue'.tr(context: context),
          // `bills.length > 0 ? t("billsSummary", …) : t("noBillsDue")` —
          // `:269-275`. The `billsSummary` branch is B6b's; the count is
          // always zero here.
          subtitle: 'wallet.noBillsDue'.tr(context: context),
          actionLabel: 'wallet.viewAll'.tr(context: context),
          onAction: onViewAll,
        ),
        const SizedBox(height: 16),
        WalletEmptyCard(
          // lucide `Receipt`, bundled.
          icon: const LucideIcon(
            name: 'Receipt',
            size: 24,
            color: AppColors.gray400Inline,
          ),
          title: 'wallet.noBillsDue'.tr(context: context),
          subtitle: isAuthenticated
              ? 'wallet.allBillsPaid'.tr(context: context)
              : 'wallet.signInBills'.tr(context: context),
        ),
      ],
    );
  }
}
