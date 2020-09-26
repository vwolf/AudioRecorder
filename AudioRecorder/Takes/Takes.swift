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

class Takes {
    
    /**
     Get all takes in documents directory
     */
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
    
    
    /**
     Does take with takeName exist?
     Is newTakeName unique?
     
     - Parameters:
     - takeName: name of existing take (with extension!)
     - newTakeName: name to change to without extension
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
    
    
    func checkFileName( newTakeName: String, takeName: String, fileExtension: String) -> String {
        guard let takePath = getUrlforFile(fileName: "\(takeName).\(fileExtension)") else {
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
    
    
    // MARK: Take & CoreData
    
    /**
     Load take data from CoreData
     
     - Parameters:
        - takeName: name of take without extension
    */
    func loadTake(takeName: String) -> TakeMO? {
        
        let coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
        let loadedTake = coreDataController?.getTake(takeName: takeName)
        
        if (loadedTake?.count)! > 0 {
            print("take loaded: \(String(describing: loadedTake?[0].name))")
            
//            let takeMetaDataItems = coreDataController?.getMetadataForTake(takeName: takeName)
            
//            for mdItem in takeMetaDataItems! {
//                guard let itemName = mdItem.name else {
//                    break
//                }
//
////                // itemName from CoreData is item.id
////                if getItemForID(id: itemName) != nil {
////                    // remove item
////                    deleteItem(id: itemName)
////                }
//
//                switch itemName {
//                case "addCategory":
//                    let category = mdItem.value
//                    guard let subCategory = takeMetaDataItems?.first(where: { $0.name == "addSubCategory"}) else {
//                        print("Subcategory not set")
//                        //self.addCategory()
//                        break
//                    }
//
//                default:
//                    print("Unkown item name \(String(describing: mdItem.name))")
//                }
//            }
            return loadedTake?[0]
        }
        
        return nil
    }
    
    /**
     Try to delete take with takeName
     Take CoreData data are not deleted
     
     - parameter takeName: Name of take with file extension
    */
    func  deleteTake(takeName: String) -> Bool {
        guard let takePath = getUrlforFile(fileName: takeName) else {
            print("No URL for take with name \(takeName)")
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
    
    func makeMetadataFile(takeName: String) -> Bool {
        guard let md = loadTake(takeName: takeName) else {
            return false
        }
        
        let takeMD = md.metadata
        //print("Custom metadata count: \(takeMD?.count)")
        
        var metaData = [String: String]()
        
        // add location
//        if md.latitude != 0.0 {
//            metaData["latitude"] = String(md.latitude)
//            metaData["longitude"] = String(md.longitude)
//        }
        
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
                
                let takeURL = Takes().getUrlforFile(fileName: takeName + ".wav")!
                
                if JSONParser().write(url: takeURL, data: data) == false {
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
