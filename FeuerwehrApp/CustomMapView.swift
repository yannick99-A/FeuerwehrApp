import SwiftUI
import MapKit

struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var annotations: [IdentifiablePointAnnotation]
    @Binding var routePolyline: MKPolyline?
    @Binding var trackingMode: MKUserTrackingMode
    @Binding var mapType: MKMapType // Neue Property für den Kartenstil
    var onLongPress: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = trackingMode
        mapView.mapType = mapType // Kartenstil setzen
        
        // Long-Press-Gesture korrekt hinzufügen
        let longPressRecognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPressRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecognizer)
        
        // Priorität der Gestures anpassen
        if let existingGestures = mapView.gestureRecognizers {
            for gesture in existingGestures {
                gesture.require(toFail: longPressRecognizer)
            }
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }
        // Annotations aktualisieren
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)
        
        // Route aktualisieren
        uiView.removeOverlays(uiView.overlays)
        if let routePolyline = routePolyline {
            uiView.addOverlay(routePolyline)
        }
        
        // Tracking-Modus synchronisieren
        if uiView.userTrackingMode != trackingMode {
            uiView.userTrackingMode = trackingMode
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            
            let mapView = gesture.view as! MKMapView
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // Temporär Tracking deaktivieren
            mapView.userTrackingMode = .none
            parent.trackingMode = .none
            
            // Long-Press-Handler aufrufen
            parent.onLongPress(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            // Tracking-Status synchron halten
            DispatchQueue.main.async {
                self.parent.trackingMode = mode
            }
        }
    }
}
