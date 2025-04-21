// Feuerwehr.swift
import Foundation

struct Feuerwehr: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    var name: String
    var ort: String
    var gruppe: FeuerwehrGruppe // Neue Eigenschaft
    var fahrzeuge: [Fahrzeug]
}

enum FeuerwehrGruppe: String, Codable, CaseIterable {
    case ortsfeuerwehr = "Ortsfeuerwehr"
    case bereitschaft = "Feuerwehrbereitschaft"
}

struct Fahrzeug: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    var typ: String
    var funkrufname: String
    var standardBesatzung: Int
    var besatzung: Int
    var standardAgtTraeger: Int
    var agtTraeger: Int
    var isSelected: Bool = true
    var foerderstrecke: Int = 1 // Neue Eigenschaft: Förderstrecke (1 oder 2)
}
