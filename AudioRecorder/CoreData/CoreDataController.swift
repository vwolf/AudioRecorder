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
    
    // MARK: Initialization
    
    /**
     Initialze CoreData stack
     
     - modelName:  CoreData Model name
     - completionClosure
    */
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
        queue.async {
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
                try managedObjectContext?.save()
            } catch {
                print("Unresoved error \(error)")
            }
        }
    }
    // MARK: DataControllerDelegate
    
    func downloadStatus(status: String) {
        print("DataController.downloadStatus: \(status)")
    }
    
    // MARK: Settings
    
    func fetchSettings() -> [SettingsMO] {
        let fetchRequest = NSFetchRequest<SettingsMO>(entityName: "Settings")
        let settings = try! managedObjectContext.fetch(fetchRequest)
        
        return settings
    }

    func fetchSettings( name: String) -> SettingsMO? {
        
        let fetchRequest = NSFetchRequest<SettingsMO>(entityName: "Settings")
        fetchRequest.predicate = NSPredicate(format: "name == /@",  name)
        let settins = try! managedObjectContext.fetch(fetchRequest)
        
        if settins.first != nil {
            return settins.first
        }
        return nil
    }
    
    func seedSettings(settings: [[String: Any]]) {
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
            settings.takename = value
        }
        
        saveContext()
    }
    
}

protocol DataControllerDelegate {
    func downloadStatus(status: String)
}
