// certificate_page_isolation fixture — the INNOCENT half of the pair.
//
// This file is what the sibling under `death/` reaches for. It imports nothing
// and violates nothing: the edge is the importer's, and the guard must cite the
// importer, not this file. A guard that reported both ends would send a reader
// to the wrong one.
const String fixtureBirthParentDataName = 'parents.name';
