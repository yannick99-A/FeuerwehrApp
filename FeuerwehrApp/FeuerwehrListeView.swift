// FeuerwehrListeView.swift
import SwiftUI
import SafariServices
import PDFKit // WICHTIG: Wird für das Zusammenfügen der PDFs benötigt!

struct FeuerwehrListeView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @State private var navigationPath = NavigationPath()
    @State private var showSafariView = false
    
    // Neue State-Variablen für Export und Reset
    @State private var showResetAlert = false
    @State private var pdfURL: IdentifiableURL?
    
    var body: some View {
        List {
            // MARK: - Einsatz-Verwaltung (NEU)
            Section(header: Text("Einsatz-Verwaltung")) {
                Button(action: {
                    exportCompleteOperation()
                }) {
                    Label("Gesamten Einsatz exportieren", systemImage: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
                
                Button(role: .destructive, action: {
                    showResetAlert = true
                }) {
                    Label("Einsatz beenden & zurücksetzen", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            
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
        .sheet(item: $pdfURL) { identifiableURL in
            ShareSheet(activityItems: [identifiableURL.url])
        }
        // Alert für das Zurücksetzen
        .alert("Einsatz beenden?", isPresented: $showResetAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Alles zurücksetzen", role: .destructive) {
                resetEinsatz()
            }
        } message: {
            Text("Möchtest du diesen Einsatz wirklich beenden? Alle Fahrzeuge werden deaktiviert, die Besatzung wird auf Standardwerte zurückgesetzt. Notizen und Karten-Routen werden unwiderruflich gelöscht!\n\n(Die Feuerwehren selbst bleiben erhalten)")
        }
    }
    
    // MARK: - Einsatz-Logik (NEU)
    
    private func resetEinsatz() {
            // 1. Fahrzeuge zurücksetzen
            for i in 0..<feuerwehren.count {
                for j in 0..<feuerwehren[i].fahrzeuge.count {
                    feuerwehren[i].fahrzeuge[j].isSelected = false
                    feuerwehren[i].fahrzeuge[j].foerderstrecke = 1
                    
                    let fahrzeug = feuerwehren[i].fahrzeuge[j]
                    feuerwehren[i].fahrzeuge[j].besatzung = fahrzeug.standardBesatzung
                    feuerwehren[i].fahrzeuge[j].agtTraeger = fahrzeug.standardAgtTraeger
                }
            }
            saveAll()
            
            // 2. Notizen aus dem Speicher löschen
            UserDefaults.standard.removeObject(forKey: "savedNotes")
            
            // 3. Karten-Status löschen (Routen und Pins)
            UserDefaults.standard.removeObject(forKey: "kartenState_v2")
            
            // NEU: Funkspruch an alle anderen Tabs senden, dass aufgeräumt wurde!
            NotificationCenter.default.post(name: NSNotification.Name("EinsatzReset"), object: nil)
            
            // Haptisches Feedback für Erfolg
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }
    
    private func exportCompleteOperation() {
        var urlsToMerge: [URL] = []
        let activeFeuerwehrIDs = Set(feuerwehren.filter { fw in fw.fahrzeuge.contains(where: { $0.isSelected }) }.map { $0.id })
        
        // 1. Feuerwehr-Übersicht generieren
        if let uebersichtURL = PDFGenerator.generateFeuerwehrUebersichtPDF(
            feuerwehren: feuerwehren,
            selectedFeuerwehren: activeFeuerwehrIDs,
            includeInactiveVehicles: false,
            espFahrzeug: nil // Könnte ausgebaut werden
        ) {
            urlsToMerge.append(uebersichtURL)
        }
        
        // 2. Wasserförderstrecken generieren (Achtung: Distanzen sind 0, da sie in einer anderen View liegen)
        for strecke in 1...2 {
            let fahrzeugeStrecke = feuerwehren.flatMap { fw in
                fw.fahrzeuge.filter { $0.isSelected && $0.foerderstrecke == strecke }
                    .map { (fahrzeug: $0, feuerwehrName: fw.name) }
            }
            
            if !fahrzeugeStrecke.isEmpty {
                let dummyDistances = Array(repeating: 0, count: fahrzeugeStrecke.count)
                if let wfsURL = PDFGenerator.generateCombinedPDF(
                    for: fahrzeugeStrecke,
                    distances: dummyDistances,
                    foerderstrecke: strecke,
                    funkrufgruppe: "",
                    espFahrzeug: nil,
                    andereFoerderstreckeFahrzeug: nil,
                    espDistance: 0
                ) {
                    urlsToMerge.append(wfsURL)
                }
            }
        }
        
        // 3. Notizen generieren
        if let data = UserDefaults.standard.data(forKey: "savedNotes"),
           let notes = try? JSONDecoder().decode([Note].self, from: data),
           !notes.isEmpty {
            if let notesURL = PDFGenerator.generateNotesPDF(notes: notes) {
                urlsToMerge.append(notesURL)
            }
        }
        
        // 4. Alles zu einem Master-PDF mergen
        if let mergedURL = mergePDFs(urls: urlsToMerge) {
            self.pdfURL = IdentifiableURL(url: mergedURL)
        }
    }
    
    private func mergePDFs(urls: [URL]) -> URL? {
        let pdfDocument = PDFDocument()
        var pageCount = 0
        
        for url in urls {
            if let doc = PDFDocument(url: url) {
                for i in 0..<doc.pageCount {
                    if let page = doc.page(at: i) {
                        pdfDocument.insert(page, at: pageCount)
                        pageCount += 1
                    }
                }
            }
        }
        
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let outputURL = documentDirectory.appendingPathComponent("Gesamter_Einsatzbericht.pdf")
            if pdfDocument.write(to: outputURL) {
                return outputURL
            }
        }
        return nil
    }
    
    // MARK: - Safe Binding für Feuerwehren
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

// ... Rest der Datei (FeuerwehrDetailView und SafariView) bleibt absolut unverändert! ...

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
                            Fahrzeug(typ: "Neues Fahrzeug", funkrufname: "", standardBesatzung: 6, besatzung: 6, standardAgtTraeger: 0, agtTraeger: 0, isSelected: true)
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
