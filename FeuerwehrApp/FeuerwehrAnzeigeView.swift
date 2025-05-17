import SwiftUI

struct FeuerwehrAnzeigeView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @Binding var selectedFeuerwehren: Set<UUID>
    @State private var pdfURL: IdentifiableURL?
    @State private var includeAllVehicles = true
    
    var body: some View {
        ZStack(alignment: .top) {
            // Hintergrund-ScrollView
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Platzhalter für die Höhe des fixierten Headers
                    Spacer()
                        .frame(height: 5) // Höher wegen zusätzlichem Toggle im Header
                    
                    if selectedFeuerwehren.isEmpty {
                        // Platzhalter-Text wenn keine Auswahl
                        VStack(spacing: 20) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("Keine Feuerwehr ausgewählt")
                                .font(.title2)
                                .bold()
                            
                            Text("Wähle Feuerwehren in der Sidebar aus oder fügen neue hinzu.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                    } else {
                        // Bestehende Ansicht wenn Auswahl vorhanden
                        ForEach(feuerwehren.filter { selectedFeuerwehren.contains($0.id) }) { feuerwehr in
                            EinzelneFeuerwehrView(
                                feuerwehr: binding(for: feuerwehr),
                                feuerwehren: $feuerwehren
                            )
                        }
                        
                        Button("PDF erstellen und teilen") {
                            if let url = PDFGenerator.generateFeuerwehrUebersichtPDF(
                                feuerwehren: feuerwehren,
                                selectedFeuerwehren: selectedFeuerwehren,
                                includeInactiveVehicles: includeAllVehicles // Hier den Toggle-State übergeben
                            ) {
                                pdfURL = IdentifiableURL(url: url)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .sheet(item: $pdfURL) { identifiableURL in
                            ShareSheet(activityItems: [identifiableURL.url])
                        }
                    }
                }
                .padding()
                .padding(.top, 120) // Mehr Padding oben wegen größerem Header
            }
            
            // Fixierter Header mit Toggle
            if !selectedFeuerwehren.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text("Gesamtbesatzung: \(gesamtBesatzungBerechnen())")
                        Spacer()
                        Text("Gesamt-AGT: \(gesamtAGTBerechnen())")
                    }
                    .font(.headline)
                    
                    HStack {
                        Toggle(isOn: $includeAllVehicles) {
                            Text(includeAllVehicles ? "Alle Fahrzeuge einbeziehen" : "Nur aktivierte Fahrzeuge einbeziehen")
                                .font(.subheadline)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .shadow(radius: 2)
            }
        }
    }
    
    private func binding(for feuerwehr: Feuerwehr) -> Binding<Feuerwehr> {
            guard let index = feuerwehren.firstIndex(where: { $0.id == feuerwehr.id }) else {
                fatalError("Feuerwehr nicht gefunden")
            }
            return $feuerwehren[index]
        }
        
        private func gesamtBesatzungBerechnen() -> Int {
            return feuerwehren
                .filter { selectedFeuerwehren.contains($0.id) }
                .flatMap { $0.fahrzeuge }
                .filter { includeAllVehicles || $0.isSelected }
                .reduce(0) { $0 + $1.besatzung }
        }
        
        private func gesamtAGTBerechnen() -> Int {
            return feuerwehren
                .filter { selectedFeuerwehren.contains($0.id) }
                .flatMap { $0.fahrzeuge }
                .filter { includeAllVehicles || $0.isSelected }
                .reduce(0) { $0 + $1.agtTraeger }
        }
}
