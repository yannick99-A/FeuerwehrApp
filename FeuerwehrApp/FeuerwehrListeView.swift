// FeuerwehrListeView.swift
import SwiftUI
import SafariServices

struct FeuerwehrListeView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @State private var navigationPath = NavigationPath()
    @State private var showSafariView = false
    
    var body: some View {
        List {
            Section(header: Text("Ortsfeuerwehren")) {
                ForEach(feuerwehren.filter { $0.gruppe == .ortsfeuerwehr }) { feuerwehr in
                    NavigationLink(destination: FeuerwehrDetailView(
                        feuerwehr: safeBinding(for: feuerwehr.id),
                        onSave: saveAll
                    )) {
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
                ForEach(feuerwehren.filter { $0.gruppe == .bereitschaft }) { feuerwehr in
                    NavigationLink(destination: FeuerwehrDetailView(
                        feuerwehr: safeBinding(for: feuerwehr.id),
                        onSave: saveAll
                    )) {
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
            Section {
                Button(action: {
                    showSafariView = true
                }) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Feuerwehr unterstützen")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Hilf mit einer Spende die Feuerwehrarbeit zu finanzieren")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            } footer: {
                Text("Die App ist kostenlos. Spenden gehen direkt an die Feuerwehr und helfen bei der Finanzierung von Ausrüstung und Material.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Alle Feuerwehren")
        .toolbar {
            EditButton()
        }
        .onChange(of: feuerwehren) { _ in
            saveAll()
        }
        .sheet(isPresented: $showSafariView) {
            if let url = URL(string: "https://paypal.me/ffoldenrode") {
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    // MARK: - Safe Binding für Feuerwehren
    // Diese Funktion verhindert den Crash, wenn eine Feuerwehr gelöscht wird, während sie noch angezeigt wird.
    private func safeBinding(for id: UUID) -> Binding<Feuerwehr> {
        Binding<Feuerwehr>(
            get: {
                feuerwehren.first(where: { $0.id == id }) ?? Feuerwehr(name: "", ort: "", gruppe: .ortsfeuerwehr, fahrzeuge: [])
            },
            set: { newValue in
                if let index = feuerwehren.firstIndex(where: { $0.id == id }) {
                    feuerwehren[index] = newValue
                }
            }
        )
    }
    
    private func saveAll() {
        DataManager.shared.saveFeuerwehren(feuerwehren)
    }
    
    private func deleteFeuerwehr(at offsets: IndexSet, gruppe: FeuerwehrGruppe) {
        let filtered = feuerwehren.filter { $0.gruppe == gruppe }
        for index in offsets {
            let idToDelete = filtered[index].id
            feuerwehren.removeAll { $0.id == idToDelete }
        }
        saveAll()
    }
}

struct FeuerwehrDetailView: View {
    @Binding var feuerwehr: Feuerwehr
    var onSave: () -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Feuerwehr-Daten")) {
                TextField("Name", text: $feuerwehr.name)
                TextField("Ort", text: $feuerwehr.ort)
            }
            
            Section(header: Text("Fahrzeuge")) {
                // Hier iterieren wir über das rohe Array und bauen uns für jedes Item ein Safe Binding
                ForEach(feuerwehr.fahrzeuge) { fahrzeug in
                    let fahrzeugBinding = safeFahrzeugBinding(for: fahrzeug.id)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(fahrzeug.typ.isEmpty ? "Neues Fahrzeug" : fahrzeug.typ)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .bold()
                            
                            Spacer()
                            
                            if feuerwehr.fahrzeuge.count > 1 {
                                Button(action: {
                                    removeFahrzeug(withId: fahrzeug.id)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(.bottom, 4)
                        
                        HStack {
                            TextField("Fahrzeugtyp", text: fahrzeugBinding.typ)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            
                            Toggle("", isOn: fahrzeugBinding.isSelected)
                                .labelsHidden()
                        }
                        
                        TextField("Funkrufname", text: fahrzeugBinding.funkrufname)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        
                        Stepper("Besatzung: \(fahrzeug.besatzung)", value: fahrzeugBinding.besatzung, in: 0...20)
                        
                        Stepper("AGT-Träger: \(fahrzeug.agtTraeger)", value: fahrzeugBinding.agtTraeger, in: 0...fahrzeug.besatzung)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6).opacity(0.5)))
                }
                
                Button(action: {
                    withAnimation {
                        feuerwehr.fahrzeuge.append(
                            Fahrzeug(typ: "Neues Fahrzeug", funkrufname: "", standardBesatzung: 1, besatzung: 1, standardAgtTraeger: 0, agtTraeger: 0, isSelected: true)
                        )
                    }
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
            
            Section {
                Button(action: {
                    onSave()
                    hideKeyboard()
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }) {
                    HStack {
                        Spacer()
                        Text("Speichern")
                            .fontWeight(.bold)
                            .font(.system(size: 18))
                        Spacer()
                    }
                }
                .foregroundColor(.white)
                .listRowBackground(Color.blue)
            }
        }
        .navigationTitle(feuerwehr.name)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
    }
    
    // MARK: - Safe Binding für Fahrzeuge
    // Gibt einen Dummy zurück, wenn das Fahrzeug beim Rendern nicht mehr existiert
    private func safeFahrzeugBinding(for id: UUID) -> Binding<Fahrzeug> {
        Binding<Fahrzeug>(
            get: {
                feuerwehr.fahrzeuge.first(where: { $0.id == id }) ?? Fahrzeug(typ: "", funkrufname: "", standardBesatzung: 0, besatzung: 0, standardAgtTraeger: 0, agtTraeger: 0)
            },
            set: { newValue in
                if let index = feuerwehr.fahrzeuge.firstIndex(where: { $0.id == id }) {
                    feuerwehr.fahrzeuge[index] = newValue
                }
            }
        )
    }
    
    private func removeFahrzeug(withId id: UUID) {
        withAnimation {
            feuerwehr.fahrzeuge.removeAll { $0.id == id }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .red
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}
