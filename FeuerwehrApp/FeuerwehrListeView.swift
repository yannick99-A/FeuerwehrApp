// FeuerwehrListeView.swift
import SwiftUI

struct FeuerwehrListeView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @State private var navigationPath = NavigationPath()
    @State private var showSafariView = false
    
    var body: some View {
        List {
            Section(header: Text("Ortsfeuerwehren")) {
                ForEach($feuerwehren.filter { $0.wrappedValue.gruppe == .ortsfeuerwehr }) { $feuerwehr in
                    NavigationLink(destination: FeuerwehrDetailView(feuerwehr: $feuerwehr)) {
                        VStack(alignment: .leading) {
                            Text(feuerwehr.name)
                                .font(.headline)
                            Text(feuerwehr.ort)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete { offsets in
                    deleteFeuerwehr(at: offsets, gruppe: .ortsfeuerwehr)
                }
            }
            
            Section(header: Text("Feuerwehrbereitschaft")) {
                ForEach($feuerwehren.filter { $0.wrappedValue.gruppe == .bereitschaft }) { $feuerwehr in
                    NavigationLink(destination: FeuerwehrDetailView(feuerwehr: $feuerwehr)) {
                        VStack(alignment: .leading) {
                            Text(feuerwehr.name)
                                .font(.headline)
                            Text(feuerwehr.ort)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete { offsets in
                    deleteFeuerwehr(at: offsets, gruppe: .bereitschaft)
                }
            }
        }
        .navigationTitle("Alle Feuerwehren")
        .toolbar {
            EditButton()
        }
    }
    
    private func deleteFeuerwehr(at offsets: IndexSet, gruppe: FeuerwehrGruppe) {
        let filtered = feuerwehren.filter { $0.gruppe == gruppe }
        for index in offsets {
            if let globalIndex = feuerwehren.firstIndex(where: { $0.id == filtered[index].id }) {
                feuerwehren.remove(at: globalIndex)
            }
        }
        DataManager.shared.saveFeuerwehren(feuerwehren)
    }
}

struct FeuerwehrDetailView: View {
    @Binding var feuerwehr: Feuerwehr
    
    var body: some View {
        Form {
            Section(header: Text("Feuerwehr-Daten")) {
                TextField("Name", text: $feuerwehr.name)
                TextField("Ort", text: $feuerwehr.ort)
            }
            
            Section(header: Text("Fahrzeuge")) {
                ForEach(Array($feuerwehr.fahrzeuge.enumerated()), id: \.element.id) { index, $fahrzeug in
                    VStack(alignment: .leading, spacing: 12) {
                        // Header mit Entfernen-Button (nur wenn mehr als 1 Fahrzeug)
                        HStack {
                            Text("Fahrzeug \(index + 1)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .bold()
                            
                            Spacer()
                            
                            // Entfernen-Button nur anzeigen, wenn mehr als 1 Fahrzeug vorhanden
                            if feuerwehr.fahrzeuge.count > 1 {
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
                        Toggle(isOn: $fahrzeug.isSelected) {
                            TextField("Fahrzeugtyp", text: $fahrzeug.typ)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        TextField("Funkrufname", text: $fahrzeug.funkrufname)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Stepper("Besatzung: \(fahrzeug.besatzung)", value: $fahrzeug.besatzung, in: 0...20)
                        
                        Stepper("AGT-Träger: \(fahrzeug.agtTraeger)", value: $fahrzeug.agtTraeger, in: 0...fahrzeug.besatzung)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6).opacity(0.5))
                    )
                }
                
                Button(action: {
                    feuerwehr.fahrzeuge.append(
                        Fahrzeug(
                            typ: "Neues Fahrzeug",
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
                .padding(.top, 8)
            }
        }
        .navigationTitle(feuerwehr.name)
        .onChange(of: feuerwehr) { _ in
            DataManager.shared.saveFeuerwehren(DataManager.shared.loadFeuerwehren())
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
    }
    
    private func removeFahrzeug(at index: Int) {
        guard feuerwehr.fahrzeuge.count > 1 else { return }
        feuerwehr.fahrzeuge.remove(at: index)
    }
    
    private func deleteFahrzeug(at offsets: IndexSet) {
        feuerwehr.fahrzeuge.remove(atOffsets: offsets)
    }
}

// SafariView für die Web-Anzeige
import SafariServices
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}
