//
//  TakeCKRecordModel.swift
//  AudioRecorder
//
//  Created by Wolf on 14.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

/**
 Add, update, delete, refresh
 
 
 */
class TakeCKRecordModel {
    
    static let sharedInstance = TakeCKRecordModel()
    
    private let database = CKContainer.default().publicCloudDatabase
    private let privateDatabase = CKContainer.default().privateCloudDatabase
    private let sharedDatabase = CKContainer.default().sharedCloudDatabase
    
    // CloudKit API will notifiy its caller about finished operations on background treads
    // Extend the Model so that it sends its notifications by default to main queue
    
    var onChange:(() -> Void)?
    var onError: ((Error) -> Void)?
    var notificationQueue = OperationQueue.main
    
    // all records in CKCloudkit Container
    var records = [CKRecord]()
    var insertedObjects = [TakeCKRecord]()
    var deletedObjectIDs = Set<CKRecord.ID>()
    
    var takeRecords = [TakeCKRecord]() {
        didSet {
            self.notificationQueue.addOperation {
                self.onChange?()
            }
        }
    }
    
    private let container = CKContainer.default()
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    
    /// Get account status and observer to account status changes
    init() {
        requestAccountStatus()
        setupNotificationHandling()
    }
    
    private func requestAccountStatus() {
        container.accountStatus { [unowned self] (accountStatus, error ) in
            if let error = error { print(error) }
            
            self.accountStatus = accountStatus
        }
    }
    
    /// When the account status changes, a CKAccountChanged notification is posted by an instance of the CKContainer class.
    /// If no instance is alive when the account status changes, no notification is posted -> keep a reference to the default container.
    ///
    fileprivate func setupNotificationHandling() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(accountDidChange(_:)), name: Notification.Name.CKAccountChanged, object: nil)
    }
    
    @objc private func accountDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.requestAccountStatus()
        }
    }
    
    
    func addTake(url: URL) {
        var takeRecord = TakeCKRecord()
        takeRecord.name = url.lastPathComponent
        
        // recording (wav file)
        let takeAsset = CKAsset(fileURL: url)
        
        takeRecord.audioAsset = takeAsset
        
        // metadataFile? (*.json)
        let metadataFileURL = url.deletingPathExtension().appendingPathExtension("json")
        if FileManager.default.fileExists(atPath: metadataFileURL.path) {
            takeRecord.metadataAsset = CKAsset(fileURL: metadataFileURL)
        } else {
            // no metadata json file, create one
            let takeName = url.deletingPathExtension().lastPathComponent
            
            if (Takes().makeMetadataFile(takeName: takeName) == true) {
                takeRecord.metadataAsset = CKAsset(fileURL: metadataFileURL)
            }
        }
        
        // notes for take?
        var takeNoteFileURL = url.deletingPathExtension().appendingPathComponent("notes")
        takeNoteFileURL.appendPathComponent(takeRecord.name, isDirectory: false)
        
        if FileManager.default.fileExists(atPath: takeNoteFileURL.path) {
            takeRecord.noteAsset = CKAsset(fileURL: takeNoteFileURL)
        }
        
        //FileManager.default.setUbiquitous(true, itemAt: url, destinationURL: <#T##URL#>)
//        privateDatabase.save(takeRecord.record) { _, error in
//            guard error == nil else {
//                self.handle(error: error!)
//                return
//            }
//
//            self.insertedObjects.append(takeRecord)
//            self.updateTakeRecords()
//        }
        
        // update public CloudDatabase
        database.save(takeRecord.record) { _, error in
            guard error == nil else {
                self.handle(error: error!)
                return
            }

            self.insertedObjects.append(takeRecord)
            self.updateTakeRecords()
        }
        
    }
    
    /**
     Delete take at index
     
     - parameters index: index of take to delete in takeRecords
     */
    func deleteTake(at index: Int) {
        let recordID = takeRecords[index].record.recordID
        database.delete(withRecordID: recordID) { _, error in
            guard error == nil else {
                self.handle(error: error!)
                return
            }
        }
        
        deletedObjectIDs.insert(recordID)
        updateTakeRecords()
    }
    
    
    /**
     Get records not in cloud storage.
     
     Use field value to compare records. That should be the name field
     
     - parameter field: name of value to compare
     - parameter recordNames: array of take names
     
     - returns array with new record names
    
     */
    func getNewRecords(with field: String, in recordNames: [String] ) -> [String] {
       
        var newRecords = recordNames
        for idx in 0..<recordNames.count {
            if takeRecords.contains(where: { $0.name == recordNames[idx] }) {
                if let i = newRecords.firstIndex(of: recordNames[idx]) {
                    newRecords.remove(at: i)
                }
            }
        }
        
        return newRecords
    }
    
    /// Return value name for all records
    /// 
    func getRecordsName() -> [String] {
        var recordNames = [String]()
        for rec in takeRecords {
            recordNames.append(rec.name)
        }
        return recordNames
    }
    
    func getRecordsTakeURL() -> [URL] {
        var takeURLs = [URL]()
        for take in takeRecords {
            if (take.audioAsset.fileURL != nil) {
                takeURLs.append(take.audioAsset.fileURL!)
            }
        }
        return takeURLs
    }
    
    
    
    private func handle(error: Error) {
        self.notificationQueue.addOperation {
            self.onError?(error)
        }
    }
    
    
    fileprivate func updateTakeRecords() {
        var knownIDs = Set(records.map { $0.recordID })
        
        // remove objects form local list once the are returned from cloudkit storage
        self.insertedObjects.removeAll { takeRecord in
            knownIDs.contains(takeRecord.record.recordID)
        }
        knownIDs.formUnion(self.insertedObjects.map { $0.record.recordID })
        
        // remove objects form local list once we see them not being returned from storage anymore
        self.deletedObjectIDs.formIntersection(knownIDs)
        
        var takeRecords = records.map { record in TakeCKRecord(record: record) }
        
        takeRecords.append(contentsOf: self.insertedObjects )
        takeRecords.removeAll { takeRecord in
            deletedObjectIDs.contains(takeRecord.record.recordID)
        }
        
        self.takeRecords = takeRecords
        
        debugPrint("Tracking local objects \(self.insertedObjects) \(self.deletedObjectIDs)")
    }
    
    /// Get all records
    @objc func refresh( completion: @escaping () -> Void ) {
        let query = CKQuery(recordType: TakeCKRecord.recordType, predicate: NSPredicate(value: true))
        
        database.perform(query, inZoneWith: nil) { records, error in
            guard let records = records, error == nil else {
                self.handle(error: error!)
                return
            }
            self.records = records
            self.updateTakeRecords()
            completion()
        }
    }
    
    
    func deleteTake(takeName: String) {
        
        if let idx = (takeRecords.firstIndex(where: { $0.name == takeName }))  {
            let recordID = takeRecords[idx].record.recordID
            database.delete(withRecordID: recordID) { (deletedRecordID, error) in
                if error == nil {
                    print("Record deleted")
                } else {
                    print("DeleteTake Error: \(error?.localizedDescription)")
                }
            }
        }
        
//        if takeRecords.contains(where: { $0.name == takeName }) {
//            if let i = newRecords.firstIndex(of: recordNames[idx]) {
//                newRecords.remove(at: i)
//            }
//        }
//        database.delete(withRecordID: recordID) { (deletedRecordID, error) in
//
//        }
    }
    
    
    func getTakeCKRecord(takeName: String) -> TakeCKRecord? {
        let takeNameWithExtension = "\(takeName).wav"
        return takeRecords.first(where: { $0.name == takeNameWithExtension })
        
    }
}


