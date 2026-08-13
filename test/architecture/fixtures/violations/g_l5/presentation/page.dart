// G-L5 fixture — THE VIOLATION, and it is deliberately a double one: this file
// both imports a `di/` path and names a locator, which are the two independent
// halves of the guard. Asserting on both is how the self-test proves neither
// half was quietly dropped.
//
// CR-1 (SSD § 6.4): route builders and `main.dart` may resolve from a locator;
// no widget may.
import '../di/auth_injection.dart';

String fixtureRead() => authInjection();
