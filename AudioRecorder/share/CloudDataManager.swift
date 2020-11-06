//
//  CloudDataManager.swift
//  AudioRecorder
//
//  Created by Wolf on 14.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation

class CloudDataManager {
    
    // singelton
    static let sharedInstance = CloudDataManager()
    
    private var metaDataQuery: NSMetadataQuery
    var onChange:((_: Bool) -> Void)?
    
    var cloudURLs: [URL] = []
    
    private init() {
        metaDataQuery = NSMetadataQuery()
    }
    
    
    struct DocumentsDirectory {
        static let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last!
        static let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    /**
     Return the Document directory (Cloud OR Local).
     To do in a background thread.
     
     - returns
    */
    func getDocumentDiretoryURL() -> URL {
        if isCloudEnabled()  {
            return DocumentsDirectory.iCloudDocumentsURL!
        } else {
            return DocumentsDirectory.localDocumentsURL
        }
    }
    
    func isCloudEnabled() -> Bool {
        if DocumentsDirectory.iCloudDocumentsURL != nil {
            print(DocumentsDirectory.iCloudDocumentsURL!)
            return true
        }
        else { return false }
    }
    
    func copyFileToCloud(fileNames: [String]) {
        if isCloudEnabled() {
            do {
                let directoryContents = try FileManager.default.contentsOfDirectory(atPath: DocumentsDirectory.iCloudDocumentsURL!.path)
                
                for fileName in fileNames {
                    if !directoryContents.contains(fileName) {
                       print("copyFileToCloudDrive: \(fileName)")
//                        try FileManager.default.copyItem(at: DocumentsDirectory.localDocumentsURL.appendingPathComponent(fileName, isDirectory: false), to: (DocumentsDirectory.iCloudDocumentsURL?.appendingPathComponent(fileName, isDirectory: false))!)
                        
                        try FileManager.default.setUbiquitous(true, itemAt: DocumentsDirectory.localDocumentsURL.appendingPathComponent(fileName, isDirectory: false), destinationURL: (DocumentsDirectory.iCloudDocumentsURL?.appendingPathComponent(fileName, isDirectory: false))!)
                    } else {
                        print("already in CloudDrive: \(fileName)")
                    }
                    
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func copyFileToCloud() {
        if isCloudEnabled() {
            deleteFilesInDirectory(url: DocumentsDirectory.iCloudDocumentsURL)
            
            let enumerator = FileManager.default.enumerator(atPath: DocumentsDirectory.localDocumentsURL.path)
            while let file = enumerator?.nextObject() as? String {
                do {
                    
                    try FileManager.default.setUbiquitous(true, itemAt: DocumentsDirectory.localDocumentsURL.appendingPathComponent(file, isDirectory: false), destinationURL: (DocumentsDirectory.iCloudDocumentsURL?.appendingPathComponent(file, isDirectory: false))!)
                    
//                    print("copyFileToCloud: \(file) to \(String(describing: DocumentsDirectory.iCloudDocumentsURL))")
//                    //print("path: \(String(describing: DocumentsDirectory.iCloudDocumentsURL?.appendingPathComponent(file, isDirectory: false))) ")
//
//                    try FileManager.default.copyItem(at: DocumentsDirectory.localDocumentsURL, to: DocumentsDirectory.iCloudDocumentsURL!)
////                    try FileManager.default.copyItem(at: DocumentsDirectory.localDocumentsURL, to: DocumentsDirectory.iCloudDocumentsURL!.appendingPathComponent(file, isDirectory: false))
                } catch let error as NSError {
                    print("Failed to move file to Cloud: \(error)")
                }
            }
        }
    }
    
    
    func deleteFilesInDirectory(url: URL?) {
        let enumerator = FileManager.default.enumerator(atPath: DocumentsDirectory.iCloudDocumentsURL!.path)
        while let file = enumerator?.nextObject() as? String {
            print("file to delete: \(file)")
            do {
                try FileManager.default.removeItem(at: DocumentsDirectory.iCloudDocumentsURL!.appendingPathComponent(file, isDirectory: false))
            } catch let error as NSError {
                print("Failed to delete file: \(error.localizedDescription)")
            }
        }
        
    }
    
    /**
     Get all takes not already in CloudDrive
     
     */
    func getNewTakes() -> (url: [URL], name: [String]) {
        
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .fileResourceTypeKey, .isUbiquitousItemKey, .typeIdentifierKey])
        let enumerator = FileManager.default.enumerator(at: DocumentsDirectory.localDocumentsURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)
        
        var fileURLs: [URL] = []
        var fileNames: [String] = []
        
        for case let fileURL as URL in enumerator! {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  let isDirectory = resourceValues.isDirectory,
                  let name = resourceValues.name,
                  let fileTypeKey = resourceValues.fileResourceType,
                  let isUbiquitous = resourceValues.isUbiquitousItem,
                  let typeIdentifierKey = resourceValues.typeIdentifier
            else {
                continue
            }
            
            if isDirectory {
                enumerator?.skipDescendents()
            } else {
                //fileURLs.append(fileURL)
                
                print("name: \(name)")
                print("fileTypeKey: \(fileTypeKey)")
                print("typeIdentifierKey: \(typeIdentifierKey)")
                print("isUbiquitous: \(isUbiquitous)")
                
                if typeIdentifierKey == "com.microsoft.waveform-audio" && !isUbiquitous {
                    fileURLs.append(fileURL)
                    fileNames.append(name)
                }
            }
        }
        return (fileURLs, fileNames)
    }
    
    
    func getTakesInCloud() -> [URL] {
        var URLs: [URL] = []
        
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .typeIdentifierKey])
       
        let directoryEnumerator = FileManager.default.enumerator(at: DocumentsDirectory.iCloudDocumentsURL!, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)
            
            for case let fileURL as URL in directoryEnumerator! {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                      let isDirectory = resourceValues.isDirectory,
                      let name = resourceValues.name,
                      let typeIdentifierKey = resourceValues.typeIdentifier
                else {
                    continue
                }
                
                if typeIdentifierKey == "com.microsoft.waveform-audio" && !isDirectory {
                    print("takeInCloud: \(name)")
                    URLs.append(fileURL)
                }
            }
        return URLs
        
    }
    
    // MARK: MetadataQuery
    /**
     Query at UbiquitousDocumentsScope
     
     */
    func metadataQuery(closure: @escaping (Bool) -> Void) {
        onChange = closure
        metaDataQuery.predicate = NSPredicate(format: "%K.pathExtension = %@", argumentArray: [NSMetadataItemURLKey, "wav"])
        //metaDataQuery?.predicate = NSPredicate(format: "%K like 'SampleDoc.txt'", NSMetadataItemFSNameKey)
        metaDataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        NotificationCenter.default.addObserver(self, selector: #selector(metadataQueryDidFinishGathering(_ :)), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery)
        
        metaDataQuery.start()
    }
    
    
    @objc func metadataQueryDidFinishGathering(_ notification: Notification) -> Void {
        metaDataQuery.disableUpdates()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery)
//        let query: NSMetadataQuery = notification.object as! NSMetadataQuery
//        query.disableUpdates()
        let metadataItems = metaDataQuery.results as! [NSMetadataItem]
        cloudURLs = metadataItems.map{ $0.value(forAttribute: NSMetadataItemURLKey) as! URL }
        
        let result = metaDataQuery.results
        for item in result {
            let itemURL = (item as AnyObject).value(forAttribute: NSMetadataItemURLKey) as! URL
            print(itemURL.path)
        }
        onChange!(true)
    }
}
