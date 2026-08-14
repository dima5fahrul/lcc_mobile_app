/// `AccountDocumentsBloc` — the "My Documents" card's read.
///
/// Ports `const docsQuery = useQuery((signal) => me.documents(signal), [])`
/// (`AccountPage.tsx:190`) and the four list states it drives (`:398-488`).
///
/// One of **three** BLoCs on this page, not one of one (specs.md § 6.3): the
/// source runs three independent `useQuery` calls whose loading and error
/// states render in three different places.
///
/// ## The generation guard is a port, not an embellishment
///
/// `hooks.ts:55,73` stamps every in-flight request with
/// `const mine = ++generation.current` and drops the response when
/// `mine !== generation.current` — *"a newer request won"*. Reproduced here as
/// [_generation], and it is load-bearing: `bloc` 9.2.1's default event
/// transformer is **concurrent**, so two taps on Retry start two fetches and
/// without the stamp the slower one overwrites the fresher one on arrival.
/// Four B2 BLoCs `emit(… await …)` with no such re-check; B9 ported the guard
/// and this one does too.
///
/// ## GG-2 — this feature has never been measured against live data
///
/// No one has called `/me/documents` for the `Mencoba` test citizen. Given
/// `/me/digital-id` and `/me/family-book` both 404 for it, an empty list is
/// *likely* and is **not established** (specs.md § 6.5). The four states are
/// gated against fixtures; the populated state's live behaviour is reported
/// NOT EVALUATED with that reason (B8-AC-28), never asserted from the guess.
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/citizen_document.dart';
import '../../domain/usecases/account_usecases.dart';
import 'account_region_status.dart';

part 'account_documents_event.dart';
part 'account_documents_state.dart';
part 'account_documents_bloc.freezed.dart';

class AccountDocumentsBloc
    extends Bloc<AccountDocumentsEvent, AccountDocumentsState> {
  AccountDocumentsBloc({required this.getDocuments})
      : super(const AccountDocumentsState()) {
    on<AccountDocumentsRequested>(_onRequested);
    on<AccountDocumentsRetried>(_onRequested);
  }

  final GetDocuments getDocuments;

  /// `hooks.ts:55` — `const generation = useRef(0)`.
  int _generation = 0;

  Future<void> _onRequested(
    AccountDocumentsEvent event,
    Emitter<AccountDocumentsState> emit,
  ) async {
    final int mine = ++_generation;
    emit(state.copyWith(status: RegionStatus.loading));

    final Either<Failure, List<CitizenDocument>> result =
        await getDocuments(NoParams());
    // "a newer request won" — `hooks.ts:73`.
    if (mine != _generation || emit.isDone) return;

    emit(state.withDocuments(result));
  }
}
