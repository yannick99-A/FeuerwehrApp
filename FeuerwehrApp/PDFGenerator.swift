import Foundation
import UIKit
import PencilKit

struct PDFGenerator {
    static func generateCombinedPDF(
        for fahrzeuge: [(fahrzeug: Fahrzeug, feuerwehrName: String)],
        distances: [Int],
        foerderstrecke: Int,
        funkrufgruppe: String,
        espFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)?,
        andereFoerderstreckeFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)?,
        espDistance: Int
    ) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let datum = dateFormatter.string(from: Date())
        
        let pdfData = renderer.pdfData { context in
            // 1. Wasserentnahmeseite (nur erste Feuerwehr)
            var yPosition: CGFloat = 50
            context.beginPage()
            drawWaterIntakePage(context: context,
                              fahrzeuge: fahrzeuge,
                              distances: distances,
                              foerderstrecke: foerderstrecke,
                              funkrufgruppe: funkrufgruppe,
                              datum: datum,
                              yPosition: &yPosition,
                              highlightedIndex: 1,
                              espFahrzeug: nil)
            
            // 2. Mittlere Seiten
            for index in 1..<fahrzeuge.count {
                yPosition = 50
                context.beginPage()
                drawMiddlePage(context: context,
                             fahrzeuge: fahrzeuge,
                             distances: distances,
                             currentIndex: index,
                             foerderstrecke: foerderstrecke,
                             funkrufgruppe: funkrufgruppe,
                             datum: datum,
                             yPosition: &yPosition,
                             highlightedIndex: index + 1,
                             espFahrzeug: espFahrzeug)
            }
            
            // 3. ESP-Seite falls vorhanden (vor der Zusammenfassung)
                       if let esp = espFahrzeug {
                           yPosition = 50
                           context.beginPage()
                           drawESPPage(context: context,
                                     fahrzeuge: fahrzeuge,
                                     espFahrzeug: esp,
                                     foerderstrecke: foerderstrecke,
                                     funkrufgruppe: funkrufgruppe,
                                     datum: datum,
                                     yPosition: &yPosition,
                                     andereFoerderstreckeFahrzeug: andereFoerderstreckeFahrzeug)
                       }
            
            // 4. Zusammenfassungsseite(n)
            drawSummaryPages(context: context,
                           fahrzeuge: fahrzeuge,
                           distances: distances,
                           foerderstrecke: foerderstrecke,
                           funkrufgruppe: funkrufgruppe,
                           datum: datum,
                           espFahrzeug: espFahrzeug,
                           espDistance: espDistance)
        }
        
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pdfURL = documentDirectory.appendingPathComponent("Wasserfoerderstrecke_\(foerderstrecke).pdf")
            do {
                try pdfData.write(to: pdfURL)
                return pdfURL
            } catch {
                print("Fehler beim Speichern der PDF-Datei: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    // MARK: - Wasserentnahmeseite (nur erste Feuerwehr)
    private static func drawWaterIntakePage(context: UIGraphicsPDFRendererContext,
                                          fahrzeuge: [(fahrzeug: Fahrzeug, feuerwehrName: String)],
                                          distances: [Int],
                                          foerderstrecke: Int,
                                          funkrufgruppe: String,
                                          datum: String,
                                          yPosition: inout CGFloat,
                                          highlightedIndex: Int,
                                          espFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)?) {
        // Kopfbereich
        drawHeader(foerderstrecke: foerderstrecke,
                  funkrufgruppe: funkrufgruppe,
                  datum: datum,
                  yPosition: &yPosition)
        
        // Wasserentnahme Überschrift
        drawText(text: "WASSERENTNAHME", x: 200, y: yPosition, font: .boldSystemFont(ofSize: 24), color: .blue)
        yPosition += 40
        
        // Eigene Feuerwehr (Wasserentnahme) - hervorgehoben
        drawPosition(index: 1, x: 50, y: yPosition, highlight: highlightedIndex == 1)
        drawText(text: "\(fahrzeuge[0].feuerwehrName) - \(fahrzeuge[0].fahrzeug.typ) (\(fahrzeuge[0].fahrzeug.funkrufname))",
                x: 100, y: yPosition, font: .boldSystemFont(ofSize: 20))
        yPosition += 50
        
        // Großer Pfeil mit Abstand
        drawArrowWithDistance(x: 70, y: yPosition, distance: distances[0])
        yPosition += 80
        
        // Nächste Feuerwehr - nicht hervorgehoben
        if fahrzeuge.count > 1 {
            drawPosition(index: 2, x: 50, y: yPosition, highlight: highlightedIndex == 2)
            drawText(text: "\(fahrzeuge[1].feuerwehrName) - \(fahrzeuge[1].fahrzeug.typ) (\(fahrzeuge[1].fahrzeug.funkrufname))",
                    x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16))
            yPosition += 40
        }
    }
    
    // MARK: - Mittlere Seiten (3 Feuerwehren)
    private static func drawMiddlePage(context: UIGraphicsPDFRendererContext,
                                     fahrzeuge: [(fahrzeug: Fahrzeug, feuerwehrName: String)],
                                     distances: [Int],
                                     currentIndex: Int,
                                     foerderstrecke: Int,
                                     funkrufgruppe: String,
                                     datum: String,
                                     yPosition: inout CGFloat,
                                     highlightedIndex: Int,
                                     espFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)?) {
        // Kopfbereich
        drawHeader(foerderstrecke: foerderstrecke,
                  funkrufgruppe: funkrufgruppe,
                  datum: datum,
                  yPosition: &yPosition)
        
        // Vorherige Feuerwehr (Wasserquelle) - nicht hervorgehoben
        drawText(text: "Wasser bekommen von:", x: 50, y: yPosition, font: .systemFont(ofSize: 14))
        yPosition += 25
        
        drawPosition(index: currentIndex, x: 50, y: yPosition, highlight: highlightedIndex == currentIndex)
        drawText(text: "\(fahrzeuge[currentIndex-1].feuerwehrName) - \(fahrzeuge[currentIndex-1].fahrzeug.typ) (\(fahrzeuge[currentIndex-1].fahrzeug.funkrufname))",
                x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16))
        yPosition += 40
        
        // Pfeil mit Abstand
        drawArrowWithDistance(x: 70, y: yPosition, distance: distances[currentIndex-1])
        yPosition += 80
        
        // Eigene Feuerwehr (hervorgehoben)
        drawPosition(index: currentIndex+1, x: 50, y: yPosition, highlight: highlightedIndex == currentIndex+1)
        drawText(text: "\(fahrzeuge[currentIndex].feuerwehrName) - \(fahrzeuge[currentIndex].fahrzeug.typ) (\(fahrzeuge[currentIndex].fahrzeug.funkrufname))",
                x: 100, y: yPosition, font: .boldSystemFont(ofSize: 20))
        yPosition += 50
        
        // Pfeil mit Abstand
        drawArrowWithDistance(x: 70, y: yPosition, distance: distances[currentIndex])
        yPosition += 80
        
        // Nächste Feuerwehr oder ESP
        if currentIndex < fahrzeuge.count - 1 {
            drawText(text: "Wasser abgeben an:", x: 50, y: yPosition, font: .systemFont(ofSize: 14))
            yPosition += 25
            
            drawPosition(index: currentIndex+2, x: 50, y: yPosition, highlight: highlightedIndex == currentIndex+2)
            drawText(text: "\(fahrzeuge[currentIndex+1].feuerwehrName) - \(fahrzeuge[currentIndex+1].fahrzeug.typ) (\(fahrzeuge[currentIndex+1].fahrzeug.funkrufname))",
                    x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16))
        } else if let esp = espFahrzeug {
            drawText(text: "Wasser abgeben an:", x: 50, y: yPosition, font: .systemFont(ofSize: 14))
            yPosition += 25
            
            drawText(text: "Einsatzstellenpumpe: \(esp.feuerwehrName) - \(esp.fahrzeug.typ) (\(esp.fahrzeug.funkrufname))",
                    x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16), color: .blue)
        } else {
            drawText(text: "Einsatzstelle",
                    x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16))
        }
        yPosition += 40
    }
    
    // MARK: - ESP-Seite
    private static func drawESPPage(context: UIGraphicsPDFRendererContext,
                                  fahrzeuge: [(fahrzeug: Fahrzeug, feuerwehrName: String)],
                                  espFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String),
                                  foerderstrecke: Int,
                                  funkrufgruppe: String,
                                  datum: String,
                                  yPosition: inout CGFloat,
                                  andereFoerderstreckeFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)?) {
        // Kopfbereich
        drawHeader(foerderstrecke: foerderstrecke,
                  funkrufgruppe: funkrufgruppe,
                  datum: datum,
                  yPosition: &yPosition)
        
        // ESP Überschrift
        drawText(text: "EINSATZSTELLENPUMPE", x: 180, y: yPosition, font: .boldSystemFont(ofSize: 24), color: .blue)
        yPosition += 40
        
        // ESP Fahrzeug
        drawText(text: "\(espFahrzeug.feuerwehrName) - \(espFahrzeug.fahrzeug.typ) (\(espFahrzeug.fahrzeug.funkrufname))",
                x: 100, y: yPosition, font: .boldSystemFont(ofSize: 20))
        yPosition += 50
        
        // Wasser bekommen von:
        drawText(text: "Empfängt Wasser von beiden Förderstrecken:", x: 50, y: yPosition, font: .systemFont(ofSize: 14))
        yPosition += 30
        
        // Letzte Fahrzeuge beider Förderstrecken
        if let letztesFahrzeug1 = fahrzeuge.last {
            drawText(text: "• Förderstrecke \(foerderstrecke): \(letztesFahrzeug1.feuerwehrName) - \(letztesFahrzeug1.fahrzeug.typ) (\(letztesFahrzeug1.fahrzeug.funkrufname))",
                    x: 70, y: yPosition, font: .boldSystemFont(ofSize: 16))
            yPosition += 30
        }
        
        if let andereFahrzeug = andereFoerderstreckeFahrzeug {
            drawText(text: "• Förderstrecke \(foerderstrecke == 1 ? 2 : 1): \(andereFahrzeug.feuerwehrName) - \(andereFahrzeug.fahrzeug.typ) (\(andereFahrzeug.fahrzeug.funkrufname))",
                    x: 70, y: yPosition, font: .boldSystemFont(ofSize: 16))
        } else {
            drawText(text: "• Förderstrecke \(foerderstrecke == 1 ? 2 : 1): [Keine Daten verfügbar]",
                    x: 70, y: yPosition, font: .boldSystemFont(ofSize: 16))
        }
        yPosition += 40
        
        // Pfeil zur Einsatzstelle
        drawText(text: "↓", x: 70, y: yPosition, font: .systemFont(ofSize: 48))
        yPosition += 60
        
        drawText(text: "Übergabe an Einsatzstelle",
                x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16))
    }
    
    // MARK: - Hilfsfunktionen
    private static func drawHeader(foerderstrecke: Int,
                                 funkrufgruppe: String,
                                 datum: String,
                                 yPosition: inout CGFloat) {
        drawText(text: "Wasserförderstrecke \(foerderstrecke) - Funkrufgruppe: \(funkrufgruppe)",
                x: 50, y: yPosition, font: .boldSystemFont(ofSize: 16))
        yPosition += 20
        
        drawText(text: "Erstellt am: \(datum)", x: 50, y: yPosition)
        yPosition += 40
    }
    
    private static func drawPosition(index: Int, x: CGFloat, y: CGFloat, highlight: Bool) {
        if highlight {
            let circleSize: CGFloat = 40
            let circleRect = CGRect(x: x, y: y, width: circleSize, height: circleSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let path = UIBezierPath(ovalIn: circleRect)
            UIColor.blue.setFill()
            path.fill()
            UIColor.black.setStroke()
            path.lineWidth = 3
            path.stroke()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white
            ]
            "\(index)".draw(in: circleRect.insetBy(dx: 0, dy: 9), withAttributes: attributes)
        } else {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
            "\(index)".draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
    
    private static func drawPositionCircle(index: Int, x: CGFloat, y: CGFloat, highlight: Bool = false) {
        let circleSize: CGFloat = highlight ? 40 : 30
        let fontSize: CGFloat = highlight ? 18 : 14
        let lineWidth: CGFloat = highlight ? 3 : 2
        
        let circleRect = CGRect(x: x, y: y-5, width: circleSize, height: circleSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: highlight ? UIColor.white : UIColor.black
        ]
        
        let path = UIBezierPath(ovalIn: circleRect)
        (highlight ? UIColor.blue : UIColor.white).setFill()
        path.fill()
        UIColor.black.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
        
        "\(index)".draw(in: circleRect.insetBy(dx: 0, dy: 5), withAttributes: attributes)
    }
    
    private static func drawArrowWithDistance(x: CGFloat, y: CGFloat, distance: Int) {
        let arrowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48),
            .foregroundColor: UIColor.black
        ]
        "↓".draw(at: CGPoint(x: x, y: y), withAttributes: arrowAttributes)
        
        let hoses = distance / 20
        let hoseText = hoses == 1 ? "B-Schlauch" : "B-Schläuche"
        let distanceText = "\(distance) m / \(hoses) \(hoseText)"
        
        let distanceAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        distanceText.draw(at: CGPoint(x: x+60, y: y+25), withAttributes: distanceAttributes)
    }
    
    private static func drawText(text: String, x: CGFloat, y: CGFloat,
                               font: UIFont = .systemFont(ofSize: 12),
                               color: UIColor = .black) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
    }

    private static func drawSummaryPages(context: UIGraphicsPDFRendererContext,
                                       fahrzeuge: [(fahrzeug: Fahrzeug, feuerwehrName: String)],
                                       distances: [Int],
                                       foerderstrecke: Int,
                                       funkrufgruppe: String,
                                       datum: String,
                                       espFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)?,
                                       espDistance: Int) {
        
        let maxEntriesPerPage = 4 // Weniger Einträge pro Seite für bessere Lesbarkeit
        var currentPageStart = 0
        var yPosition: CGFloat = 50
        
        while currentPageStart < fahrzeuge.count {
            context.beginPage()
            yPosition = 50
            
            // Kopfbereich auf jeder Seite
            drawHeader(foerderstrecke: foerderstrecke,
                      funkrufgruppe: funkrufgruppe,
                      datum: datum,
                      yPosition: &yPosition)
            
            // Überschrift nur auf erster Seite
            if currentPageStart == 0 {
                drawText(text: "ZUSAMMENFASSUNG - Förderstrecke \(foerderstrecke)",
                        x: 50, y: yPosition,
                        font: .boldSystemFont(ofSize: 18),
                        color: .blue)
                yPosition += 30
                
                // Gesamtstrecke nur auf erster Seite
                var totalDistance = distances.reduce(0, +)
                if espFahrzeug != nil {
                    totalDistance += espDistance
                }
                let totalHoses = totalDistance / 20
                let totalHoseText = totalHoses == 1 ? "B-Schlauch" : "B-Schläuche"
                drawText(text: "Gesamtlänge: \(totalDistance) Meter (\(totalHoses) \(totalHoseText))",
                        x: 50, y: yPosition,
                        font: .boldSystemFont(ofSize: 14))
                yPosition += 40
            }
            
            // Einträge für aktuelle Seite
            let currentPageEnd = min(currentPageStart + maxEntriesPerPage, fahrzeuge.count)
            for index in currentPageStart..<currentPageEnd {
                // Feuerwehr-Eintrag
                drawPositionCircle(index: index+1, x: 50, y: yPosition)
                drawText(text: "\(fahrzeuge[index].feuerwehrName) - \(fahrzeuge[index].fahrzeug.typ) (\(fahrzeuge[index].fahrzeug.funkrufname))",
                        x: 110, y: yPosition,
                        font: .systemFont(ofSize: 12))
                yPosition += 40
                
                // Pfeil und Abstand
                if index < fahrzeuge.count - 1 {
                    drawArrowWithDistance(x: 70, y: yPosition, distance: distances[index])
                    yPosition += 80
                }
                
                // Prüfen ob wir auf der letzten Seite sind
                if index == currentPageEnd - 1 && index == fahrzeuge.count - 1 {
                    // ESP-Eintrag auf letzter Seite
                    if let esp = espFahrzeug {
                        // Pfeil zur ESP
                        drawArrowWithDistance(x: 70, y: yPosition, distance: distances[index])
                        yPosition += 80
                        
                        // ESP Position
                        let espPosition = fahrzeuge.count + 1
                        drawPositionCircle(index: espPosition, x: 50, y: yPosition)
                        drawText(text: "Einsatzstellenpumpe: \(esp.feuerwehrName) - \(esp.fahrzeug.typ) (\(esp.fahrzeug.funkrufname))",
                                x: 110, y: yPosition,
                                font: .systemFont(ofSize: 12))
                        yPosition += 40
                        
                        // Pfeil zur Einsatzstelle
                        drawArrowWithDistance(x: 70, y: yPosition, distance: espDistance)
                        yPosition += 80
                        
                        // Einsatzstelle
                        drawText(text: "Übergabe an Einsatzstelle",
                                x: 110, y: yPosition,
                                font: .systemFont(ofSize: 12))
                        yPosition += 40
                    } else {
                        // Keine ESP - normale Übergabe
                        drawFinalTransferArrow(x: 70, y: yPosition, distance: distances.last ?? 0)
                        yPosition += 100
                    }
                }
                
                // Seitenumbruch prüfen
                if yPosition > 700 && index < currentPageEnd - 1 {
                    break
                }
            }
            
            currentPageStart = currentPageEnd
        }
    }

    private static func drawFinalTransferArrow(x: CGFloat, y: CGFloat, distance: Int) {
        "↓".draw(at: CGPoint(x: x, y: y),
                 withAttributes: [
                    .font: UIFont.systemFont(ofSize: 48),
                    .foregroundColor: UIColor.black
                 ])
        
        let hoses = distance / 20
        let hoseText = hoses == 1 ? "B-Schlauch" : "B-Schläuche"
        let distanceText = "\(distance) m / \(hoses) \(hoseText)"
        
        distanceText.draw(at: CGPoint(x: x + 60, y: y + 15),
                         withAttributes: [
                            .font: UIFont.boldSystemFont(ofSize: 14),
                            .foregroundColor: UIColor.black
                         ])
        
        "Übergabe an Einsatzstelle".draw(at: CGPoint(x: x - 10, y: y + 60),
                                        withAttributes: [
                                            .font: UIFont.boldSystemFont(ofSize: 14),
                                            .foregroundColor: UIColor.black
                                        ])
    }
}

