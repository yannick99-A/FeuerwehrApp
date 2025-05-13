// FeuerwehrListeView.swift
import SwiftUI

// FeuerwehrListeView.swift
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
            // Spenden-Section
            /*Section {
                                Button(action: {
                                    showSafariView = true
                                }) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                        Text("Spenden für die Feuerwehr")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .sheet(isPresented: $showSafariView) {
                                    if let url = URL(string: "https://paypal.me/ffoldenrode") {
                                        SafariView(url: url)
                                    }
                                }
                            }*/
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
                ForEach($feuerwehr.fahrzeuge) { $fahrzeug in
                    VStack(alignment: .leading) {
                        Toggle(isOn: $fahrzeug.isSelected) {
                            TextField("Fahrzeugtyp", text: $fahrzeug.typ)
                        }
                        TextField("Funkrufname", text: $fahrzeug.funkrufname)
                        Stepper("Besatzung: \(fahrzeug.besatzung)", value: $fahrzeug.besatzung, in: 0...20)
                        Stepper("AGT-Träger: \(fahrzeug.agtTraeger)", value: $fahrzeug.agtTraeger, in: 0...fahrzeug.besatzung)
                    }
                }
                .onDelete(perform: deleteFahrzeug)
                
                Button("Fahrzeug hinzufügen") {
                    feuerwehr.fahrzeuge.append(
                        Fahrzeug(
                            typ: "Neues Fahrzeug",
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
        .navigationTitle(feuerwehr.name)
        .onChange(of: feuerwehr) { _ in
            DataManager.shared.saveFeuerwehren(DataManager.shared.loadFeuerwehren())
        }
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
