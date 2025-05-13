import SwiftUI

struct FeuerwehrView: View {
    @State private var feuerwehren: [Feuerwehr] = DataManager.shared.loadFeuerwehren()
    @State private var selectedFeuerwehren: Set<UUID> = Set()
    @State private var showEingabeMaske = false
    @State private var isCompact: Bool = UIDevice.current.userInterfaceIdiom == .phone
    
    var body: some View {
        TabView {
            // Tab 1: Feuerwehr
            Group {
                if isCompact {
                    NavigationStack {
                        FeuerwehrAuswahlView(
                            feuerwehren: $feuerwehren,
                            selectedFeuerwehren: $selectedFeuerwehren,
                            showEingabeMaske: $showEingabeMaske
                        )
                        .navigationTitle("FeuerwehrApp")
                        .navigationDestination(isPresented: .constant(!selectedFeuerwehren.isEmpty)) {
                            FeuerwehrAnzeigeView(
                                feuerwehren: $feuerwehren,
                                selectedFeuerwehren: $selectedFeuerwehren
                            )
                            .navigationTitle("Ausgewählte Feuerwehren")
                        }
                    }
                } else {
                    NavigationSplitView {
                        FeuerwehrAuswahlView(
                            feuerwehren: $feuerwehren,
                            selectedFeuerwehren: $selectedFeuerwehren,
                            showEingabeMaske: $showEingabeMaske
                        )
                        .navigationTitle("FeuerwehrApp")
                    } detail: {
                        FeuerwehrAnzeigeView(
                            feuerwehren: $feuerwehren,
                            selectedFeuerwehren: $selectedFeuerwehren
                        )
                    }
                }
            }
            .tabItem {
                Label("Feuerwehr", systemImage: "flame.fill")
            }
            
            // Tab 2: Wasserförderstrecke
            WasserfoerderstreckeView(feuerwehren: $feuerwehren, selectedFeuerwehren: $selectedFeuerwehren)
                .tabItem {
                    Label("Wasserförderstrecke", systemImage: "drop.fill")
                }
            
            // Tab 3: Karte
            FeuerwehrKarteView(feuerwehren: $feuerwehren, selectedFeuerwehren: $selectedFeuerwehren)
                .tabItem {
                    Label("Karte", systemImage: "map.fill")
                }
            
            // Tab 4: Notizen und Foto
            NotizenView()
                .tabItem {
                    Label("Notizen", systemImage: "note.text")
                }
            
            // Tab 5: Einstellungen
            NavigationView {
                FeuerwehrListeView(feuerwehren: $feuerwehren)
            }
            .tabItem {
                Label("Einstellungen", systemImage: "gear")
            }
        }
        .sheet(isPresented: $showEingabeMaske) {
            FeuerwehrEingabeView(feuerwehren: $feuerwehren, isPresented: $showEingabeMaske)
        }
        .onAppear {
            if selectedFeuerwehren.isEmpty {
                selectedFeuerwehren = Set(feuerwehren.map { $0.id })
            }
        }
        .onChange(of: feuerwehren) { _ in
            DataManager.shared.saveFeuerwehren(feuerwehren)
        }
    }
}
