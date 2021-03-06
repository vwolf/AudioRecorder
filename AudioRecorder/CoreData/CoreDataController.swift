//
//  CoreDataController.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import CoreData

class CoreDataController: DataControllerDelegate {
    
    var xcdatamodelName: String!
    var managedObjectContext: NSManagedObjectContext!
    var managedObjectModel: NSManagedObjectModel!
    
    var initialized = false
    // MARK: Initialization
    
    
    /// Initialze CoreData stack
    ///
    /// - parameter modelName:  CoreData Model name
    /// - parameter completionClosure
    ///
    init(modelName: String, completionClosure: @escaping () -> ()) {
        xcdatamodelName = modelName
        
        // model url
        guard let modelURL = Bundle.main.url(forResource: xcdatamodelName, withExtension: "momd" ) else {
            fatalError("Error loading model from bundle")
        }
        
        // load managed object model for the application
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        // add observers
        NotificationCenter.default.addObserver(self, selector: #selector(persistentStoreCoordinator(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: psc)
        
        // set NSManageObjectContext
        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        queue.async { [self] in
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
                else {
                    fatalError("Unable to resolve document directory")
            }
            
            let storeURL = docURL.appendingPathComponent(self.xcdatamodelName.appending(".sqlite"))
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                
                //The callback block is expected to complete the User Interface and therefore should be presented
                //back on the main queue so that the user interface does not need to be concerned with
                //which queue this call is coming from.
                DispatchQueue.main.sync(execute: completionClosure)
                self.initialized = true
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }
    
    @objc func persistentStoreCoordinator(_ n: Notification) -> Void {
        print("persistentStoreCoordinator.notification: \(n.name)")
        
        if n.name == NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange {
            let nc = NotificationCenter.default
            // make sure it runs on main queue
            OperationQueue.main.addOperation {
                nc.post(name: Notification.Name(rawValue: "persistentStoreCoordinatorStoresDidChange"), object: self, userInfo: ["message": "operationComplete"])
            }
        }
    }
    
    // MARK: - Core Data Saving support
    
    func saveContext() {
        if managedObjectContext.hasChanges {
            print("saveContext")
            do {
                if initialized {
                try managedObjectContext?.save()
                } else {
                    print("CoreDate Stack not inialized!")
                }
            } catch {
                print("Unresoved error \(error)")
            }
        }
    }
    
    // MARK: DataControllerDelegate
    
    func downloadStatus(status: String) {
        print("DataController.downloadStatus: \(status)")
    }
    // MARK: Take
    
    
    /// Add new take to CoreData or update existing take
    ///
    /// - Parameters:
    ///   - name: file name of take
    ///   - filePath: path to file
    ///   - recordedAt: Date object
    ///   - latitude: latitude as Double
    ///   - longitude: longitude as Double
    ///
    func seedTake(name: String,
                  filePath: String,
                  recordeAt: Date,
                  length: Double,
                  latitude: Double?,
                  longitude: Double?) -> Bool {

        guard let newTake = NSEntityDescription.insertNewObject(forEntityName: "Take", into: managedObjectContext) as? TakeMO else {
            print("Error seedTake")
            return false
        }
        
        newTake.name = name
        newTake.filepath = filePath
        newTake.recordedAt = recordeAt
        newTake.length = length
        if latitude != nil {
            newTake.latitude = latitude!
            newTake.longitude = longitude!
        }
        
        saveContext()
        
        return true
    }
    
    
    /// Update existing take
    ///
    /// - Parameters:
    ///   - takeNameToUpdate: TakeMO name
    ///   - name: file name of take
    ///   - filePath:
    ///   - recordedAt:
    ///   - latiude:
    ///   - longitude:
    ///
    func updateTake(takeNameToUpdate : String,
                    name: String,
                    filePath: String,
                    recordedAt: Date,
                    latitude: Double?,
                    longitude: Double?) -> Bool {
        
        // does this take exist?
        do {
            let takes = try getTake(takeName: takeNameToUpdate)
            if let take = takes?.first {
                take.name = name
                take.filepath = filePath
                take.recordedAt = recordedAt as NSDate? as Date?
                take.latitude = latitude!
                take.longitude = longitude!
            }
            
            saveContext()
            
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
       
    
    /// Return take with name takeName
    ///
    /// - Parameters:
    ///    - takeName: name in TakeMO
    ///
    func getTake(takeName: String) throws -> [TakeMO]? {
        let fetchRequest = NSFetchRequest<TakeMO>(entityName: "Take")
        fetchRequest.predicate = NSPredicate(format: "name == %@", takeName)
        do {
            let take = try managedObjectContext.fetch(fetchRequest)
            return take
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    
    /// Return all takes
    ///
    func getTakes() -> [TakeMO] {
        let fetchRequest = NSFetchRequest<TakeMO>(entityName: "Take")
        let take = try! managedObjectContext.fetch(fetchRequest)
        
        // debug print all take details
        //printTakeDetails(takes: take)
        return take
    }
    
    
    /// Delete record with name takename
    ///
    /// - parameter takeName: take name without file extension
    ///
    func deleteTake( takeName: String) -> Bool {
        let fetchRequest = NSFetchRequest<TakeMO>(entityName: "Take")
        fetchRequest.predicate = NSPredicate(format: "name == %@", takeName)
        let take = try! managedObjectContext.fetch(fetchRequest)

        if ((take.first?.metadata) != nil) {
            _ = deleteMetadataForTake(takeName: takeName)
        }
        if take.first != nil {
            managedObjectContext.delete(take.first!)
            do {
                try managedObjectContext.save()
                return true
            } catch let error as NSError {
                NSLog("Error while deleting take: \(error.userInfo)")
            }
        }
        return false
    }
    
    
    // MARK: MetaData
    
    func seedMetadata(metadata: Dictionary<String, String>) {
        let newMetadata = NSEntityDescription.insertNewObject(forEntityName: "Metadata", into: managedObjectContext) as! MetadataMO
        
        if let metadataName = metadata["name"] {
            newMetadata.name = metadataName
        }
        saveContext()
    }
    
    func seedMetadataForTake( takeName: String, metadata: Dictionary<String, String> ) {
        let fetchRequest = NSFetchRequest<TakeMO>(entityName: "Take")
        fetchRequest.predicate = NSPredicate(format: "name == %@", takeName)
        
        do {
            let take = try! managedObjectContext.fetch(fetchRequest)
            if take.count > 0 {
                for data in metadata {
                    let newMetadata = NSEntityDescription.insertNewObject(forEntityName: "Metadata", into: managedObjectContext) as! MetadataMO
                    newMetadata.name = data.key
                    newMetadata.value = data.value
                    take[0].addToMetadata(newMetadata)
                }
                saveContext()
            }
        }
    }
    
    
    func updateMetadataForTake( takeName: String, metadata: Dictionary<String, String> ) {
        let fetchRequest = NSFetchRequest<TakeMO>(entityName: "Take")
        fetchRequest.predicate = NSPredicate(format: "name == %@", takeName)
        
        var md = metadata
        do {
            let take = try! managedObjectContext.fetch(fetchRequest)
            if take.count > 0 {
                //let takeMetadata = take.first?.metadata
                let takeMetadata = take.first?.mutableSetValue(forKey: "metadata")
                for item in takeMetadata!  {
                    if let mItem = item as? MetadataMO {
                        print( "\(String(describing: mItem.name))" )
                        if metadata[mItem.name!] != nil {
                            if mItem.value != metadata[mItem.name!] {
                                mItem.value = metadata[mItem.name!]
                            }
                            md.removeValue(forKey: mItem.name!)
                        }
                    }
                }
                // any metadata entrys left
                if md.count > 0 {
                    for newItem in md {
                        let newMetadataItem = NSEntityDescription.insertNewObject(forEntityName: "Metadata", into: managedObjectContext) as! MetadataMO
                        newMetadataItem.name = newItem.key
                        newMetadataItem.value = newItem.value
                        take[0].addToMetadata(newMetadataItem)
                    }
                }
              
            }
            saveContext()
        }
    }
    
    
    /// Get metadata items for take
    /// Add extension to name of take
    ///
    /// - Parameters:
    ///   - takeName: name of take
    /// - Returns: Array MetadataMO objects
    ///
    func getMetadataForTake(takeName: String) -> [MetadataMO] {
        let fetchRequest = NSFetchRequest<TakeMO>(entityName: "Take")
        fetchRequest.predicate = NSPredicate(format: "name == %@", takeName)
        let take = try! managedObjectContext.fetch(fetchRequest)
        let meta = take[0].metadata?.allObjects as! [MetadataMO]
        
        return meta
    }
    
    
    /// Delete metadata records for take with takeName
    /// - Parameter takeName:
    /// - Returns: true if no records to delete or operation successful
    ///
    func deleteMetadataForTake(takeName: String) -> Bool {
        let fetchRequest = NSFetchRequest<TakeMO>(entityName: "Take")
        fetchRequest.predicate = NSPredicate(format: "name == %@", takeName)
        let take = try! managedObjectContext.fetch(fetchRequest)
        let metadataRecords = take[0].metadata?.allObjects as! [MetadataMO]
        
        if metadataRecords.isEmpty {
            return true
        }
        
        for item in metadataRecords {
            managedObjectContext.delete(item)
        }
        
        do {
            try managedObjectContext.save()
            return true
        } catch let error as NSError {
            NSLog("Error while deleting take: \(error.userInfo)")
        }
        
        return false
    }
    
    
    // MARK: - Settings
    
    /// Return records for entity Settings
    ///
    func fetchSettings() -> [SettingsMO] {
        let fetchRequest = NSFetchRequest<SettingsMO>(entityName: "Settings")
        let settings = try! managedObjectContext.fetch(fetchRequest)
        
        return settings
    }

    
    /// return record from entity Settings with name
    ///
    /// - Parameter name: settings name (key)
    /// - Returns: Optional SettingsMO object
    ///
    func fetchSettings( name: String) -> SettingsMO? {
        
        let fetchRequest = NSFetchRequest<SettingsMO>(entityName: "Settings")
        fetchRequest.predicate = NSPredicate(format: "name == /@",  name)
        let settins = try! managedObjectContext.fetch(fetchRequest)
        
        if settins.first != nil {
            return settins.first
        }
        return nil
    }
    
    /// Save settings dict
    ///
    /// - Parameter settings: Dict settingsKey and value
    /// - Returns
    ///
    func seedSettings(settings: [[String: Any]]) -> Bool {
        //let e = fetchSettings()
        
        for setting in settings {
            let set = NSEntityDescription.insertNewObject(forEntityName: "Settings", into: managedObjectContext) as! SettingsMO
            set.name = setting["name"] as! String?
            set.type = setting["type"] as! String?
            set.bitDepth = setting["bitDepth"] as! Int16
            set.sampleRate = setting["sampleRate"] as! Double
            set.channels = setting["channels"] as! Int16
            
            saveContext()
        }
        
        return true
    }
    
    
    // MARK: User Settings
    
    func fetchUserSettings() -> [UserSettingsMO] {
        let fetchRequest = NSFetchRequest<UserSettingsMO>(entityName: "UserSettings")
        let userSettings = try! managedObjectContext.fetch(fetchRequest)
               
        return userSettings
    }
    
    
    func seedUserSettings(settings: [String: String] ) {
        
        let newSetting = NSEntityDescription.insertNewObject(forEntityName: "UserSettings", into: managedObjectContext) as! UserSettingsMO
        newSetting.takename = settings["takeName"]
        newSetting.style = settings["style"]
        newSetting.recordingSettings = settings["recordingSettings"]
        
        
        saveContext()
    }
    
    func updateUserSetting(name: String, value: String) {
        let fetchRequest = NSFetchRequest<UserSettingsMO>(entityName: "UserSettings")
        let userSettings = try! managedObjectContext.fetch(fetchRequest)
        
        if let settings = userSettings.first {
            switch name {
            case "takename":
                settings.takename = value
            case "takenameExtension":
                settings.takenameExtension = value
            case "style":
                settings.style = value
            case "recordingSettings":
                settings.recordingSettings = value
            case "shareClient":
                settings.shareClient = value
            default:
                print("Unknown name \(name)")
            }
//            let currentName = settings.value(forKey: name)
//            if (settings.value(forKey: name) != nil) {
//                settings.value(forKey: name) as! String = value
//            }
//            settings.takename = value
        }
        
        saveContext()
    }
    
    
    // MARK Debug
    
    func printTakeDetails(takes: [TakeMO]) {
        for take in takes {
            print(take.name ?? "no take name")
            print(take.filepath ?? "no filepath")
            print("\(take.latitude), \(take.longitude)")
        }
    }
}

protocol DataControllerDelegate {
    func downloadStatus(status: String)
}
