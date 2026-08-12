/// Wallet tab — P0 placeholder.
///
/// Public, like the React source: `App.tsx` keeps `wallet` out of
/// `PROTECTED_TABS` and lets `WalletPage` render an empty state for a
/// signed-out visitor, prompting for auth only when an action needs it. The
/// real screen (balance, quick payments, bills due, recent transactions) is a
/// later batch.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/shell/tab_placeholder.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPlaceholder(
      icon: Icons.account_balance_wallet_outlined,
      title: 'wallet.title'.tr(),
      subtitle: 'wallet.subtitle'.tr(),
    );
  }
}
