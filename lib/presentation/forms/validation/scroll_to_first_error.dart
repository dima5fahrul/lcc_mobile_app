/// `formValidation.tsx:150-163` — after a form reveals its errors, jump to the
/// first invalid field.
///
/// ```ts
/// requestAnimationFrame(() => {
///   const marker = document.querySelector("[data-field-error]");
///   if (!marker) return;
///   const field = marker.parentElement ?? marker;
///   field.scrollIntoView({ behavior: "smooth", block: "center" });
///   const control = …find first visible, non-disabled…;
///   control?.focus({ preventScroll: true });
/// });
/// ```
///
/// Three behaviours are ported and each is separately observable:
///
/// 1. **It waits a frame.** `requestAnimationFrame` waits for React to commit
///    the newly-rendered error nodes before querying the DOM; the call site is
///    right after `setShowErrors(true)`. Flutter's equivalent is
///    [WidgetsBinding.addPostFrameCallback] — without it the markers this
///    function looks for do not exist yet, and it silently finds nothing.
/// 2. **First in document order.** `querySelector` returns the first match in
///    document order, which is the first invalid field. Depth-first pre-order
///    over the element tree is the same order.
/// 3. **Centred, then focused.** `block: "center"` is `alignment: 0.5`;
///    `preventScroll: true` is Flutter's default, since requesting focus does
///    not scroll on its own.
///
/// ## Why this is two functions and not one `Future`
///
/// The source returns `void` and neither awaits the smooth scroll nor reports
/// whether it found anything, so a `Future<bool>` would be a shape the port
/// invented. It was also untestable in practice: a completer resolved inside a
/// post-frame callback, awaited from a `testWidgets` body, deadlocks the
/// fake-async zone — the test hangs rather than fails, which is the worst
/// possible failure mode for a gate.
///
/// So the **decision** is [scrollToFirstErrorNow] — synchronous, returns
/// whether it found a field, and directly assertable — and [scrollToFirstError]
/// is the thin frame-waiting wrapper the pages call. The behaviour is in the
/// half a test can hold.
library;

import 'package:flutter/widgets.dart';

import 'field_error.dart';

/// How long the smooth scroll takes. `scrollIntoView({behavior: "smooth"})`
/// leaves the duration to the browser; 300 ms is Flutter's own convention for
/// the same gesture and no tier can observe the difference.
const Duration kScrollToErrorDuration = Duration(milliseconds: 300);

/// The page-facing call: wait one frame, then jump.
///
/// Call it right after flipping `showErrors`, exactly as the source does — the
/// frame is what lets the newly-revealed error rows exist before they are
/// looked for.
void scrollToFirstError(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    scrollToFirstErrorNow(context);
  });
}

/// Scroll the first [FieldErrorMarker] under [context] to the centre of the
/// viewport and focus its control, **now**, without waiting for a frame.
///
/// Returns whether a marker was found — so a test can assert the capability
/// (it located a field and focused it) rather than that the function was
/// called.
///
/// The scroll animation is deliberately **not** awaited: `scrollIntoView` is
/// fire-and-forget in the browser and `control?.focus()` runs on the next line,
/// not 300 ms later. That is also what `preventScroll: true` exists to make
/// safe.
bool scrollToFirstErrorNow(BuildContext context) {
  final Element? marker = firstErrorMarker(context);
  if (marker == null) return false;

  Scrollable.ensureVisible(
    marker,
    alignment: 0.5,
    duration: kScrollToErrorDuration,
    curve: Curves.easeInOut,
  );

  final FocusNode? node = (marker.widget as FieldErrorMarker).focusNode;
  if (node != null && node.canRequestFocus) node.requestFocus();

  return true;
}

/// The first [FieldErrorMarker] element under [context], in depth-first
/// pre-order — the analogue of `document.querySelector`'s document order.
///
/// Exposed so a test can assert *which* field was found, not merely that one
/// was: "it scrolled somewhere" and "it scrolled to the first invalid field"
/// are different claims and only the second is the behaviour.
Element? firstErrorMarker(BuildContext context) {
  Element? found;

  void visit(Element element) {
    if (found != null) return;
    if (element.widget is FieldErrorMarker) {
      found = element;
      return;
    }
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return found;
}
