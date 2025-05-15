import SwiftUI
import MapKit
import CoreLocation

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

class FeuerwehrKarteViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var annotationsStrecke1: [IdentifiablePointAnnotation] = []
    @Published var annotationsStrecke2: [IdentifiablePointAnnotation] = []
    @Published var routePolylineStrecke1: MKPolyline?
    @Published var routePolylineStrecke2: MKPolyline?
    @Published var routeDistanceStrecke1: CLLocationDistance = 0
    @Published var routeDistanceStrecke2: CLLocationDistance = 0
    @Published var currentFahrzeugIndexStrecke1: Int = 0
    @Published var currentFahrzeugIndexStrecke2: Int = 0
    @Published var fahrzeugeForStrecke1: [FahrzeugMitName] = []
    @Published var fahrzeugeForStrecke2: [FahrzeugMitName] = []
    @Published var showRouteStrecke1: Bool = true
    @Published var showRouteStrecke2: Bool = true

    struct FahrzeugMitName: Codable {
        let fahrzeug: Fahrzeug
        let feuerwehrName: String
    }

    private struct SavedState: Codable {
        let annotationsStrecke1: [IdentifiablePointAnnotation]
        let annotationsStrecke2: [IdentifiablePointAnnotation]
        let routePolylineStrecke1: [CLLocationCoordinate2D]?
        let routePolylineStrecke2: [CLLocationCoordinate2D]?
        let routeDistanceStrecke1: CLLocationDistance
        let routeDistanceStrecke2: CLLocationDistance
        let currentFahrzeugIndexStrecke1: Int
        let currentFahrzeugIndexStrecke2: Int
        let fahrzeugeForStrecke1: [FahrzeugMitName]
        let fahrzeugeForStrecke2: [FahrzeugMitName]
        let showRouteStrecke1: Bool
        let showRouteStrecke2: Bool
    }

    init() {
        loadState()
    }

    func saveState() {
        let state = SavedState(
            annotationsStrecke1: annotationsStrecke1,
            annotationsStrecke2: annotationsStrecke2,
            routePolylineStrecke1: routePolylineStrecke1?.coordinates,
            routePolylineStrecke2: routePolylineStrecke2?.coordinates,
            routeDistanceStrecke1: routeDistanceStrecke1,
            routeDistanceStrecke2: routeDistanceStrecke2,
            currentFahrzeugIndexStrecke1: currentFahrzeugIndexStrecke1,
            currentFahrzeugIndexStrecke2: currentFahrzeugIndexStrecke2,
            fahrzeugeForStrecke1: fahrzeugeForStrecke1,
            fahrzeugeForStrecke2: fahrzeugeForStrecke2,
            showRouteStrecke1: showRouteStrecke1,
            showRouteStrecke2: showRouteStrecke2
        )

        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: "kartenState_v2")
        }
    }

    func loadState() {
        guard let data = UserDefaults.standard.data(forKey: "kartenState_v2"),
              let decoded = try? JSONDecoder().decode(SavedState.self, from: data) else {
            return
        }

        annotationsStrecke1 = decoded.annotationsStrecke1
        annotationsStrecke2 = decoded.annotationsStrecke2
        routeDistanceStrecke1 = decoded.routeDistanceStrecke1
        routeDistanceStrecke2 = decoded.routeDistanceStrecke2
        currentFahrzeugIndexStrecke1 = decoded.currentFahrzeugIndexStrecke1
        currentFahrzeugIndexStrecke2 = decoded.currentFahrzeugIndexStrecke2
        fahrzeugeForStrecke1 = decoded.fahrzeugeForStrecke1
        fahrzeugeForStrecke2 = decoded.fahrzeugeForStrecke2
        showRouteStrecke1 = decoded.showRouteStrecke1
        showRouteStrecke2 = decoded.showRouteStrecke2

        if let coords1 = decoded.routePolylineStrecke1 {
            routePolylineStrecke1 = MKPolyline(coordinates: coords1, count: coords1.count)
        }
        if let coords2 = decoded.routePolylineStrecke2 {
            routePolylineStrecke2 = MKPolyline(coordinates: coords2, count: coords2.count)
        }
    }

    func toggleRouteVisibility(for strecke: Int) {
        if strecke == 1 {
            showRouteStrecke1.toggle()
        } else {
            showRouteStrecke2.toggle()
        }
        saveState()
    }

    func addAnnotation(at coordinate: CLLocationCoordinate2D, for strecke: Int) {
        if strecke == 1 {
            if currentFahrzeugIndexStrecke1 < fahrzeugeForStrecke1.count {
                let fahrzeug = fahrzeugeForStrecke1[currentFahrzeugIndexStrecke1]
                let annotation = IdentifiablePointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = currentFahrzeugIndexStrecke1 == 0
                    ? "Wasserentnahme: \(fahrzeug.feuerwehrName) - \(fahrzeug.fahrzeug.typ) (\(fahrzeug.fahrzeug.funkrufname))"
                    : "\(fahrzeug.feuerwehrName) - \(fahrzeug.fahrzeug.typ) (\(fahrzeug.fahrzeug.funkrufname))"
                annotationsStrecke1.append(annotation)
                currentFahrzeugIndexStrecke1 += 1
            } else {
                let annotation = IdentifiablePointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Einsatzstelle"
                annotationsStrecke1.append(annotation)
                currentFahrzeugIndexStrecke1 += 1
            }
            calculateRoute(for: 1)
        } else {
            if currentFahrzeugIndexStrecke2 < fahrzeugeForStrecke2.count {
                let fahrzeug = fahrzeugeForStrecke2[currentFahrzeugIndexStrecke2]
                let annotation = IdentifiablePointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = currentFahrzeugIndexStrecke2 == 0
                    ? "Wasserentnahme: \(fahrzeug.feuerwehrName) - \(fahrzeug.fahrzeug.typ) (\(fahrzeug.fahrzeug.funkrufname))"
                    : "\(fahrzeug.feuerwehrName) - \(fahrzeug.fahrzeug.typ) (\(fahrzeug.fahrzeug.funkrufname))"
                annotationsStrecke2.append(annotation)
                currentFahrzeugIndexStrecke2 += 1
            } else {
                let annotation = IdentifiablePointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Einsatzstelle"
                annotationsStrecke2.append(annotation)
                currentFahrzeugIndexStrecke2 += 1
            }
            calculateRoute(for: 2)
        }
        saveState()
    }

    func undoLastAnnotation(for strecke: Int) {
        if strecke == 1, !annotationsStrecke1.isEmpty {
            annotationsStrecke1.removeLast()
            currentFahrzeugIndexStrecke1 = max(0, currentFahrzeugIndexStrecke1 - 1)
            calculateRoute(for: 1)
        } else if strecke == 2, !annotationsStrecke2.isEmpty {
            annotationsStrecke2.removeLast()
            currentFahrzeugIndexStrecke2 = max(0, currentFahrzeugIndexStrecke2 - 1)
            calculateRoute(for: 2)
        }
        saveState()
    }

    func resetAnnotationsAndRoute(for strecke: Int) {
        if strecke == 1 {
            annotationsStrecke1.removeAll()
            currentFahrzeugIndexStrecke1 = 0
            routePolylineStrecke1 = nil
            routeDistanceStrecke1 = 0
        } else {
            annotationsStrecke2.removeAll()
            currentFahrzeugIndexStrecke2 = 0
            routePolylineStrecke2 = nil
            routeDistanceStrecke2 = 0
        }
        saveState()
    }

    func updateFahrzeugeForStrecke(feuerwehren: [Feuerwehr], selectedFeuerwehren: Set<UUID>, selectedStrecke: Int) {
        if selectedStrecke == 1 {
            fahrzeugeForStrecke1 = feuerwehren
                .filter { selectedFeuerwehren.contains($0.id) }
                .flatMap { feuerwehr in
                    feuerwehr.fahrzeuge
                        .filter { $0.isSelected && $0.foerderstrecke == 1 }
                        .map { FahrzeugMitName(fahrzeug: $0, feuerwehrName: feuerwehr.name) }
                }
        } else {
            fahrzeugeForStrecke2 = feuerwehren
                .filter { selectedFeuerwehren.contains($0.id) }
                .flatMap { feuerwehr in
                    feuerwehr.fahrzeuge
                        .filter { $0.isSelected && $0.foerderstrecke == 2 }
                        .map { FahrzeugMitName(fahrzeug: $0, feuerwehrName: feuerwehr.name) }
                }
        }
        saveState()
    }

    private func calculateRoute(for strecke: Int) {
        let annotations = strecke == 1 ? annotationsStrecke1 : annotationsStrecke2
        guard annotations.count >= 2 else {
            if strecke == 1 {
                routePolylineStrecke1 = nil
                routeDistanceStrecke1 = 0
            } else {
                routePolylineStrecke2 = nil
                routeDistanceStrecke2 = 0
            }
            return
        }

        var allCoordinates: [CLLocationCoordinate2D] = []
        var totalDistance: CLLocationDistance = 0
        let dispatchGroup = DispatchGroup()

        for i in 0..<annotations.count - 1 {
            let start = annotations[i].coordinate
            let end = annotations[i + 1].coordinate

            dispatchGroup.enter()
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
            request.transportType = .walking // oder .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                defer { dispatchGroup.leave() }

                if let route = response?.routes.first,
                   route.distance > 0,
                   route.polyline.pointCount > 1 {
                    allCoordinates.append(contentsOf: route.polyline.coordinates)
                    totalDistance += route.distance
                } else {
                    print("❗️ Segment \(i) konnte nicht berechnet werden.")
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if allCoordinates.count > 1 {
                let fullPolyline = MKPolyline(coordinates: allCoordinates, count: allCoordinates.count)

                if strecke == 1 {
                    self.routePolylineStrecke1 = fullPolyline
                    self.routeDistanceStrecke1 = totalDistance
                } else {
                    self.routePolylineStrecke2 = fullPolyline
                    self.routeDistanceStrecke2 = totalDistance
                }
            } else {
                if strecke == 1 {
                    self.routePolylineStrecke1 = nil
                    self.routeDistanceStrecke1 = 0
                } else {
                    self.routePolylineStrecke2 = nil
                    self.routeDistanceStrecke2 = 0
                }
            }

            self.saveState()
        }
    }

}
