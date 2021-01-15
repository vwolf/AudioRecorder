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
import Photos

 /// ICloud service: Add, update, delete, refresh
 ///
class TakeCKRecordModel {
    
    static let sharedInstance = TakeCKRecordModel()
    
    private let publicDatabase = CKContainer.default().publicCloudDatabase
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
    
    /// Add a take to iCloud reading the Take object.
    /// Only add new take (unique takename).
    ///
    /// - Parameter take: selected take object
    ///
    func addTake(take: Take,  completion: @escaping (Bool, Error?) -> Void ) {
        if takeRecords.contains(where: { $0.name == take.takeName }) {
            // takeCKRecord with name exist!
            // abort or update?
            print("TakeCKRecord with name \(String(describing: take.takeName)) exist")
            completion(false, TakeCKRecordModelError.NoTakeCKRecord(take.takeName ?? "?"))
        } else {
            var takeRecord = TakeCKRecord()
            
            // add recorded audioNote
            guard let takeURL = take.getTakeURL() else {
                // no recorded take
                print("no take url")
                return
            }
            
            let takeAudioAsset = CKAsset(fileURL: takeURL)
            takeRecord.audioAsset = takeAudioAsset
            
            takeRecord.name = takeURL.lastPathComponent
            
            // image asset
            if let imageItem = take.getItemForID(id: "image", section: .METADATASECTION) {
                if let imageName = imageItem.value as? String {
                    if imageName != "" {
                        // now we have the name of image in app's documents directory
                        let takeFolderURL = take.getTakeFolder()
                        let imageURL = takeFolderURL?.appendingPathComponent(imageName)
                        if FileManager.default.fileExists(atPath: imageURL!.path) {
                            takeRecord.imageAsset = CKAsset(fileURL: imageURL!)
                        }
                    }
                }
            }
            
            // note asset
            if let audioItem = take.getItemForID(id: "audioNote", section: .METADATASECTION) {
                let takeFolderURL = take.getTakeFolder()
                if let audioItemName = audioItem.value as? String {
                    let audioItemURL = takeFolderURL?.appendingPathComponent(audioItemName)
                    if FileManager.default.fileExists(atPath: audioItemURL!.path) {
                        takeRecord.noteAsset = CKAsset(fileURL: audioItemURL!)
                    }
                }
            }
            
            
            // add metadata file, overwriting existing one
            take.writeJsonForTake() { metadataURL, error in
                if (error != nil) {
                    // problem writing metadata file
                    print(error!)
                    completion(false, error)
                } else {
                    print(metadataURL)
                    takeRecord.metadataAsset = CKAsset(fileURL: metadataURL)
                    
                    // update public CloudDatabase
                    publicDatabase.save(takeRecord.record) { _, error in
                        guard error == nil else {
                            self.handle(error: error!)
                            return
                        }

                        self.insertedObjects.append(takeRecord)
                        self.updateTakeRecords()
                        
                        completion(true, nil)
                        //CloudDataManager.sharedInstance.takeFolderToCloud(takeName: take.takeName!, takeDirectory: "takes")
                    }
                }
            }
            
            
        }
    }
    
    /// Add Take to iCloud
    ///
    /// - Parameter url: url to take in documents directory
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
        
        // set files ubiquitous to remove from app's document directory
        // FileManager.default.setUbiquitous(true, itemAt: url, destinationURL: url)
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
        publicDatabase.save(takeRecord.record) { _, error in
            guard error == nil else {
                self.handle(error: error!)
                return
            }

            self.insertedObjects.append(takeRecord)
            self.updateTakeRecords()
        }
        
    }
    
    
    /// Delete take at index
    ///
    /// - parameters index: index of take to delete in takeRecords
    ///
    func deleteTake(at index: Int) {
        let recordID = takeRecords[index].record.recordID
        publicDatabase.delete(withRecordID: recordID) { _, error in
            guard error == nil else {
                self.handle(error: error!)
                return
            }
        }
        
        deletedObjectIDs.insert(recordID)
        updateTakeRecords()
    }
    
    
    /// Delete take with id
    ///
    /// - Parameter id: 
    func deleteTake(with id: CKRecord.ID) {
        publicDatabase.delete(withRecordID: id) { _, error in
            guard error == nil else {
                self.handle(error: error!)
                return
            }
            self.deletedObjectIDs.insert(id)
            self.updateTakeRecords()
        }
        
//        deletedObjectIDs.insert(id)
//        updateTakeRecords()
    }
    
    /// Get records not in cloud storage.
    ///
    /// Use field value to compare records. That should be the name field
    ///
    /// - parameter field: name of value to compare
    /// - parameter recordNames: array of take names
    ///
    /// - returns array with new record names
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
        
        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            guard let records = records, error == nil else {
                self.handle(error: error!)
                return
            }
            self.records = records
            self.updateTakeRecords()
            completion()
        }
    }
    
    
    func deleteTake(takeName: String, completion: @escaping (Bool) -> Void )  {
        
        if let idx = (takeRecords.firstIndex(where: { $0.name == takeName })) {
            let recordID = takeRecords[idx].record.recordID
            publicDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
                if error == nil {
                    print("Record deleted")
                    completion(true)
                } else {
                    print("DeleteTake Error: \(String(describing: error?.localizedDescription))")
                    completion(false)
                }
            }
        }
    }
    
    
    func getTakeCKRecord(takeName: String) -> TakeCKRecord? {
        let takeNameWithExtension = "\(takeName).wav"
        return takeRecords.first(where: { $0.name == takeNameWithExtension })
    }
    
    func takeCKRecordExist(takeName: String) -> Bool {
        let takeNameWithExtension = "\(takeName).wav"
        return takeRecords.contains(where: { $0.name == takeNameWithExtension})
    }
}


struct TakeCKRecord {
    fileprivate static let recordType = "Take"
    fileprivate static let keyName = "name"
    fileprivate static let keyTake = "take"
    fileprivate static let keyMetaData = "metadata"
    fileprivate static let keyAudioNote = "audioNote"
    fileprivate static let keyImageNote = "image"
    
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
    
    var imageAsset: CKAsset {
        get {
            return self.record.value(forKey: TakeCKRecord.keyImageNote) as! CKAsset
        }
        set {
            self.record.setValue(newValue, forKey: TakeCKRecord.keyImageNote)
        }
    }
}

enum TakeCKRecordModelError {
    case NoTakeCKRecord(String)
}

extension TakeCKRecordModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .NoTakeCKRecord:
            return NSLocalizedString("No TakeCKRecord with takeName: ", comment: "")
        }
    }
}
