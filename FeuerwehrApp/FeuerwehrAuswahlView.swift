import SwiftUI

// FeuerwehrAuswahlView.swift
struct FeuerwehrAuswahlView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @Binding var selectedFeuerwehren: Set<UUID>
    @Binding var showEingabeMaske: Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        List {
            // Ortsfeuerwehren
            Section(header: Text("Ortsfeuerwehren")) {
                ForEach(feuerwehren.filter { $0.gruppe == .ortsfeuerwehr }) { feuerwehr in
                    HStack {
                        Text(feuerwehr.name)
                        Spacer()
                        Image(systemName: selectedFeuerwehren.contains(feuerwehr.id) ? "checkmark.circle.fill" : "circle")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(for: feuerwehr.id)
                    }
                }
            }
            
            // Feuerwehrbereitschaft
            Section(header: Text("Feuerwehrbereitschaft")) {
                ForEach(feuerwehren.filter { $0.gruppe == .bereitschaft }) { feuerwehr in
                    HStack {
                        Text(feuerwehr.name)
                        Spacer()
                        Image(systemName: selectedFeuerwehren.contains(feuerwehr.id) ? "checkmark.circle.fill" : "circle")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(for: feuerwehr.id)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        
        Button("Feuerwehr hinzufügen") {
            showEingabeMaske = true
        }
        .padding()
        if horizontalSizeClass == .compact && !selectedFeuerwehren.isEmpty {
                        NavigationLink {
                            FeuerwehrAnzeigeView(
                                feuerwehren: $feuerwehren,
                                selectedFeuerwehren: $selectedFeuerwehren
                            )
                            .navigationTitle("Ausgewählte Feuerwehren")
                        } label: {
                            Text("Auswahl anzeigen")
                                .padding(.horizontal, 20) // Horizontaler Padding
                                                                .padding(.vertical, 10)   // Vertikaler Padding
                                                                .background(Color.blue)
                                                                .foregroundColor(.white)
                                                                .cornerRadius(10)
                                                                .fixedSize() // Wichtig: Verhindert Aufweitung
                                                        
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
    }
    
    private func toggleSelection(for id: UUID) {
        if selectedFeuerwehren.contains(id) {
            selectedFeuerwehren.remove(id)
        } else {
            selectedFeuerwehren.insert(id)
        }
    }
}
