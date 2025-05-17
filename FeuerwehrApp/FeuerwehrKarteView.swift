import SwiftUI
import MapKit
import CoreLocation

struct FeuerwehrKarteView: View {
    @Binding var feuerwehren: [Feuerwehr]
    @Binding var selectedFeuerwehren: Set<UUID>
    
    @StateObject private var viewModel = FeuerwehrKarteViewModel()
    @State private var selectedStrecke: Int = 1
    @StateObject private var locationManager = LocationManager()
    @State private var trackingMode: MKUserTrackingMode = .follow
    @State private var showAlert = false
    @State private var mapType: MKMapType = .standard
    @State private var showHelpPopup = false
    
    // Computed property für die aktuelle Route
    private var currentRoutePolyline: Binding<MKPolyline?> {
        Binding<MKPolyline?>(
            get: {
                if selectedStrecke == 1 {
                    return viewModel.showRouteStrecke1 ? viewModel.routePolylineStrecke1 : nil
                } else {
                    return viewModel.showRouteStrecke2 ? viewModel.routePolylineStrecke2 : nil
                }
            },
            set: { _ in }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Streckenauswahl
            HStack {
                Button(action: {
                    selectedStrecke = 1
                }) {
                    Text("Strecke 1")
                        .padding()
                        .background(selectedStrecke == 1 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    selectedStrecke = 2
                }) {
                    Text("Strecke 2")
                        .padding()
                        .background(selectedStrecke == 2 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            
            // Kartenbereich
            ZStack(alignment: .bottomTrailing) {
                            CustomMapView(
                                region: $viewModel.region,
                                annotations: selectedStrecke == 1 ? $viewModel.annotationsStrecke1 : $viewModel.annotationsStrecke2,
                                routePolyline: currentRoutePolyline,
                                trackingMode: $trackingMode,
                                mapType: $mapType, // Neue Binding-Variable
                                onLongPress: { coordinate in
                                    handleLongPress(at: coordinate)
                                }
                            )
                .alert("Standort nicht verfügbar", isPresented: $showAlert) {
                    Button("OK") { }
                } message: {
                    Text("Bitte aktivieren Sie Standortdienste in den Einstellungen.")
                }
                
                // Steuerungsbuttons
                VStack(spacing: 10) {
                    Button(action: {
                        viewModel.resetAnnotationsAndRoute(for: selectedStrecke)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.red)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    
                    Button(action: {
                        viewModel.undoLastAnnotation(for: selectedStrecke)
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.orange)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    
                    Button(action: toggleUserTracking) {
                        Image(systemName: trackingMode == .followWithHeading ? "location.north.line.fill" :
                              trackingMode == .follow ? "location.fill" : "location")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    
                    Button(action: {
                        viewModel.toggleRouteVisibility(for: selectedStrecke)
                    }) {
                        Image(systemName: selectedStrecke == 1 ?
                              (viewModel.showRouteStrecke1 ? "eye.slash" : "eye") :
                              (viewModel.showRouteStrecke2 ? "eye.slash" : "eye"))
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    Button(action: {
                        mapType = mapType == .standard ? .hybrid : .standard
                    }) {
                        Image(systemName: mapType == .standard ? "map.fill" : "map")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    
                    Button(action: {
                                            showHelpPopup = true
                                        }) {
                                            Image(systemName: "questionmark.circle.fill")
                                                .font(.system(size: 20))
                                                .frame(width: 44, height: 44)
                                                .background(Color.white.opacity(0.9))
                                                .foregroundColor(.blue)
                                                .clipShape(Circle())
                                                .shadow(radius: 3)
                                        }
                }
                .padding(.trailing, 10)
                .padding(.bottom, 30)
            }
            
            // Routeninformation
            Text("Strecke \(selectedStrecke): \(String(format: "%.1f", selectedStrecke == 1 ? viewModel.routeDistanceStrecke1 : viewModel.routeDistanceStrecke2)) Meter")
                .font(.headline)
                .padding()
        }
        .navigationTitle("Kartenansicht")
        .onAppear {
            checkLocationAuthorization()
            viewModel.loadState()
            viewModel.updateFahrzeugeForStrecke(
                feuerwehren: feuerwehren,
                selectedFeuerwehren: selectedFeuerwehren,
                selectedStrecke: selectedStrecke
            )
            
            if locationManager.isLocationAuthorized {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    centerMapOnUserLocation()
                }
            }
        }
        .onChange(of: selectedFeuerwehren) { _ in
            viewModel.updateFahrzeugeForStrecke(
                feuerwehren: feuerwehren,
                selectedFeuerwehren: selectedFeuerwehren,
                selectedStrecke: selectedStrecke
            )
        }
        .navigationTitle("Kartenansicht")
                .sheet(isPresented: $showHelpPopup) {
                    HilfePopupView()
                }
    }
    
    private func handleLongPress(at coordinate: CLLocationCoordinate2D) {
        trackingMode = .none
        viewModel.addAnnotation(at: coordinate, for: selectedStrecke)
    }
    
    private func toggleUserTracking() {
        guard locationManager.isLocationAuthorized else {
            showAlert = true
            return
        }
        
        withAnimation {
            switch trackingMode {
            case .none:
                trackingMode = .follow
                centerMapOnUserLocation()
            case .follow:
                trackingMode = .followWithHeading
            case .followWithHeading:
                trackingMode = .none
            @unknown default:
                trackingMode = .none
            }
        }
    }
    
    private func centerMapOnUserLocation() {
        if let location = locationManager.userLocation {
            viewModel.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func checkLocationAuthorization() {
        if !locationManager.isLocationAuthorized {
            showAlert = true
        }
    }
}
// Korrigierte HilfePopupView
struct HilfePopupView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Wegpunkte setzen")
                .font(.title2.bold())
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                InfoStepView(icon: "1.circle", text: "Wähle eine Förderstrecke (1 oder 2) aus.")
                InfoStepView(icon: "hand.tap.fill", text: "Langer Druck auf die Karte setzt Wegpunkte.")
                InfoStepView(icon: "arrow.right", text: "Reihenfolge laut Wasserförderstrecke-Tab:")
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("1. Wasserentnahmestelle")
                    Text("2. Förderfahrzeuge")
                    Text("3. Einsatzstelle")
                }
                .padding(.leading, 30)
                
                InfoStepView(icon: "arrow.uturn.backward", text: "Mit dem Zurück-Button wird der zuletzt gesetzte Punkt entfernt.")
                InfoStepView(icon: "arrow.clockwise", text: "Reset-Button löscht alle Punkte der aktuellen Strecke.")
                InfoStepView(icon: "eye.fill", text: "Die automatisch berechnete Route lässt sich ein- und ausblenden.")
            }
            
            Button("Verstanden") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
        .padding(.horizontal)
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
    }
}


// Hilfs-View für einheitliche Schritt-Darstellung
struct InfoStepView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}
