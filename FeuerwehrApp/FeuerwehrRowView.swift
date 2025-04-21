// FeuerwehrRowView.swift
import SwiftUI

struct FeuerwehrRowView: View {
    let fahrzeug: Fahrzeug
    let feuerwehrName: String // Feuerwehr-Name hinzufügen
    let index: Int // Index des Fahrzeugs in der Liste
    @Binding var distance: Int
    let showArrow: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index + 1). \(feuerwehrName) - \(fahrzeug.typ) (\(fahrzeug.funkrufname))") // Feuerwehr-Name, Typ und Funkrufname anzeigen
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                TextField("Meter", value: $distance, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .onChange(of: distance) { _ in
                        // Diese Aktion wird automatisch durch das Binding ausgelöst
                    }
                Text("Meter")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if showArrow {
                HStack {
                    Spacer()
                    Text("↓") // Richtungspfeil nach unten
                        .font(.title)
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
