// WasserfoerderstreckeView.swift
import SwiftUI

// Wrapper-Typ, um URL identifizierbar zu machen
struct IdentifiableURL: Identifiable {
    let id = UUID() // Eindeutige ID
    let url: URL
}

// ShareSheet für das Teilen des PDFs
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// WasserfoerderstreckeView.swift
import SwiftUI

struct WasserfoerderstreckeView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @Binding var selectedFeuerwehren: Set<UUID>
    
    @State private var orderedFahrzeuge1: [(fahrzeug: Fahrzeug, feuerwehrName: String)] = []
    @State private var orderedFahrzeuge2: [(fahrzeug: Fahrzeug, feuerwehrName: String)] = []
    @State private var espFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)? = nil
    @State private var distances1: [Int] = []
    @State private var distances2: [Int] = []
    @State private var totalDistance1: Int = 0
    @State private var totalDistance2: Int = 0
    @State private var pdfURL1: IdentifiableURL?
    @State private var pdfURL2: IdentifiableURL?
    @State private var funkrufgruppe1: String = ""
    @State private var funkrufgruppe2: String = ""
    @State private var espDistance: Int = 0
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // Vertikale Anordnung für schmale Ansicht
                ScrollView {
                    VStack(spacing: 20) {
                        foerderstreckeView(foerderstrecke: 1)
                        foerderstreckeView(foerderstrecke: 2)
                    }
                    .padding()
                }
            } else {
                // Horizontale Anordnung für breite Ansicht
                HStack(alignment: .top, spacing: 10) {
                    foerderstreckeView(foerderstrecke: 1)
                    foerderstreckeView(foerderstrecke: 2)
                }
                .padding()
            }
        }
        .onAppear {
            updateFahrzeugeLists()
        }
        .onChange(of: feuerwehren) { _ in
            updateFahrzeugeLists()
        }
        .onChange(of: distances1) { _ in
            calculateTotalDistance()
        }
        .onChange(of: distances2) { _ in
            calculateTotalDistance()
        }
    }
    
    @ViewBuilder
    private func foerderstreckeView(foerderstrecke: Int) -> some View {
        let fahrzeuge = foerderstrecke == 1 ? orderedFahrzeuge1 : orderedFahrzeuge2
        let distances = foerderstrecke == 1 ? distances1 : distances2
        let totalDistance = foerderstrecke == 1 ? totalDistance1 : totalDistance2
        let funkrufgruppe = foerderstrecke == 1 ? $funkrufgruppe1 : $funkrufgruppe2
        let pdfURL = foerderstrecke == 1 ? $pdfURL1 : $pdfURL2
        
        VStack {
            // Header mit angepasstem Padding
            Text("Förderstrecke \(foerderstrecke): \(fahrzeuge.count) Fahrzeuge, Länge: \(totalDistance) m (\(totalDistance/20) B-Schläuche)")
                .font(.headline)
                .padding(.bottom, 5)
                .padding(.top, 10)
            
            TextField("Funkrufgruppe Strecke \(foerderstrecke)", text: funkrufgruppe)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Fertig") {
                                        hideKeyboard()
                                    }
                                }
                            }
            
            List {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Wasserentnahmestelle")
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .listRowSeparator(.hidden)
                .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                // Liste der Fahrzeuge
                ForEach(Array(fahrzeuge.enumerated()), id: \.element.fahrzeug.id) { index, element in
                    FeuerwehrRowView(
                        fahrzeug: element.fahrzeug,
                        feuerwehrName: element.feuerwehrName,
                        index: index,
                        distance: Binding(
                                                get: {
                                                    distances.indices.contains(index) ? distances[index] : 0
                                                },
                                                set: { newValue in
                                                    if foerderstrecke == 1 {
                                                        if distances1.indices.contains(index) {
                                                            distances1[index] = newValue
                                                        }
                                                    } else {
                                                        if distances2.indices.contains(index) {
                                                            distances2[index] = newValue
                                                        }
                                                    }
                                                    calculateTotalDistance()
                                                }
                                            ),
                        showArrow: index < fahrzeuge.count
                    )
                }
                .onMove { indices, newOffset in
                    if foerderstrecke == 1 {
                        orderedFahrzeuge1.move(fromOffsets: indices, toOffset: newOffset)
                        distances1.move(fromOffsets: indices, toOffset: newOffset)
                    } else {
                        orderedFahrzeuge2.move(fromOffsets: indices, toOffset: newOffset)
                        distances2.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    calculateTotalDistance()
                }
                
                // Einsatzstellenpumpe falls vorhanden
                if let esp = espFahrzeug {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Einsatzstellenpumpe")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        
                        FeuerwehrRowView(
                            fahrzeug: esp.fahrzeug,
                            feuerwehrName: esp.feuerwehrName,
                            index: 0,
                            distance: $espDistance, // Bindung an den ESP Abstand
                            showArrow: true
                        )
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .listRowSeparator(.hidden)
                }
                
                // Übergabe an Einsatzstelle
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Übergabe an Einsatzstelle")
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .listRowSeparator(.hidden)
            }
            .environment(\.editMode, .constant(.active))
            .frame(minHeight: 400)
            
            // In der Button-Action, wo der PDF-Generator aufgerufen wird:
            Button("PDF erstellen und teilen (Förderstrecke \(foerderstrecke))") {
                let andereFoerderstrecke = foerderstrecke == 1 ? 2 : 1
                let andereFahrzeuge = andereFoerderstrecke == 1 ? orderedFahrzeuge1 : orderedFahrzeuge2
                let andereFoerderstreckeFahrzeug = andereFahrzeuge.last
                
                if let url = PDFGenerator.generateCombinedPDF(
                    for: fahrzeuge,
                    distances: distances,
                    foerderstrecke: foerderstrecke,
                    funkrufgruppe: funkrufgruppe.wrappedValue,
                    espFahrzeug: espFahrzeug,
                    andereFoerderstreckeFahrzeug: andereFoerderstreckeFahrzeug,
                    espDistance: espDistance
                ) {
                    if foerderstrecke == 1 {
                        pdfURL1 = IdentifiableURL(url: url)
                    } else {
                        pdfURL2 = IdentifiableURL(url: url)
                    }
                }
            }
            .disabled(!canGeneratePDF(for: foerderstrecke))
            .opacity(canGeneratePDF(for: foerderstrecke) ? 1 : 0.6)
            .padding()
            .frame(maxWidth: .infinity)
            .background((fahrzeuge.isEmpty && espFahrzeug == nil) ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .sheet(item: pdfURL) { identifiableURL in
                ShareSheet(activityItems: [identifiableURL.url])
            }
        }
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .shadow(radius: 3)
    }
    
    private func updateFahrzeugeLists() {
        let previousDistances1 = distances1
        let previousDistances2 = distances2
        
        // Finde die Einsatzstellenpumpe (falls vorhanden)
        espFahrzeug = feuerwehren
            .filter { selectedFeuerwehren.contains($0.id) }
            .flatMap { feuerwehr in
                feuerwehr.fahrzeuge
                    .filter { $0.isSelected && $0.foerderstrecke == 3 }
                    .map { (fahrzeug: $0, feuerwehrName: feuerwehr.name) }
            }
            .first
        
        orderedFahrzeuge1 = feuerwehren
            .filter { selectedFeuerwehren.contains($0.id) }
            .flatMap { feuerwehr in
                feuerwehr.fahrzeuge
                    .filter { $0.isSelected && $0.foerderstrecke == 1 }
                    .map { (fahrzeug: $0, feuerwehrName: feuerwehr.name) }
            }
        
        orderedFahrzeuge2 = feuerwehren
            .filter { selectedFeuerwehren.contains($0.id) }
            .flatMap { feuerwehr in
                feuerwehr.fahrzeuge
                    .filter { $0.isSelected && $0.foerderstrecke == 2 }
                    .map { (fahrzeug: $0, feuerwehrName: feuerwehr.name) }
            }
        
        distances1 = Array(0..<orderedFahrzeuge1.count).map {
            $0 < previousDistances1.count ? previousDistances1[$0] : 0
        }
        distances2 = Array(0..<orderedFahrzeuge2.count).map {
            $0 < previousDistances2.count ? previousDistances2[$0] : 0
        }
        
        calculateTotalDistance()
    }
    
    // Neue Berechnung der Gesamtstrecke in WasserfoerderstreckeView
    private func calculateTotalDistance() {
        // Vorherige Berechnung
        totalDistance1 = distances1.reduce(0, +)
        totalDistance2 = distances2.reduce(0, +)
        
        // ESP-Distanz hinzufügen WENN ESP existiert UND Fahrzeuge in der Strecke sind
        if espFahrzeug != nil {
            if !orderedFahrzeuge1.isEmpty {
                totalDistance1 += espDistance
            }
            if !orderedFahrzeuge2.isEmpty {
                totalDistance2 += espDistance
            }
        }
    }
    
    // Prüft ob PDF-Erstellung möglich ist
        private func canGeneratePDF(for foerderstrecke: Int) -> Bool {
            let fahrzeuge = foerderstrecke == 1 ? orderedFahrzeuge1 : orderedFahrzeuge2
            let hasESP = espFahrzeug != nil
            
            // Ungültige Fälle:
            // 1. Nur ESP vorhanden (keine anderen Fahrzeuge)
            // 2. Gar keine Fahrzeuge
            if (fahrzeuge.isEmpty && hasESP) ||  // Nur ESP
               (fahrzeuge.isEmpty && !hasESP) {  // Gar nichts
                return false
            }
            
            // Gültige Fälle:
            // 1. Mindestens 1 Fahrzeug (egal ob mit oder ohne ESP)
            // 2. ESP mit mindestens 1 Fahrzeug
            return true
        }
}
