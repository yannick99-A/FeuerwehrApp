import Foundation
import UIKit

struct PDFGenerator {
    static func generateCombinedPDF(for fahrzeuge: [(fahrzeug: Fahrzeug, feuerwehrName: String)],
                                  distances: [Int],
                                  foerderstrecke: Int,
                                  funkrufgruppe: String) -> URL? {
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
                              highlightedIndex: 1) // Nur Position 1 ist hervorgehoben
            
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
                             highlightedIndex: index + 1) // Nur die aktuelle Position ist hervorgehoben
            }
            
            // 3. Zusammenfassungsseite(n)
            drawSummaryPages(context: context,
                           fahrzeuge: fahrzeuge,
                           distances: distances,
                           foerderstrecke: foerderstrecke,
                           funkrufgruppe: funkrufgruppe,
                           datum: datum)
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
                                          highlightedIndex: Int) {
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
                                     highlightedIndex: Int) {
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
        
        // Nächste Feuerwehr oder Einsatzstelle - nicht hervorgehoben
        if currentIndex < fahrzeuge.count - 1 {
            drawText(text: "Wasser abgeben an:", x: 50, y: yPosition, font: .systemFont(ofSize: 14))
            yPosition += 25
            
            drawPosition(index: currentIndex+2, x: 50, y: yPosition, highlight: highlightedIndex == currentIndex+2)
            drawText(text: "\(fahrzeuge[currentIndex+1].feuerwehrName) - \(fahrzeuge[currentIndex+1].fahrzeug.typ) (\(fahrzeuge[currentIndex+1].fahrzeug.funkrufname))",
                    x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16))
        } else {
            drawText(text: "Einsatzstelle",
                    x: 90, y: yPosition, font: .boldSystemFont(ofSize: 16))
        }
        yPosition += 40
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
            // Hervorgehobene Position mit Kreis
            let circleSize: CGFloat = 40
            let circleRect = CGRect(x: x, y: y, width: circleSize, height: circleSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            // Kreis zeichnen
            let path = UIBezierPath(ovalIn: circleRect)
            UIColor.blue.setFill()
            path.fill()
            UIColor.black.setStroke()
            path.lineWidth = 3
            path.stroke()
            
            // Weißer Text im blauen Kreis
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white
            ]
            "\(index)".draw(in: circleRect.insetBy(dx: 0, dy: 9), withAttributes: attributes)
        } else {
            // Normale Position ohne Kreis (nur Text)
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
            
            // Kreis zeichnen
            let path = UIBezierPath(ovalIn: circleRect)
            (highlight ? UIColor.blue : UIColor.white).setFill()
            path.fill()
            UIColor.black.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
            
            // Text im Kreis
            "\(index)".draw(in: circleRect.insetBy(dx: 0, dy: 5), withAttributes: attributes)
        }
    
    private static func drawArrowWithDistance(x: CGFloat, y: CGFloat, distance: Int) {
        // Großer Pfeil
        let arrowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48),
            .foregroundColor: UIColor.black
        ]
        "↓".draw(at: CGPoint(x: x, y: y), withAttributes: arrowAttributes)
        
        // Abstandstext mit korrekter Pluralform
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
                                           datum: String) {
            let maxEntriesPerPage = 5 // Maximale Einträge pro Seite
            var currentPageStart = 0
            var yPosition: CGFloat = 50
            
            while currentPageStart < fahrzeuge.count {
                context.beginPage()
                yPosition = 50
                
                // Kopfbereich
                drawHeader(foerderstrecke: foerderstrecke,
                          funkrufgruppe: funkrufgruppe,
                          datum: datum,
                          yPosition: &yPosition)
                
                // Überschrift
                drawText(text: "ZUSAMMENFASSUNG - Förderstrecke \(foerderstrecke)",
                        x: 50, y: yPosition,
                        font: .boldSystemFont(ofSize: 18),
                        color: .blue)
                yPosition += 30
                
                // Gesamtstrecke nur auf erster Seite
                if currentPageStart == 0 {
                    let totalDistance = distances.reduce(0, +)
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
                    
                    // Pfeil und Abstand oder Übergabe
                    if index < fahrzeuge.count - 1 {
                        drawArrowWithDistance(x: 70, y: yPosition, distance: distances[index])
                        yPosition += 80
                    } else {
                        drawFinalTransferArrow(x: 70, y: yPosition, distance: distances.last ?? 0)
                        yPosition += 100
                    }
                    
                    // Seitenumbruch bei Bedarf
                    if yPosition > 700 && index < currentPageEnd - 1 {
                        yPosition = 50
                        context.beginPage()
                        currentPageStart = index + 1
                        break
                    }
                }
                
                currentPageStart = currentPageEnd
            }
        }

    private static func drawFinalTransferArrow(x: CGFloat, y: CGFloat, distance: Int) {
        // Großer Pfeil
        "↓".draw(at: CGPoint(x: x, y: y),
                 withAttributes: [
                    .font: UIFont.systemFont(ofSize: 48),
                    .foregroundColor: UIColor.black
                 ])
        
        // Abstand mit korrekter Pluralform
        let hoses = distance / 20
        let hoseText = hoses == 1 ? "B-Schlauch" : "B-Schläuche"
        let distanceText = "\(distance) m / \(hoses) \(hoseText)"
        
        distanceText.draw(at: CGPoint(x: x + 60, y: y + 15),
                         withAttributes: [
                            .font: UIFont.boldSystemFont(ofSize: 14),
                            .foregroundColor: UIColor.black
                         ])
        
        // Übergabe-Text unter dem Pfeil
        "Übergabe an Einsatzstelle".draw(at: CGPoint(x: x - 10, y: y + 60),
                                        withAttributes: [
                                            .font: UIFont.boldSystemFont(ofSize: 14),
                                            .foregroundColor: UIColor.black
                                        ])
    }
    
    
}