struct TakeCKRecord {
    fileprivate static let recordType = "Take"
    fileprivate static let keyName = "name"
    fileprivate static let keyTake = "take"
    fileprivate static let keyMetaData = "metadata"
    fileprivate static let keyAudioNote = "audioNote"
    
    var record: CKRecord
    
    init(record: CKRecord) {
        self.record = record
    }
    
    init() {
        self.record = CKRecord(recordType: TakeCKRecord.recordType)
    }
    
    var name: String {
        get {
            return self.record.value(forKey: TakeCKRecord.keyName) as! String
        }
        set {
            self.record.setValue(newValue, forKey: TakeCKRecord.keyName)
        }
    }
    
    var audioAsset: CKAsset {
        get {
            return self.record.value(forKey: TakeCKRecord.keyTake) as! CKAsset
        }
        set {
            self.record.setValue(newValue, forKey: TakeCKRecord.keyTake)
        }
    }
    
    var metadataAsset: CKAsset {
        get {
            return self.record.value(forKey: TakeCKRecord.keyMetaData) as! CKAsset
        }
        set {
            self.record.setValue(newValue, forKey: TakeCKRecord.keyMetaData)
        }
    }
    
    var noteAsset: CKAsset {
        get  {
            return self.record.value(forKey: TakeCKRecord.keyAudioNote) as! CKAsset
        }
        set {
            self.record.setValue(newValue, forKey: TakeCKRecord.keyAudioNote)
        }
    }
}
