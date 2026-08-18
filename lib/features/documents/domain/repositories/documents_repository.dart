/// The collection slice's repository — **exactly two methods, both reads**
/// (`B5-AC-32`, `B5-AC-25`).
///
/// `GET /me/certificates` and `GET /me/certificates/{id}` are the only two of
/// B5's ten dispatched endpoints that survive adjudication (specs.md § 6.0);
/// the other eight are dead, F4's or B8's. There is **no write path** in this
/// feature, which is also why the fidelity instrument reports Tier 0 as
/// *N/A — no write path* rather than PASS (§ 6.13).
///
/// A third method here is out of scope. If one appears necessary, that is a
/// § 8.3 escalation, not an implementer's call.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/issued_certificate.dart';

abstract class DocumentsRepository {
  /// `me.certificates()` — `endpoints.ts:131`, consumed at
  /// `HistoryDetailPage.tsx:149`. A **plain array**, not paged.
  Future<Either<Failure, List<IssuedCertificate>>> getCertificates();

  /// `me.certificate(id)` — `endpoints.ts:132`, consumed at `:157`.
  Future<Either<Failure, IssuedCertificate>> getCertificate(String id);
}
