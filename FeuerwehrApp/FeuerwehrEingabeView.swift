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
            isSelected: true
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
                    ForEach(Array(fahrzeuge.enumerated()), id: \.element.id) { index, _ in
                        VStack(alignment: .leading, spacing: 8) {
                            // Header mit Entfernen-Button
                            HStack {
                                Text("Fahrzeug \(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                // Entfernen-Button nur anzeigen, wenn mehr als 1 Fahrzeug vorhanden
                                if fahrzeuge.count > 1 {
                                    Button(action: {
                                        removeFahrzeug(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 20))
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .padding(.bottom, 4)
                            
                            // Fahrzeug-Eingabefelder
                            TextField("Fahrzeugtyp", text: $fahrzeuge[index].typ)
                                .padding(.vertical, 4)
                            
                            TextField("Funkrufname", text: $fahrzeuge[index].funkrufname)
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Standardbesatzung: \(fahrzeuge[index].standardBesatzung)")
                                Spacer()
                                Stepper("",
                                    value: $fahrzeuge[index].standardBesatzung,
                                    in: 1...20
                                )
                                .labelsHidden()
                            }
                            
                            HStack {
                                Text("Standard-AGT-Träger: \(fahrzeuge[index].standardAgtTraeger)")
                                Spacer()
                                Stepper("",
                                    value: $fahrzeuge[index].standardAgtTraeger,
                                    in: 0...fahrzeuge[index].standardBesatzung
                                )
                                .labelsHidden()
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .padding(.horizontal, -8)
                        )
                    }
                    
                    Button(action: {
                        fahrzeuge.append(
                            Fahrzeug(
                                typ: "",
                                funkrufname: "",
                                standardBesatzung: 1,
                                besatzung: 1,
                                standardAgtTraeger: 0,
                                agtTraeger: 0,
                                isSelected: true
                            )
                        )
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Fahrzeug hinzufügen")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
        }
    }
    
    private func removeFahrzeug(at index: Int) {
        guard fahrzeuge.count > 1 else { return }
        fahrzeuge.remove(at: index)
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
                    isSelected: true
                )
            )
        }
    }
}
