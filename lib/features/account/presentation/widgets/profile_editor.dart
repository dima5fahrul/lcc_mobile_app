/// The Personal Information panel — `AccountPage.tsx:506-551`.
///
/// **Exactly three inputs** — name, email, address (B8-AC-48). Phone is a
/// separate, read-only `Row` (`:553`) and is never editable, which is why
/// `ProfileUpdate` has no `phone` field at all.
///
/// ## The form buffer is the widget's, and that is the port
///
/// `const [form, setForm] = useState({name:"", email:"", address:""})`
/// (`:198`) with a `useEffect` (`:204-207`) that re-seeds it whenever
/// `account.id/name/email/address` change. Here that is three
/// [TextEditingController]s re-seeded in [didUpdateWidget] on the same
/// four-field key. Keeping the buffer out of the BLoC matters for one measured
/// reason: `handleSaveProfile` reads `form` **at press time** and diffs it
/// against `account` then. A BLoC that owned the text would have to re-emit on
/// every keystroke, and the diff would start depending on emit ordering.
///
/// ## Per-field errors, and the one field that has none
///
/// `saveProfile.fieldErrors.name` (`:516`) and `.email` (`:530`) render under
/// their inputs. **`address` has no error slot** (`:534-543` renders none), so
/// a server validation error on `address` is invisible in the web and is
/// invisible here. Ported as measured — B8-AC-49.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../session/domain/entities/citizen_account.dart';
import '../bloc/account_profile_state_view.dart';
import 'account_primitives.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.account,
    required this.view,
    required this.onSave,
  });

  /// The seed for the three controllers, and the diff's left-hand side.
  final CitizenAccount? account;

  final ProfileEditorView view;

  /// Handed the three **raw** values. Trimming happens inside
  /// `ProfileUpdate.diff`, which is where the asymmetry lives and where Tier 0
  /// can reach it.
  final void Function(String name, String email, String address) onSave;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account?.name ?? '');
    _email = TextEditingController(text: widget.account?.email ?? '');
    _address = TextEditingController(text: widget.account?.address ?? '');
  }

  @override
  void didUpdateWidget(covariant ProfileEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // `useEffect(..., [account?.id, account?.name, account?.email,
    // account?.address])` — `:204-207`. Re-seeds only when one of those four
    // actually changed, so a rebuild for any other reason (a sibling panel
    // opening, a preferences refetch) does not stamp on what the citizen is
    // typing.
    final CitizenAccount? was = oldWidget.account;
    final CitizenAccount? now = widget.account;
    if (was?.id == now?.id &&
        was?.name == now?.name &&
        was?.email == now?.email &&
        was?.address == now?.address) {
      return;
    }

    _name.text = now?.name ?? '';
    _email.text = now?.email ?? '';
    _address.text = now?.address ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileEditorView view = widget.view;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FieldLabel('account.fullName'.tr()),
        AccountTextField(controller: _name),
        _FieldError(message: view.nameError),
        const SizedBox(height: AppSpacing.gap12),

        FieldLabel('account.emailLabel'.tr()),
        AccountTextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        _FieldError(message: view.emailError),
        const SizedBox(height: AppSpacing.gap12),

        FieldLabel('account.addressLabel'.tr()),
        // **No `_FieldError` here.** See the library doc — the source renders
        // none for `address`, and adding one would be a divergence that looks
        // like an improvement.
        AccountTextField(controller: _address),
        const SizedBox(height: AppSpacing.gap12),

        // `{saveProfile.error && <p className="text-red-500 text-xs">…}` —
        // `:544-546`.
        if (view.saveError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.gap8),
            child: Text(
              view.saveError!,
              style: const TextStyle(
                color: AppColors.dangerGlyph,
                fontSize: AppTypography.size12,
              ),
            ),
          ),

        // `{profileNote && <p className="text-green-600 text-xs">…}` — `:547`.
        // The key is resolved **here**, at render time, in the reader's locale
        // — see `SaveOutcome`'s doc for why the BLoC stores an enum.
        if (view.noteKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.gap8),
            child: Text(
              view.noteKey!.tr(),
              style: const TextStyle(
                color: AppColors.green600,
                fontSize: AppTypography.size12,
              ),
            ),
          ),

        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AccountButton(
            // `{tc("save")}` — `:549`, the **`common`** namespace, which
            // already exists in Flutter. B8 adds zero `common` keys
            // (B8-AC-62).
            label: 'common.save'.tr(),
            loading: view.saving,
            onPressed: () =>
                widget.onSave(_name.text, _email.text, _address.text),
          ),
        ),
      ],
    );
  }
}

/// `{saveProfile.fieldErrors.X && <p className="text-red-500 text-xs mt-1.5">}`
class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.gap6),
      child: Text(
        message!,
        style: const TextStyle(
          color: AppColors.dangerGlyph,
          fontSize: AppTypography.size12,
        ),
      ),
    );
  }
}
