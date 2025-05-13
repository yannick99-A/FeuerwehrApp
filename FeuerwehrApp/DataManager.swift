import Foundation

class DataManager {
    static let shared = DataManager()
    
    private let feuerwehrenKey = "feuerwehren"
    private var cachedFeuerwehren: [Feuerwehr]?
    
    func loadFeuerwehren() -> [Feuerwehr] {
        if let cached = cachedFeuerwehren {
            return cached
        }
        
        if let data = UserDefaults.standard.data(forKey: feuerwehrenKey) {
            do {
                let decoded = try JSONDecoder().decode([Feuerwehr].self, from: data)
                if !decoded.isEmpty {
                    cachedFeuerwehren = decoded
                    return decoded
                }
            } catch {
                print("Fehler beim Decodieren der Feuerwehren: \(error.localizedDescription)")
            }
        }
        
        let standardFeuerwehren = [
            Feuerwehr(
                name: "Feuerwehr Beispieldorf",
                ort: "Beispieldorf",
                gruppe: .ortsfeuerwehr,
                fahrzeuge: [
                    Fahrzeug(
                        typ: "MLF",
                        funkrufname: "12-42-30",
                        standardBesatzung: 6,
                        besatzung: 6,
                        standardAgtTraeger: 0,
                        agtTraeger: 0
                    ),
                    Fahrzeug(
                        typ: "MTW",
                        funkrufname: "12-42-19",
                        standardBesatzung: 9,
                        besatzung: 9,
                        standardAgtTraeger: 0,
                        agtTraeger: 0
                    )
                ]
            )
        ]
        
        saveFeuerwehren(standardFeuerwehren)
        return standardFeuerwehren
    }
    
    func saveFeuerwehren(_ feuerwehren: [Feuerwehr]) {
        do {
            let encoded = try JSONEncoder().encode(feuerwehren)
            UserDefaults.standard.set(encoded, forKey: feuerwehrenKey)
            UserDefaults.standard.synchronize()
            
            cachedFeuerwehren = feuerwehren
            print("Feuerwehren erfolgreich gespeichert: \(feuerwehren.count) Einträge")
        } catch {
            print("Fehler beim Speichern der Feuerwehren: \(error.localizedDescription)")
        }
    }
}

