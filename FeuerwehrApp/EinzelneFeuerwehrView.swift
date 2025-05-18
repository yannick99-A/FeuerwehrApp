import SwiftUI

struct EinzelneFeuerwehrView: View {
    @Binding var feuerwehr: Feuerwehr
    @Binding var feuerwehren: [Feuerwehr]
    
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
                            // Linksbündig: Status-Switch
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
                            
                            Spacer() // Drückt den Picker nach rechts
                            
                            // Rechtsbündig: Förderstrecken-Picker
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Förderstrecke")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("", selection: $fahrzeug.foerderstrecke) {
                                    Text("1").tag(1)
                                    Text("2").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 120)
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
}