extension PDFGenerator {
    static func generateFeuerwehrUebersichtPDF(
        feuerwehren: [Feuerwehr],
        selectedFeuerwehren: Set<UUID>,
        includeInactiveVehicles: Bool = false,
        espFahrzeug: (fahrzeug: Fahrzeug, feuerwehrName: String)? = nil
    ) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let datum = dateFormatter.string(from: Date())
        
        let filteredFeuerwehren = feuerwehren.filter { selectedFeuerwehren.contains($0.id) }
        
        let gesamtBesatzung = filteredFeuerwehren
            .flatMap { $0.fahrzeuge }
            .filter { includeInactiveVehicles || $0.isSelected }
            .reduce(0) { $0 + $1.besatzung }
        
        let gesamtAGT = filteredFeuerwehren
            .flatMap { $0.fahrzeuge }
            .filter { includeInactiveVehicles || $0.isSelected }
            .reduce(0) { $0 + $1.agtTraeger }
        
        let pdfData = renderer.pdfData { context in
            var yPosition: CGFloat = 50
            
            context.beginPage()
            drawHeader(title: "Feuerwehr-Übersicht", datum: datum, yPosition: &yPosition)
            
            if let esp = espFahrzeug {
                drawText(text: "Einsatzstellenpumpe: \(esp.feuerwehrName) - \(esp.fahrzeug.typ)",
                        x: 50, y: yPosition,
                        font: .boldSystemFont(ofSize: 14),
                        color: .blue)
                yPosition += 30
            }
            
            drawText(text: "Gesamtbesatzung: \(gesamtBesatzung)",
                    x: 50, y: yPosition,
                    font: .boldSystemFont(ofSize: 16))
            yPosition += 25
            
            drawText(text: "Gesamt-AGT-Träger: \(gesamtAGT)",
                    x: 50, y: yPosition,
                    font: .boldSystemFont(ofSize: 16))
            yPosition += 20
            
            let berechnungHinweis = includeInactiveVehicles
                ? "Berechnung inkl. aller Fahrzeuge"
                : "Berechnung nur aktiver Fahrzeuge"
            drawText(text: berechnungHinweis,
                    x: 50, y: yPosition,
                    font: .italicSystemFont(ofSize: 12),
                    color: .gray)
            yPosition += 40
            
            for feuerwehr in filteredFeuerwehren {
                let fahrzeugeToShow = includeInactiveVehicles
                    ? feuerwehr.fahrzeuge
                    : feuerwehr.fahrzeuge.filter { $0.isSelected }
                
                if fahrzeugeToShow.isEmpty { continue }
                
                if yPosition > 650 {
                    context.beginPage()
                    yPosition = 50
                    drawHeader(title: "Feuerwehr-Übersicht (Fortsetzung)",
                             datum: datum,
                             yPosition: &yPosition)
                }
                
                drawText(text: "\(feuerwehr.name) - \(feuerwehr.ort)",
                        x: 50, y: yPosition,
                        font: .boldSystemFont(ofSize: 14),
                        color: .blue)
                yPosition += 25
                
                for fahrzeug in fahrzeugeToShow {
                    let statusText: String
                    let statusColor: UIColor
                    
                    if fahrzeug.foerderstrecke == 3 {
                        statusText = "Einsatzstellenpumpe"
                        statusColor = .systemBlue
                    } else {
                        statusText = fahrzeug.isSelected ? "Aktiv (Förderstrecke \(fahrzeug.foerderstrecke))" : "Nicht in Förderstrecke aktiv"
                        statusColor = fahrzeug.isSelected ? .systemGreen : .systemRed
                    }
                    
                    drawText(text: "\(fahrzeug.typ) (\(fahrzeug.funkrufname)) - \(statusText)",
                            x: 60, y: yPosition,
                            font: .systemFont(ofSize: 12),
                            color: statusColor)
                    yPosition += 20
                    
                    drawText(text: "  Besatzung: \(fahrzeug.besatzung)",
                            x: 80, y: yPosition)
                    drawText(text: "  AGT-Träger: \(fahrzeug.agtTraeger)",
                            x: 250, y: yPosition)
                    yPosition += 20
                    
                    if fahrzeug.isSelected && fahrzeug.foerderstrecke != 3 {
                        drawText(text: "  Förderstrecke: \(fahrzeug.foerderstrecke)",
                                x: 80, y: yPosition,
                                font: .systemFont(ofSize: 11),
                                color: .darkGray)
                        yPosition += 20
                    }
                }
                
                yPosition += 20
            }
        }
        
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pdfURL = documentDirectory.appendingPathComponent("Feuerwehr_Uebersicht.pdf")
            do {
                try pdfData.write(to: pdfURL)
                return pdfURL
            } catch {
                print("Fehler beim Speichern der PDF-Datei: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    private static func drawHeader(title: String, datum: String, yPosition: inout CGFloat) {
        drawText(text: title,
                x: 50, y: yPosition,
                font: .boldSystemFont(ofSize: 20))
        yPosition += 25
        
        drawText(text: "Erstellt am: \(datum)",
                x: 50, y: yPosition,
                font: .systemFont(ofSize: 12),
                color: .gray)
        yPosition += 40
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 50, y: yPosition))
        path.addLine(to: CGPoint(x: 562, y: yPosition))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        yPosition += 20
    }
}

