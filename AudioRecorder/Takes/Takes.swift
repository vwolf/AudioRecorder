//
//  Takes.swift
//  AudioRecorder
//
//  Created by Wolf on 01.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

/// Takes of kinds (local, iCloud, iDrive, Dropbox)

class Takes {

    /// singelton pattern
    static let sharedInstance = Takes()
    
    var coreDataController: CoreDataController?
    var takesLocal: [Take] = []
    var takesCloud: [Take] = []
    var takesDrive: [Take] = []
    var takesDropbox: [Take] = []
    
    var reloadFlag = false
    
    var allTakeNames = [String]()
    
    init() {
        /// get CoreDataController
        coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
    }
    
    /// Get all takes in documents directory. Each take has its own subdirectory.
    /// For each found take add [Take] to allTakes
    /// Also get all TakeMO for CoreData controller. If take has TakeMO then initialize take with TakeMO.
    ///
    /// - Parameters directory: Takes are in subfolder
    /// - Parameters fileExtension: file type, always "wav"
    ///
    func getAllTakesInApp(directory: String?, fileExtension: String) -> Bool {
        var documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if (directory != nil) {
            documentPath = documentPath.appendingPathComponent(directory!).absoluteURL
        }
        
        /// get all directories in documentPath
        do {
            let directoryContent = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            /// we only wants the files with right fileExtension, ignore folder at the moment
            /// folders could come imported if we add more assets (images, sub takes, ...)
//            let filePaths = directoryContent.filter { $0.pathExtension == fileExtension }"
            let takeFolders = directoryContent.filter { $0.hasDirectoryPath == true }
            /// get all Take Records from CoreData
            let takeMOs = coreDataController?.getTakes()
            //print(takeMOs?.first?.description)
            for take in takeFolders {
                let takeName = take.lastPathComponent
                let takeURLName = "\(takeName).\(fileExtension)"
                /// wav file in take folder
                let takeFolderFiles = try FileManager.default.contentsOfDirectory(at: take, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                let wavFiles = takeFolderFiles.filter { $0.pathExtension == fileExtension }
                /// a take in app's take directory should have a CoreData record
                for wavFile in wavFiles {
                    if wavFile.lastPathComponent == takeURLName {
                        if let takeMO = takeMOs?.first(where: { $0.name == takeName }) {
                            // take file and CoreData Record
                            takesLocal.append(Take(withTakeMO: takeMO))
                        } else {
                            /// take file but no CoreData Record?
                            print("No TakeMO for take \(takeName)")
                            /// make Take and add TakeMO
                            let metaDataFile = takeFolderFiles.filter { $0.pathExtension == "json"}
                            if !metaDataFile.isEmpty {
                                // metadata file with takeName?
                                takesLocal.append(Take.init(takeURL: wavFile, metaDataURL: metaDataFile.first))
                            } else {
                                takesLocal.append(Take.init(takeURL: wavFile, metaDataURL: nil))
                            }
                        }
                    }
                }
            }
            
            print("Takes in app's take directory: \(takesLocal.count)")
            
            if takeMOs != nil {
                if takesLocal.count < takeMOs!.count {
                    validateCoreDataRecords(takeMOs: takeMOs!)
                }
            }
            
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
        
        //return false
    }
    
    /// Get all takes in app's iCloud directory.
    /// This could be takes with a CoreData Record (TakeMO). This takes are set "Ubiquitous" and can be added to app any time.
    /// Find TakeMO for take and add to connect with take.
    /// Problems?
    /// Takes without CoreData Record are deleted in app (after setting ubiquitous).
    ///
    func getAllTakesIniCloud() {
        for take in TakeCKRecordModel.sharedInstance.takeRecords {
            let takeName = stripFileExtension(take.name)
            // CoreData record
            let takeMO = try? coreDataController?.getTake(takeName: takeName)
            if (takeMO?.first != nil) {
                takesCloud.append(Take(withTakeMO: takeMO!.first!))
            } else {
                takesCloud.append( Take(takeCKRecord: take, takeName: takeName))
            }
        }
        
        connectICloudTakes()
    }
    
    
    /// Get all takes in app iDrive directory
    /// 
    func getAllTakesIniDrive(completion: @escaping( () -> Void ) ) {
        print("\n #### TAKES IN IDRIVE #### \n")
        DispatchQueue.main.async {
            CloudDataManager.sharedInstance.metadataQuery { [self] result in
                print("metadataQuery with result \(result), takes: \(CloudDataManager.sharedInstance.cloudURLs.count)")
           
                for t  in takesLocal {
                    print("#### \(String(describing: t.takeName))")
                }
                
                let takeMOs = coreDataController?.getTakes()
                let resourceKeys = Set<URLResourceKey>([.nameKey, .isUbiquitousItemKey, ])
                
                for url in CloudDataManager.sharedInstance.cloudURLs {
                    print(url.lastPathComponent)
                    guard let resourceValues = try? url.resourceValues(forKeys: resourceKeys),
                          let name = resourceValues.name,
                          let isUbiquitous = resourceValues.isUbiquitousItem
                    else {
                        // this takes have nothing to do with app (at least until reimport)
                        // any take with name in local takes?
                        //print("lastPathComponent: \(url.lastPathComponent)")
                        if takesLocal.contains(where: { $0.takeName! + ".wav" == url.lastPathComponent}) {
                            //print("Take \(url.lastPathComponent) in iCloud")
                        }
                        continue
                    }
                    
                    //print("NAME: \(name)")
                    let nameWithoutExtension = stripFileExtension(name)
                    if isUbiquitous {
                        //print("\(name) is ubiquitous")
                        /// does a CoreData Take Record exist for take?
                        if let takeMO = takeMOs?.first(where: { $0.name == nameWithoutExtension }) {
                            //print("TakeMO Record for take \(name)")
                            
                            takesDrive.append(Take(withTakeMO: takeMO))
                            //takesLocal.append(Take.init(withTakeMO: takeMO))
                        }
                    } else {
                        //print("lastPathComponent: \(url.lastPathComponent)")
                        if takesLocal.contains(where: { $0.takeName! + ".wav" == url.lastPathComponent}) {
                            print("Take \(url.lastPathComponent) in iCloud")
                        }
                    }
                    
                }
                //self.addToTakesInShare(takeURLs:  CloudDataManager.sharedInstance.cloudURLs)
            }
            print("#################################### \n")
            completion()
        }
    }
    
    
    
    func getAllTakesInDropbox() {
        if DropboxManager.sharedInstance.client != nil {
            print("getAllTakesInDropbox")
            DropboxManager.sharedInstance.listFiles() { result in
                for take in DropboxManager.sharedInstance.takesInDropbox {
                    self.takesDropbox.append(Take(takeName: take, storageState: .DROPBOX))
                }
            }
        }
    }
    
    /// Add takes from iCloud.
    /// Same take could be in app and in iCloud 
    func addICloudTakes(urls: [URL]) {
        
    }
    
    /// Connection same take local and iCloud
    ///
    func connectICloudTakes() {
        for take in takesCloud {
            if let idx = takesLocal.firstIndex(where: { $0.takeName == take.takeName }) {
                takesLocal[idx].iCloudState = .ICLOUD
            }
        }
    }
    
    /// Connection same take local and iDrive
    ///
    func connectIDriveTakes() {
        for take in takesDrive {
            if let idx = takesLocal.firstIndex(where: { $0.takeName == take.takeName }) {
                takesLocal[idx].iDriveState = .IDRIVE
            }
        }
    }
    
    /// Connection same take local and Dropbox
    ///
    func connectDropboxTakes() {
        print("connectDropboxTakes: \(takesDropbox.count)")
        for take in takesDropbox {
            print("try connect take: \(String(describing: take.takeName))")
            if let idx = takesLocal.firstIndex(where: { $0.takeName == take.takeName }) {
                takesLocal[idx].dropboxState = .DROPBOX
            }
        }
    }
    
    
    /// A take is moved to iDrive, so it's no longer a local take
    /// Remove coredata record
    ///
    /// - Parameter takeName
    func takeIsUbiquitous(takeName: String) {
        if let takeIdx = takesLocal.firstIndex(where: { $0.takeName == takeName}) {
            takesLocal.remove(at: takeIdx)
            
            reloadFlag = true
        }
    }
    
    
    func getAllTakeNames( fileExtension: String, directory: String?, returnWithExtension: Bool = false) -> [String] {
        var documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if (directory != nil) {
            documentPath = documentPath.appendingPathComponent(directory!).absoluteURL
        }
        
        do {
            let directoryContent = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil, options: [])
            
            let filePaths = directoryContent.filter{ $0.pathExtension == fileExtension }
            let folders = directoryContent.filter{ $0.hasDirectoryPath == true}
            
            if folders.count > 0 {
                print(folders.first?.lastPathComponent ?? "No lastPathComponent?")
            }
            
            if returnWithExtension == false {
                let fileNames = filePaths.map { $0.deletingPathExtension().lastPathComponent }
                return fileNames
            } else {
                let fileNamesWithExtension = filePaths.map{ $0.lastPathComponent }
                
                return fileNamesWithExtension
            }
            
        } catch {
            print(error.localizedDescription)
        }
        
        return [String]()
    }
    
    /**
     Use to get all takenames if each take gets  own folder
     Take folder are in directory "takes"
     
     */
    func getAllTakeNames() {
        var takeDirectorys: [URL] = []
        var takeNames: [String] = []
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let takesPath = documentPath.appendingPathComponent(AppConstants.takesFolder.rawValue, isDirectory: true)
        // now get all directory in takesPath
        let enumerator = FileManager.default.enumerator(at: takesPath, includingPropertiesForKeys: [.isDirectoryKey, .nameKey], options: .skipsHiddenFiles)
        
        for case let fileURL as URL in enumerator! {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey]),
                  let isDirectory = resourceValues.isDirectory,
                  let name = resourceValues.name
            else {
                continue
            }
            
            if isDirectory {
                if FileManager.default.subpaths(atPath: fileURL.path)!.count > 0 {
                    takeDirectorys.append(fileURL)
                    takeNames.append(name)
                }
            }
        }
        
//        let cloudtakes = CloudDataManager.sharedInstance.getTakesInCloud()
        
//        DispatchQueue.main.async {
//            CloudDataManager.sharedInstance.metadataQuery { result in
//                print("metadataQuery with result \(result)")
//                self.addToTakesInShare(takeURLs:  CloudDataManager.sharedInstance.cloudURLs)
//            }
//        }
        allTakeNames = takeNames
        //return takeNames
    }
    
    
    /// Get all take names with a base name. Collect take names found in
    /// takesLocal, takesCloud and takesDrive
    ///
    func getAllTakeNames(base: String) -> [String] {
        //var takeNames = [String]()
        
        // get local takes which start with base
        var takeNames = [String]()
        takeNames = takesLocal.map({ $0.takeName! })
        takeNames.append(contentsOf: takesCloud.map({ $0.takeName! }))
        takeNames.append(contentsOf: takesDrive.map({ ($0.takeName ?? "") }))
        
        let takesWithName = takeNames.filter( {(item: String) -> Bool in
            let stringMatch = item.range(of: base)
            return stringMatch != nil ? true : false
        })
        
        
        return takesWithName
    }
    
    
    /// Check if take with name exists
    ///
    /// - Parameter name: name to check
    ///
    func fileWithNameExist(name: String) -> Bool {
        if allTakeNames.isEmpty {
            let takeWithNames = getAllTakeNames()
            return allTakeNames.contains(name)
        } else {
            return allTakeNames.contains(name)
        }
        
        
    }
    
    
    private func addToTakesInShare(takeURLs: [URL]) {
        let takeMOs = coreDataController?.getTakes()
        for t in takeMOs! {
            print(t.name ?? "missing name?")
        }
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isUbiquitousItemKey])
        for item in takeURLs {
            print("TakesInShare: \(item.lastPathComponent)")
            //takesInShare.append(TakeInShare(url: item, state: TakeInShare.State.CLOUD))
            
            guard let resourceValues = try? item.resourceValues(forKeys: resourceKeys),
                  let name = resourceValues.name,
                  let isUbiquitous = resourceValues.isUbiquitousItem
            else {
                continue
            }
            
            if isUbiquitous {
                print("\(name) is ubiquitous")
                /// does a CoreData Take Record exist for take?
                if (takeMOs?.first(where: { $0.name == name })) != nil {
                    print("TakeMO Record for take \(name)")
                }
            }
        }
        
    }
    
    /**
     Test if file exists at loction and return url if file exits
     This is a basic version, just checking default documents directory, no subdirectories
     
     - Parameters:
     - fileName: filename with extension
     */
    func getUrlforFile(fileName: String) -> URL? {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fullFilePath = documentPath.appendingPathComponent(fileName)
        
        print(fullFilePath.absoluteString)
        if FileManager.default.fileExists(atPath: fullFilePath.path) {
            return fullFilePath
        }
        return nil
    }
    
    
    /// Return url for take [takeName]
    /// This is the version when takes are in special takeDirectory and each take is in its own folder
    ///
    /// - parameter takeName: name of take without extension
    /// - parameter fileExtension: file type
    /// - parameter takeDirectory: take directory
    ///
    func getURLForFile(takeName: String, fileExtension: String, takeDirectory: String) -> URL? {
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var filePath = documentPath.appendingPathComponent(takeDirectory, isDirectory: true)
        
        filePath.appendPathComponent(takeName, isDirectory: true)
        filePath.appendPathComponent(takeName, isDirectory: false)
        filePath.appendPathExtension(fileExtension)
        
        if FileManager.default.fileExists(atPath: filePath.path) {
            return filePath
        }
        return nil
    }
    
    /**
     Return url to take directory
     
     - parameter takeName
     - parameter takeDirectory
     */
    func getDirectoryForFile(takeName: String, takeDirectory: String) -> URL? {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var directoryPath = documentPath.appendingPathComponent(takeDirectory, isDirectory: true)
        directoryPath.appendPathComponent(takeName, isDirectory: true)
        
        if FileManager.default.fileExists(atPath: directoryPath.path) {
            return directoryPath
        }
        return nil
    }
    
    /**
     Does take with takeName exist?
     Is newTakeName unique?
     
     - parameter takeName: name of existing take (with extension!)
     - parameter newTakeName: name to change to without extension
     */
    func renameTake( takeName: String, newTakeName: String) -> Bool {
        guard let takePath = getUrlforFile(fileName: takeName) else {
            print("Can't find file with name \(takeName)")
            return false
        }
        
        // new url
        //let pathExtension = takePath.pathExtension
        var newPath = takePath.deletingLastPathComponent()
        let fileExtension = takePath.pathExtension
        newPath.appendPathComponent(newTakeName)
        newPath.appendPathExtension(fileExtension)
        
        // unique?
        if FileManager.default.fileExists(atPath: newPath.path) {
            return false
        }
        
        do {
            try FileManager.default.moveItem(at: takePath, to: newPath)
            
        } catch {
            print(error.localizedDescription)
        }
        
        return true
    }

    
    /// Rename take if takes in subdirectory and each take is in own directory
    ///
    /// - parameter takeName: file name without extension
    /// - parameter newTakeName:
    /// - parameter fileExtension
    /// - parameter takeDirectory: directory for all takes
    ///
    func renameTake( takeName: String, newTakeName: String, fileExtension: String, takesDirectory: String) -> Bool {
        
        guard let takeURL = getURLForFile(takeName: takeName, fileExtension: fileExtension, takeDirectory: takesDirectory) else {
            print("Can't find file with name \(takeName) to rename take")
            return false
        }
        
        // new url
        var newURL = takeURL.deletingLastPathComponent()
        newURL.appendPathComponent(newTakeName)
        newURL.appendPathExtension(fileExtension)
        // file exist?
        if FileManager.default.fileExists(atPath: newURL.path) {
            print("Take \(newTakeName) exist at \(newURL.path)")
            return false
        }
        // create new directory
        let directoryURL = takeURL.deletingLastPathComponent()
        let newDirectoryURL = directoryURL.deletingLastPathComponent().appendingPathComponent(newTakeName, isDirectory: true)
        
        // rename files in folder then rename folder
        do {
            try FileManager.default.moveItem(at: takeURL, to: newURL)
            try FileManager.default.moveItem(at: directoryURL, to: newDirectoryURL)
        } catch {
            print(error.localizedDescription)
        }
        
        return true
    }
    
    
    func checkFileName( newTakeName: String, takeName: String, fileExtension: String) -> String {
//        guard let takePath = getUrlforFile(fileName: "\(takeName).\(fileExtension)") else {
//            print("Can't find file with name \(takeName)")
//            return "noTake"
//        }
        
        guard let takePath = getURLForFile(takeName: takeName, fileExtension: fileExtension, takeDirectory: "takes") else {
            print("Can't find file with name \(takeName)")
            return "noTake"
        }
        
        if newTakeName == takeName {
            return "noChanges"
        }
        // unique?
        var newPath = takePath.deletingLastPathComponent()
        newPath.appendPathComponent(newTakeName)
        
        if FileManager.default.fileExists(atPath: newPath.path) {
            return "notUnique"
        }
        
        return "ok"
    }
    
    /**
     Take to rename exists?
     Take at new path does not exists?
     
     - Parameters:
     - takeURL: URL of existing tack
     - newTakeName: name to change to without extension
     */
    func renameTake( takeURL: URL, newTakeName: String) -> Bool {
        if FileManager.default.fileExists(atPath: takeURL.path) {
            var newTakeURL = takeURL.deletingLastPathComponent().appendingPathComponent(newTakeName)
            let takePathExtension = takeURL.pathExtension
            newTakeURL.appendPathExtension(takePathExtension)
            
            do {
                try FileManager.default.moveItem(at: takeURL, to: newTakeURL)
            } catch {
                print(error.localizedDescription)
            }
            
            
        } else {
            return false
        }
        
        return true
    }
    
    
    func fileNameUnique(fileURL: URL) -> Bool {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return false
        }
        return true
    }
    
    func stripFileExtension(_ filename: String) -> String {
        var components = filename.components(separatedBy: ".")
        guard components.count > 1 else { return filename }
        components.removeLast()
        return components.joined(separator: ".")
    }
    
    
    /// When takename extensions are index then get next index
    /// First: get all takenames starting with name
    /// Second: get takenames
    ///
    func getIndexForName(name: String, seperator: String, type: String, indexLength: Int, ubiqutios: [String] = []) -> String {
        var maxIdx = 0
        let nameWithSeperator = name + seperator
        
        let allTakeNames = getAllTakeNames(base: name)
        //allTakeNames.append(contentsOf: ubiqutios)
        
        switch type {
        case "index", "date_index":
            
            //let allTakeNames = ["name_0001", "name", "name0003", "abc", "abc0001", "wwww0001", "name0567"]
            // get takes which start with name
            let takesWithName = allTakeNames.filter( {(item: String) -> Bool in
                let stringMatch = item.range(of: nameWithSeperator)
                return stringMatch != nil ? true : false
            })
            // get takes with right length
            let filteredLength = takesWithName.filter { word in
                return word.count == nameWithSeperator.count + indexLength
            }
            // get end of take names
            var indexes: [String] = []
            _ = filteredLength.filter { word in
                let f = word[word.index(word.startIndex, offsetBy: nameWithSeperator.count)..<word.endIndex ]
                indexes.append(String(f))
                return (String(f).count == indexLength)
            }
            
            for idx in indexes {
                let iToInt = Int(idx)
                
                if iToInt != nil {
                   // print(iToInt!)
                    maxIdx = max(maxIdx, iToInt!)
                }
            }
            
            // maxIdx to 4 letter string
            
            let formatter = NumberFormatter()
            formatter.minimumIntegerDigits = indexLength
            
            let formattedIndex = formatter.string(from: (maxIdx + 1) as NSNumber)
                
            return formattedIndex!
         
        case "none":
            // no take with name
            if allTakeNames.contains(name) == false {
                return name
            }
            
            // get takes which start with name (less index length)
            var takesWithName = allTakeNames.filter( {(item: String) -> Bool in
                let stringMatch = item.range(of: nameWithSeperator)
                return stringMatch != nil ? true : false
            })
            
            // one take with name without an index
            if takesWithName.isEmpty {
                takesWithName.append(nameWithSeperator)
                maxIdx = 0
            } else {
                // get takes with right length
                let filteredLength = takesWithName.filter { word in
                    return word.count == nameWithSeperator.count + indexLength
                }
                
                // get end of take names
                var indexes: [String] = []
                _ = filteredLength.filter { word in
                    let f = word[word.index(word.startIndex, offsetBy: nameWithSeperator.count)..<word.endIndex ]
                    indexes.append(String(f))
                    return (String(f).count == indexLength)
                }
                
                for idx in indexes {
                    let iToInt = Int(idx)
                    
                    if iToInt != nil {
                       // print(iToInt!)
                        maxIdx = max(maxIdx, iToInt!)
                    }
                }
            }
            
            
            let formatter = NumberFormatter()
            formatter.minimumIntegerDigits = indexLength
            
            let formattedIndex = formatter.string(from: (maxIdx + 1) as NSNumber)
                
            return name + seperator + formattedIndex!
            
        default:
            print("no index1")
        }
        
        return "0001"
    }
    
    /// Return bool if take with takeName exist in takesLocal array
    func takeInLocal(takeName: String) -> Bool {
        return takesLocal.contains(where: { $0.takeName == takeName })
    }
    
    
    // MARK: Take & CoreData
    
    
    /// Load take data from CoreData
    ///
    /// - Parameters:
    ///    - takeName: name of take without extension
    ///
    func loadTakeRecord(takeName: String) -> TakeMO? {
        
        let coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
        let loadedTake = try? coreDataController?.getTake(takeName: takeName)
        
        if (loadedTake?.count)! > 0 {
          
            print(loadedTake?[0].name as Any)
            print("Takes.loadTake: lat: \(String(describing: loadedTake?[0].latitude)), lon: \(String(describing: loadedTake?[0].longitude))")
            return loadedTake?[0]
        }
        
        return nil
    }
    
    /// Validate takes and coreData records. Each record should have a take and each take should have a record
    ///
    /// - Parameter takeMOs: All CoreData take records
    /// 
    func validateCoreDataRecords(takeMOs: [TakeMO]) {
        for take in takeMOs {
            if getDirectoryForFile(takeName: take.name!, takeDirectory: "takes") == nil {
                // no take directory - delete coredate record
                print("Delete coredata record \(take.name!)")
                _ = coreDataController?.deleteTake(takeName: take.name!)
            }
        }
    }
    
    // MARK: Take & ICloud
    /// Take was added to iCloud, add to takesICloud
    func newTakeInICloud(take: Take) {
        takesCloud.append(take)
    }
    
    /// Try to delete take with takeName
    /// Take CoreData data are not deleted
    ///
    /// - parameter takeName: Name of take with file extension
    ///
    func  deleteTake(takeName: String) -> Bool {
        let directoryName = stripFileExtension(takeName)
        guard let takePath = getDirectoryForFile(takeName: directoryName, takeDirectory: "takes") else {
            print("No URL for take directory with name \(takeName)")
            return false
        }
        
        do {
            try FileManager.default.removeItem(at: takePath)
            return true
        } catch {
            print(error.localizedDescription)
        }
        
        return false
    }
    
    
    /// Try to delete take (take data, remove take from takesLocale in Takes.
    /// Remove take's CoreData record?
    ///
    func deleteTake(take: Take) -> Bool {
        guard let takePath = getDirectoryForFile(takeName: take.takeName!, takeDirectory: "takes") else {
            print("No URL for take directory with name \(take.takeName!)")
            return false
        }
        
        do {
            // delete files
            try FileManager.default.removeItem(at: takePath)
            // remove take instance from takesLocal
            if let idx = takesLocal.firstIndex(where: { $0.takeName == take.takeName}) {
                takesLocal.remove(at: idx)
            }
            return true
        } catch {
            print(error.localizedDescription)
        }
        
        return false
    }

    /// Move take from local to icloud.
    /// First remove take from app's documents directory.
    /// The take was already added to iCloud, just update take instance
    ///
    func moveTakeToCloud(take: Take) -> Bool {
        if !takesCloud.contains(where: { $0.takeName == take.takeName}) {
            take.storageState = TakeStorageState.ICLOUD
            take.iCloudState = TakeStorageState.ICLOUD
            
            takesCloud.append(take)
            
            return true
        }
        return false
    }
    
    /// Move take from icloud to local
    ///
    func moveTakeToLocal(take: Take) -> Bool {
        if !takesLocal.contains(where: { $0.takeName == take.takeName }) {
//            take.storageState = .ICLOUD
//            take.iCloudState = .NONE
            
            takesLocal.append(take)
            
            if let idx = takesCloud.firstIndex(where: { $0.takeName == take.takeName}) {
                takesCloud.remove(at: idx)
            }
            return true
        }
        
        return false
    }
    // MARK: Take support data
    
    /**
        Take data are the take, metadata, notes recording and image
     
     */
    func getTakeData(takeName: String) {
        
    }
    
    
    func makeMetadataFile(takeName: String) -> Bool {
        guard let md = loadTakeRecord(takeName: takeName) else {
            return false
        }
        
        let takeMD = md.metadata
        var metaData = [String: String]()
        
        for data in takeMD! {
            if data is MetadataMO {
                let dataMO = data as! MetadataMO
               // print(dataMO.name)
                metaData[dataMO.name!] = dataMO.value
            }
        }
        
        if JSONSerialization.isValidJSONObject(metaData) {
            do {
                let data = try JSONSerialization.data(withJSONObject: metaData, options: .prettyPrinted)
                //let dataString = NSString(data: data, encoding: 8)
                
//                let takeURL = Takes().getUrlforFile(fileName: takeName + ".wav")!
                let takeURL = Takes().getURLForFile(takeName: takeName, fileExtension: "wav", takeDirectory: "takes")
                if JSONParser().write(url: takeURL!, data: data) == false {
                    print("Error writing json")
                    return false
                }
                return true
            } catch {
                print (error)
            }
            
        }
        return false
    }
}
