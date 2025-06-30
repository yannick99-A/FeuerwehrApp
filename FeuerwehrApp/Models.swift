//
//  Modifiable.swift
//  FeuerwehrApp
//
//  Created by Yannick Luginbühl on 21.06.25.
//


import Foundation
import CloudKit

protocol Modifiable {
    var lastModified: Date { get set }
}

struct Note: Identifiable, Codable, Modifiable {
    let id: UUID
    var text: String
    var imagesData: [Data]?
    var drawingData: Data?
    let createdAt: Date
    var lastModified: Date
    
    init(id: UUID = UUID(), 
         text: String, 
         imagesData: [Data]? = nil, 
         drawingData: Data? = nil, 
         createdAt: Date = Date(),
         lastModified: Date = Date()) {
        self.id = id
        self.text = text
        self.imagesData = imagesData
        self.drawingData = drawingData
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
}

struct Feuerwehr: Identifiable, Codable, Equatable, Hashable, Modifiable {
    let id = UUID()
    var name: String
    var ort: String
    var gruppe: FeuerwehrGruppe
    var fahrzeuge: [Fahrzeug]
    var lastModified: Date = Date()
    
    mutating func updateLastModified() {
        lastModified = Date()
        fahrzeuge.indices.forEach { fahrzeuge[$0].lastModified = Date() }
    }
}

struct Fahrzeug: Identifiable, Codable, Equatable, Hashable, Modifiable {
    let id = UUID()
    var typ: String
    var funkrufname: String
    var standardBesatzung: Int
    var besatzung: Int
    var standardAgtTraeger: Int
    var agtTraeger: Int
    var isSelected: Bool = true
    var foerderstrecke: Int = 1
    var lastModified: Date = Date()
}

enum FeuerwehrGruppe: String, Codable, CaseIterable {
    case ortsfeuerwehr = "Ortsfeuerwehr"
    case bereitschaft = "Feuerwehrbereitschaft"
}