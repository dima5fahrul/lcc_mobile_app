// G-L8 fixture — THE VIOLATION. A `.tr()` call with no `context:`.
//
// `easy_localization`'s `public.dart`:39-44 branches on exactly one thing:
// with a context it goes through `Localization.of(context)` and registers an
// `InheritedWidget` dependency; without one it reads the global
// `Localization.instance` and registers nothing. The second form is D-3.
//
// This fixture plants **three** call sites so the guard is proved to
// discriminate rather than merely to fire:
//
//   :23  bare              → REPORTED
//   :26  `context:` passed → not reported
//   :30  `context` appears only INSIDE a nested argument → REPORTED
//
// The third is the one a regex gets wrong. `\.tr\([^)]*\)` stops at the first
// `)`, which here is `resolve(context)`'s, and a naive "does the call mention
// `context`" test would call it bound. It is not: `namedArgs` is data, and the
// string is still read off the global.
//
// It trips G-L8 and nothing else: no imports at all, so G-L1/2/3/4/7 have no
// edge to look at, and no locator identifier for G-L5.

String bare() => 'planted.bare'.tr();

String boundToContext(Object context) =>
    'planted.bound'.tr(context: context);

Object resolve(Object c) => c;

String looksBoundButIsNot(Object context) => 'planted.nested'.tr(
      namedArgs: <String, Object>{'who': resolve(context)},
    );

extension on String {
  String tr({Object? context, Map<String, Object>? namedArgs}) => this;
}