// PDFGenerator.swift
extension PDFGenerator {
    static func generateFeuerwehrUebersichtPDF(
        feuerwehren: [Feuerwehr],
        selectedFeuerwehren: Set<UUID>,
        includeInactiveVehicles: Bool = false
    ) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let datum = dateFormatter.string(from: Date())
        
        let filteredFeuerwehren = feuerwehren.filter { selectedFeuerwehren.contains($0.id) }
        
        // Berechnung der Gesamtkräfte unter Berücksichtigung der includeInactiveVehicles Option
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
            
            // Titel-Seite
            context.beginPage()
            drawHeader(title: "Feuerwehr-Übersicht", datum: datum, yPosition: &yPosition)
            
            // Gesamtinformationen mit Hinweis zur Berechnung
            drawText(text: "Gesamtbesatzung: \(gesamtBesatzung)", x: 50, y: yPosition, font: .boldSystemFont(ofSize: 16))
            yPosition += 25
            drawText(text: "Gesamt-AGT-Träger: \(gesamtAGT)", x: 50, y: yPosition, font: .boldSystemFont(ofSize: 16))
            yPosition += 20
            
            // Hinweis zur Berechnungsgrundlage
            let berechnungHinweis = includeInactiveVehicles
                ? "Berechnung inkl. aller Fahrzeuge"
                : "Berechnung nur aktiver Fahrzeuge"
            drawText(text: berechnungHinweis, x: 50, y: yPosition, font: .italicSystemFont(ofSize: 12), color: .gray)
            yPosition += 40
            
            // Detailinformationen pro Feuerwehr
            for feuerwehr in filteredFeuerwehren {
                let fahrzeugeToShow = includeInactiveVehicles
                    ? feuerwehr.fahrzeuge
                    : feuerwehr.fahrzeuge.filter { $0.isSelected }
                
                if fahrzeugeToShow.isEmpty { continue }
                
                // Prüfen ob neue Seite benötigt wird
                if yPosition > 650 {
                    context.beginPage()
                    yPosition = 50
                    drawHeader(title: "Feuerwehr-Übersicht (Fortsetzung)", datum: datum, yPosition: &yPosition)
                }
                
                // Feuerwehr-Header
                drawText(text: "\(feuerwehr.name) - \(feuerwehr.ort)", x: 50, y: yPosition, font: .boldSystemFont(ofSize: 14), color: .blue)
                yPosition += 20
                
                // Fahrzeugliste mit Status-Anzeige
                for fahrzeug in fahrzeugeToShow {
                    let statusSymbol = fahrzeug.isSelected ? "✓" : "✗"
                    let statusColor = fahrzeug.isSelected ? UIColor.green : UIColor.red
                    
                    drawText(text: "\(statusSymbol) \(fahrzeug.typ) (\(fahrzeug.funkrufname))",
                            x: 60, y: yPosition,
                            font: .systemFont(ofSize: 12),
                            color: statusColor)
                    yPosition += 20
                    
                    drawText(text: "  Besatzung: \(fahrzeug.besatzung)", x: 80, y: yPosition)
                    drawText(text: "  AGT-Träger: \(fahrzeug.agtTraeger)", x: 250, y: yPosition)
                    yPosition += 20
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
        // Titel
        drawText(text: title, x: 50, y: yPosition, font: .boldSystemFont(ofSize: 20), color: .black)
        yPosition += 25
        
        // Datum
        drawText(text: "Erstellt am: \(datum)", x: 50, y: yPosition, font: .systemFont(ofSize: 12), color: .gray)
        yPosition += 40
        
        // Trennlinie
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 50, y: yPosition))
        path.addLine(to: CGPoint(x: 562, y: yPosition))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        yPosition += 20
    }
}
