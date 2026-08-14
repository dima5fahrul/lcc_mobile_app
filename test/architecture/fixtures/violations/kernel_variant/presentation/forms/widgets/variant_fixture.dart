// PLANTED VIOLATION — `F0-AC-22`. Not compiled into the app; scanned as text.
//
// Each declaration below is one of `kForbiddenKernelSymbols`, in the shape a
// real fork would arrive in: a second widget that reproduces `SearchableSelect`
// with the failure parameters omitted rather than omitting them at the call
// site. § 6.3.4 row 4 is the ruling this defends.
//
// A `SelectField` named only in this comment must NOT be reported — that is the
// comment-stripping property `guard_selftest_test.dart` asserts for every scan.

class SelectField {}

class ApiLocationFields {}

typedef RefList = List<String>;