extension PDFGenerator {
    static func generateNotesPDF(notes: [Note]) -> URL? {
        // Standard US Letter / A4-ähnliches Format
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy - HH:mm 'Uhr'"
        
        let pdfData = renderer.pdfData { context in
            var yPosition: CGFloat = 50
            let margin: CGFloat = 50
            let contentWidth = pageRect.width - 2 * margin
            
            context.beginPage()
            
            // Header
            drawText(text: "Notizen Übersicht", x: margin, y: yPosition, font: .boldSystemFont(ofSize: 24), color: .black)
            yPosition += 40
            
            // Chronologisch sortieren (Älteste zuerst, damit die Historie Sinn macht)
            let sortedNotes = notes.sorted(by: { $0.createdAt < $1.createdAt })
            
            for note in sortedNotes {
                // Seitenumbruch prüfen
                if yPosition > 700 {
                    context.beginPage()
                    yPosition = 50
                }
                
                // 1. Datum
                let dateString = dateFormatter.string(from: note.createdAt)
                drawText(text: dateString, x: margin, y: yPosition, font: .boldSystemFont(ofSize: 14), color: .blue)
                yPosition += 25
                
                // 2. Text
                if !note.text.isEmpty {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black
                    ]
                    
                    let maxSize = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
                    let textRect = note.text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
                    
                    // Seitenumbruch für Text prüfen
                    if yPosition + textRect.height > 740 {
                        context.beginPage()
                        yPosition = 50
                    }
                    
                    note.text.draw(in: CGRect(x: margin, y: yPosition, width: contentWidth, height: textRect.height), withAttributes: attributes)
                    yPosition += textRect.height + 15
                }
                
                // 3. Zeichnungen (PencilKit)
                if let drawingData = note.drawingData, let drawing = try? PKDrawing(data: drawingData) {
                    let drawingBounds = drawing.bounds
                    // Prüfen ob die Zeichnung Inhalte hat
                    if !drawingBounds.isEmpty && !drawingBounds.isInfinite {
                        let image = drawing.image(from: drawingBounds, scale: 2.0) // Scale für bessere Qualität
                        let aspectRatio = image.size.height / image.size.width
                        var drawHeight = contentWidth * aspectRatio
                        
                        // Höhe begrenzen, falls die Zeichnung extrem hoch ist
                        if drawHeight > 300 {
                            drawHeight = 300
                        }
                        
                        if yPosition + drawHeight > 740 {
                            context.beginPage()
                            yPosition = 50
                        }
                        
                        // Zentriert zeichnen
                        let drawWidth = drawHeight / aspectRatio
                        let xPos = margin + (contentWidth - drawWidth) / 2
                        
                        image.draw(in: CGRect(x: xPos, y: yPosition, width: drawWidth, height: drawHeight))
                        yPosition += drawHeight + 20
                    }
                }
                
                // 4. Bilder aus der Galerie/Kamera
                if let imagesData = note.imagesData {
                    for imageData in imagesData {
                        if let image = UIImage(data: imageData) {
                            let aspectRatio = image.size.height / image.size.width
                            var drawWidth = contentWidth
                            var drawHeight = contentWidth * aspectRatio
                            
                            // Bildgröße begrenzen, damit es nicht die ganze Seite sprengt
                            if drawHeight > 350 {
                                drawHeight = 350
                                drawWidth = drawHeight / aspectRatio
                            }
                            
                            if yPosition + drawHeight > 740 {
                                context.beginPage()
                                yPosition = 50
                            }
                            
                            // Bild zentrieren
                            let xPos = margin + (contentWidth - drawWidth) / 2
                            image.draw(in: CGRect(x: xPos, y: yPosition, width: drawWidth, height: drawHeight))
                            yPosition += drawHeight + 20
                        }
                    }
                }
                
                yPosition += 10
                
                // Trennlinie zwischen den Notizen
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: yPosition))
                path.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition))
                UIColor.lightGray.setStroke()
                path.lineWidth = 1
                path.stroke()
                yPosition += 25
            }
        }
        
        // Speichern der PDF
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pdfURL = documentDirectory.appendingPathComponent("Notizen_Historie.pdf")
            do {
                try pdfData.write(to: pdfURL)
                return pdfURL
            } catch {
                print("Fehler beim Speichern der PDF-Datei: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
}
