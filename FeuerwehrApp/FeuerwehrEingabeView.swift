// FeuerwehrEingabeView.swift
import SwiftUI

struct FeuerwehrEingabeView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var ort: String = ""
    @State private var selectedGruppe: FeuerwehrGruppe = .ortsfeuerwehr
    @State private var fahrzeuge: [Fahrzeug] = [
        Fahrzeug(
            typ: "",
            funkrufname: "",
            standardBesatzung: 1,
            besatzung: 1,
            standardAgtTraeger: 0,
            agtTraeger: 0,
            isSelected: true // Standardmäßig ausgewählt
        )
    ]
    
    private var isInputValid: Bool {
        !name.isEmpty && !ort.isEmpty &&
        fahrzeuge.allSatisfy { !$0.typ.isEmpty && !$0.funkrufname.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Feuerwehr-Daten")) {
                                    TextField("Name", text: $name)
                                    TextField("Ort", text: $ort)
                                    Picker("Gruppe", selection: $selectedGruppe) {
                                        ForEach(FeuerwehrGruppe.allCases, id: \.self) { gruppe in
                                            Text(gruppe.rawValue).tag(gruppe)
                                        }
                                    }
                                }
                
                Section(header: Text("Fahrzeuge")) {
                    ForEach($fahrzeuge) { $fahrzeug in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Fahrzeugtyp", text: $fahrzeug.typ)
                                .padding(.vertical, 4)
                            
                            TextField("Funkrufname", text: $fahrzeug.funkrufname)
                                .keyboardType(.namePhonePad)
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Standardbesatzung: \(fahrzeug.standardBesatzung)")
                                Spacer()
                                Stepper("",
                                    value: $fahrzeug.standardBesatzung,
                                    in: 1...20
                                )
                                .labelsHidden()
                            }
                            
                            HStack {
                                Text("Standard-AGT-Träger: \(fahrzeug.standardAgtTraeger)")
                                Spacer()
                                Stepper("",
                                    value: $fahrzeug.standardAgtTraeger,
                                    in: 0...fahrzeug.standardBesatzung
                                )
                                .labelsHidden()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteFahrzeug)
                    
                    Button("Fahrzeug hinzufügen") {
                        fahrzeuge.append(
                            Fahrzeug(
                                typ: "",
                                funkrufname: "",
                                standardBesatzung: 1,
                                besatzung: 1,
                                standardAgtTraeger: 0,
                                agtTraeger: 0,
                                isSelected: true // Standardmäßig ausgewählt
                            )
                        )
                    }
                }
            }
            .navigationTitle("Neue Feuerwehr")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let neueFeuerwehr = Feuerwehr(
                                    name: name,
                                    ort: ort,
                                    gruppe: selectedGruppe,
                                    fahrzeuge: fahrzeuge
                                )
                                feuerwehren.append(neueFeuerwehr)
                                DataManager.shared.saveFeuerwehren(feuerwehren)
                                isPresented = false
                    }
                    .disabled(!isInputValid)
                }
            }
            .onTapGesture {
                        hideKeyboard()
                    }
        }
        .contentShape(Rectangle()) // Wichtig für Tap-Gesture
            .onTapGesture {
                hideKeyboard()
            }
    }
    
    private func deleteFahrzeug(at offsets: IndexSet) {
        fahrzeuge.remove(atOffsets: offsets)
        if fahrzeuge.isEmpty {
            fahrzeuge.append(
                Fahrzeug(
                    typ: "",
                    funkrufname: "",
                    standardBesatzung: 1,
                    besatzung: 1,
                    standardAgtTraeger: 0,
                    agtTraeger: 0,
                    isSelected: true // Standardmäßig ausgewählt
                )
            )
        }
    }
}


