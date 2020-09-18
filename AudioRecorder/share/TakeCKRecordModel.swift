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

class TakeCKRecordModel {
    private let database = CKContainer.default().publicCloudDatabase
    private let sharedDatabase = CKContainer.default().sharedCloudDatabase
    
    // CloudKit API will notifiy its caller about finished operations on background treads
    // Extend the Model so that it sends its notifications by default to main queue
    
    var onChange:(() -> Void)?
    var onError: ((Error) -> Void)?
    var notificationQueue = OperationQueue.main
    
    // all records in CKCloudkit Container
    var records = [CKRecord]()
    var insertObjects = [TakeCKRecord]()
    var deletedObjects = Set<CKRecord.ID>()
    
    var takeRecords = [TakeCKRecord]() {
        didSet {
            self.notificationQueue.addOperation {
                self.onChange?()
            }
        }
    }
    
    /**
     Get records not in cloud storage.
     Use field value to compare records. That should be the name field
     
     - Parameter field: name of value to compare
     - Parameter recordNames: array of take names
    
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
    
    private func handle(error: Error) {
        self.notificationQueue.addOperation {
            self.onError?(error)
        }
    }
}


struct TakeCKRecord {
    fileprivate static let recordType = "Recording"
    fileprivate static let keyName = "name"
    fileprivate static let keyTake = "take"
    fileprivate static let keyMetaData = "metaData"
    
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
}
