import SwiftUI

struct EinzelneFeuerwehrView: View {
    @Binding var feuerwehr: Feuerwehr
    @Binding var feuerwehren: [Feuerwehr]
    
    // Findet die aktuelle ESP (über alle Feuerwehren hinweg)
    private var currentESP: Fahrzeug? {
        feuerwehren.flatMap { $0.fahrzeuge }.first { $0.foerderstrecke == 3 }
    }
    
    // Prüft ob eine andere ESP existiert (außer dem aktuellen Fahrzeug)
    private func isOtherESPSelected(except currentFahrzeugID: UUID) -> Bool {
        if let esp = currentESP, esp.id != currentFahrzeugID {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Feuerwehr-Header
            VStack(alignment: .leading, spacing: 4) {
                Text(feuerwehr.name)
                    .font(.headline)
                Text(feuerwehr.ort)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)
            
            // Fahrzeugliste
            ForEach($feuerwehr.fahrzeuge) { $fahrzeug in
                VStack(alignment: .leading, spacing: 12) {
                    // Fahrzeugtyp mit Funkrufname
                    Text("\(fahrzeug.typ) - \(fahrzeug.funkrufname)")
                        .font(.subheadline.bold())
                        .padding(.bottom, 4)
                    
                    // Horizontale Anordnung mit Ausrichtung
                    HStack {
                        // Links: Status-Switch
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status in Förderstrecke")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Toggle("", isOn: $fahrzeug.isSelected)
                                    .labelsHidden()
                                Text(fahrzeug.isSelected ? "Aktiviert" : "Deaktiviert")
                                    .font(.footnote)
                                    .foregroundColor(fahrzeug.isSelected ? .green : .red)
                            }
                        }
                        
                        Spacer()
                        
                        // Rechts: Förderstrecken-Picker
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Förderstrecke")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("", selection: $fahrzeug.foerderstrecke) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                                Text("ESP").tag(3)
                                    .disabled(isOtherESPSelected(except: fahrzeug.id))
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                            .onChange(of: $fahrzeug.foerderstrecke.wrappedValue) { newValue in
                                if newValue == 3 {
                                    resetOtherESPs(except: fahrzeug.id)
                                }
                            }
                        }
                    }
                    
                    // Besatzungssteuerung
                    VStack(spacing: 8) {
                        HStack {
                            Text("Besatzung: \(fahrzeug.besatzung)")
                            Spacer()
                            Stepper("", value: $fahrzeug.besatzung, in: 0...20)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("AGT-Träger: \(fahrzeug.agtTraeger)")
                            Spacer()
                            Stepper("",
                                value: $fahrzeug.agtTraeger,
                                in: 0...fahrzeug.besatzung
                            )
                            .labelsHidden()
                        }
                    }
                    .font(.footnote)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            Divider()
                .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
        .onChange(of: feuerwehr.fahrzeuge) { _ in
            DataManager.shared.saveFeuerwehren(feuerwehren)
        }
    }
    
    // Setzt alle anderen ESPs auf Förderstrecke 1 zurück
    private func resetOtherESPs(except fahrzeugID: UUID) {
        for i in 0..<feuerwehren.count {
            for j in 0..<feuerwehren[i].fahrzeuge.count {
                if feuerwehren[i].fahrzeuge[j].id != fahrzeugID &&
                   feuerwehren[i].fahrzeuge[j].foerderstrecke == 3 {
                    feuerwehren[i].fahrzeuge[j].foerderstrecke = 1
                }
            }
        }
    }
}
