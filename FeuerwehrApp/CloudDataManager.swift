import Foundation
import CloudKit
import SwiftUI

class CloudDataManager: ObservableObject {
    static let shared = CloudDataManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let zoneID: CKRecordZone.ID
    
    // Record Types
    private let feuerwehrRecordType = "Feuerwehr"
    private let noteRecordType = "Note"
    private let mapStateRecordType = "MapState"
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: "FeuerwehrAppZone", ownerName: CKCurrentUserDefaultName)
        
        checkZoneAndSubscribe()
    }
    
    // MARK: - Setup
    private func checkZoneAndSubscribe() {
        checkZone { [weak self] success in
            if success {
                self?.createSubscriptions()
            }
        }
    }
    
    private func checkZone(completion: @escaping (Bool) -> Void) {
        privateDatabase.fetch(withRecordZoneID: zoneID) { _, error in
            if let error = error as? CKError, error.code == .zoneNotFound {
                self.createZone(completion: completion)
            } else {
                completion(error == nil)
            }
        }
    }
    
    private func createZone(completion: @escaping (Bool) -> Void) {
        let zone = CKRecordZone(zoneID: zoneID)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        
        operation.modifyRecordZonesCompletionBlock = { _, _, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
        
        privateDatabase.add(operation)
    }
    
    // MARK: - Subscriptions
    private func createSubscriptions() {
        createSubscription(for: feuerwehrRecordType)
        createSubscription(for: noteRecordType)
        createSubscription(for: mapStateRecordType)
    }
    
    private func createSubscription(for recordType: String) {
        let subscriptionID = "\(recordType)-changes"
        
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        operation.qualityOfService = .utility
        
        privateDatabase.add(operation)
    }
    
    // MARK: - Feuerwehr Synchronisation
    func saveFeuerwehren(_ feuerwehren: [Feuerwehr], completion: @escaping (Error?) -> Void) {
        guard !feuerwehren.isEmpty else {
            completion(nil)
            return
        }
        
        isSyncing = true
        
        let records = feuerwehren.map { feuerwehr in
            let recordID = CKRecord.ID(recordName: feuerwehr.id.uuidString, zoneID: zoneID)
            let record = CKRecord(recordType: feuerwehrRecordType, recordID: recordID)
            
            do {
                let data = try JSONEncoder().encode(feuerwehr)
                record["data"] = data
                record["lastModified"] = feuerwehr.lastModified
                return record
            } catch {
                print("Encoding error: \(error)")
                return CKRecord(recordType: feuerwehrRecordType, recordID: recordID)
            }
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        operation.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                if error == nil {
                    self?.lastSyncDate = Date()
                }
                completion(error)
            }
        }
        
        privateDatabase.add(operation)
    }
    
    func loadFeuerwehren(completion: @escaping ([Feuerwehr]?, Error?) -> Void) {
        isSyncing = true
        
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: feuerwehrRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.zoneID = zoneID
        operation.resultsLimit = 200
        
        var loadedFeuerwehren = [Feuerwehr]()
        
        operation.recordFetchedBlock = { record in
            if let data = record["data"] as? Data {
                do {
                    let feuerwehr = try JSONDecoder().decode(Feuerwehr.self, from: data)
                    loadedFeuerwehren.append(feuerwehr)
                } catch {
                    print("Decoding error: \(error)")
                }
            }
        }
        
        operation.queryCompletionBlock = { [weak self] cursor, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                if error == nil {
                    self?.lastSyncDate = Date()
                }
                completion(loadedFeuerwehren, error)
            }
        }
        
        privateDatabase.add(operation)
    }
    
    // MARK: - Notizen Synchronisation
    func saveNotes(_ notes: [Note], completion: @escaping (Error?) -> Void) {
        // Ähnliche Implementierung wie saveFeuerwehren
    }
    
    func loadNotes(completion: @escaping ([Note]?, Error?) -> Void) {
        // Ähnliche Implementierung wie loadFeuerwehren
    }
    
    // MARK: - Kartenzustand Synchronisation
    func saveMapState(_ state: FeuerwehrKarteViewModel.SavedState, completion: @escaping (Error?) -> Void) {
        // Ähnliche Implementierung wie saveFeuerwehren
    }
    
    func loadMapState(completion: @escaping (FeuerwehrKarteViewModel.SavedState?, Error?) -> Void) {
        // Ähnliche Implementierung wie loadFeuerwehren
    }
    
    // MARK: - Konfliktbehandlung
    func resolveConflicts<T: Codable & Identifiable>(localItems: [T], remoteItems: [T]) -> [T] {
        var merged = [T]()
        let localDict = Dictionary(uniqueKeysWithValues: localItems.map { ($0.id, $0) })
        let remoteDict = Dictionary(uniqueKeysWithValues: remoteItems.map { ($0.id, $0) })
        
        let allIDs = Set(localDict.keys).union(Set(remoteDict.keys))
        
        for id in allIDs {
            if let local = localDict[id], let remote = remoteDict[id] {
                // Konflikt - nehmere das aktuellere Element
                if let localModifiable = local as? HasLastModified,
                   let remoteModifiable = remote as? HasLastModified {
                    merged.append(localModifiable.lastModified > remoteModifiable.lastModified ? local : remote)
                } else {
                    merged.append(remote) // Standardmäßig Remote bevorzugen
                }
            } else if let local = localDict[id] {
                merged.append(local)
            } else if let remote = remoteDict[id] {
                merged.append(remote)
            }
        }
        
        return merged
    }
}

protocol HasLastModified {
    var lastModified: Date { get }
}