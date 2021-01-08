//
//  Take.swift
//  Take object, to record or existing
//
//  AudioRecorder
//
//  Created by Wolf on 31.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreLocation
import CloudKit

/// Take properties
/// Each property is an MetaDataItem and belongs to a Section.
/// Metadata items are saved to coredata record.
/// Coredata record of take should always reflect the state of take instance.
///
class Take {
    
    var items = [[MetaDataItem]]()
    var itemSections = [MetaDataSections]()
    
    // MARK: Take properties
    
    /// Full path to recorded take
    var url: URL?
    var takePath: String = ""
    
    /// Name of take without extension
    var takeName: String?
    
    /// Type of recorded take
    var takeType: String?
    
    var recordedAt: Date?
    var takeLength: Double = 0
    
    var location: CLLocation?
    var newTake = true
    var takeSaved = false
    var takeModified = false
    
    var storageState = TakeStorageState.LOCAL
    var iCloudState = TakeStorageState.NONE
    var iDriveState = TakeStorageState.NONE
    var dropboxState = TakeStorageState.NONE
    
    var takeFormat: AudioFormatDescription?
    
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
    
    init() {}
    
    /// 
    init(takeName: String) {
        
    }
    
    /// Reimport take
    /// Metadata.json file?
    ///
    
    init(takeURL: URL, metaDataURL: URL?) {
        // set takeName and takeType and get items
        var recordingDataItems = self.setURL(takeURL: takeURL)
        print("take name: \(String(describing: takeName))")
        do {
            let takeAttributes = try FileManager.default.attributesOfItem(atPath: takeURL.path)
            
            if let creationDate = takeAttributes[.creationDate] as? Date {
                //creationDate.toString(dateFormat: "dd, mm, yy" )
                recordingDataItems.append(self.setRecordedAt(date: creationDate))
            }
            
            
            
            // location only if metadata file url
            if metaDataURL != nil {
                if let parserResult = JSONParser().parseJSONFile(metaDataURL!) as? [String: Any] {
                    if parserResult.contains(where: { $0.key == "latitude" }) {
                        if let lat = parserResult["latitude"] as? Double {
                            if parserResult.contains(where: { $0.key == "longitude"}) {
                                if let lon = parserResult["longitude"] as? Double {
                                    let userLocation = CLLocation(latitude: lat, longitude: lon)
                                    recordingDataItems.append(self.setLocation(location: userLocation))
                                   
                                }
                            }
                        }
                    }
                    
                    for item in parserResult {
                        print(item.key)
                        switch item.key {
                        case "category" :
                            if parserResult.contains(where: { $0.key == "subCategory" }) {
                                let subCategory = parserResult["subcategory"] as? String
                                if let category = parserResult["category"] as? String {
                                    let categories = addCategory(category: category, subCategory: subCategory ?? "")
                                    addItem(item: categories, section: .METADATASECTION)
                                }
                            }
                        default:
                            print(item.key)
                        }
                    }
                    
                    if parserResult.contains(where: { $0.key == "length" }) {
                        if let length = parserResult["length"] as? Double {
                            takeLength = length
                        }
                        //recordingDataItems.append(self.setRecordedAt(date: creationDate))
                    } else {
                        // get length of take if not already set in metadata
                        let audioPlayer = try AVAudioPlayer(contentsOf: takeURL)
                        takeLength = audioPlayer.duration
                    }
                    
                    // Description
                    if parserResult.contains(where: { $0.key == "description"}) {
                        if let description = parserResult["description"] as? String {
                            addDescription(description: description)
                        }
                    }
                    // Image
                    if parserResult.contains(where: { $0.key == "image"}) {
                        if let imageDescription = parserResult["image"] as? String {
                            addImage(imageURL: imageDescription)
                        }
                    }
                    // Note
                    
                }
                
            }
            
            itemSections.append(MetaDataSections.RECORDINGDATA)
            items.append(recordingDataItems)
            
            saveTake()
        } catch {
            
        }
    }
    
    
    /// Init new recorded take
    ///
    init(takeURL: URL, date: Date, userLocation: CLLocation?, length: Double) {
        // set takeName and takeType and get items
        var recordingDataItems = self.setURL(takeURL: takeURL)
        // recorded at
        recordingDataItems.append(self.setRecordedAt(date: date))
        // location
        if userLocation != nil {
            recordingDataItems.append(self.setLocation(location: userLocation!))
        }
        /// take length
        takeLength = length
    
        itemSections.append(MetaDataSections.RECORDINGDATA)
        items.append(recordingDataItems)
        
    }
    
    
    /// Init take from CoreData entry.
    /// First add recording data (name, location, recording date, filePath)
    /// Then read metadata from db
    /// Next add default metadata items, which have no entry in db
    ///
    /// - Parameter takeMO:
    init(withTakeMO takeMO: TakeMO) {
        takeName = takeMO.name!
        takeLength = takeMO.length
        
        self.addRecordingData(takeMO: takeMO)
        
        /// Add saved MetaData in CoreData?
        getMetaDateForTake(takeNameWithoutExtension: takeName!)
        
        /// Default Metadata
        self.addDefaultMetaData()
        
        _ = self.sortMetadataForDisplay()
        
        // take format info
        // take can be in iDrive, so no access to takeFormat
        if Takes().getURLForFile(takeName: takeName!, fileExtension: takeType!, takeDirectory: "takes") != nil {
            self.takeFormat = self.getTakeFormat()
            if self.takeFormat != nil {
                let formatString = formatTakeFormat()
                addAudioFormatData(formatString: formatString)
            }
        }
        
        
        /// take in iCloud, iDrive, Dropbox?
        if (TakeCKRecordModel.sharedInstance.getTakeCKRecord(takeName: takeName!) != nil) {
            storageState = .ICLOUD
            iCloudState = .ICLOUD
        }
        
        if (Takes.sharedInstance.takesDropbox.contains(where: { $0.takeName == takeName})) {
            dropboxState = .DROPBOX
        }
        
        //        let group = DispatchGroup()
        //        group.enter()
        //        DispatchQueue.global(qos: .default).async {
        //            self.takeFormat = self.getTakeFormat()
        //            group.leave()
        //        }
        //        group.wait()
    }
    
    /// Take from TakeCKRecord. These are always .ICOUD takes.
    /// This takes should have a CoreData record.
    ///
    init(takeCKRecord: TakeCKRecord, takeName: String) {
        // takename in takeRecord is with file extension
        self.takeName = takeName
        // let url = takeCKRecord.audioAsset.fileURL
        
        iCloudState = .ICLOUD
        storageState = .ICLOUD
        // print("ICLOUD TAKE: \(takeName), \(url)")
    }
    
    /// Use to add a Dropbox take to takes
    ///
    init(takeName: String, storageState: TakeStorageState) {
        self.takeName = takeName
        self.storageState = storageState
        
        if storageState == .DROPBOX {
            // is there a take with dame name?
            
        }
    }
    
    
    /// Add data generated at recording of take
    ///
    private func addRecordingData(takeMO: TakeMO) {
        var recordingData = [MetaDataItem]()
        
        url = URL(fileURLWithPath: takeMO.filepath!)
        let urlItems = self.setURL(takeURL: URL(fileURLWithPath: takeMO.filepath!))
        recordingData.append(contentsOf: urlItems)
        
        if takeMO.latitude != 0 {
            let takeLocation = CLLocation(latitude: takeMO.latitude, longitude: takeMO.longitude)
            let locationItem = self.setLocation(location: takeLocation)
            recordingData.append(locationItem)
        }
        
        let recordedAtItem = self.setRecordedAt(date: takeMO.recordedAt!)
        recordingData.append(recordedAtItem)
        
        itemSections.append(MetaDataSections.RECORDINGDATA)
        items.append(recordingData)
    }
    
    /// Default MetaData are
    /// Category. Description
    ///
    private func addDefaultMetaData() {
       
        if getItemForID(id: "category", section: .METADATASECTION) == nil {
            let categories = addCategory()
            addItem(item: categories, section: .METADATASECTION)
        }
        
        if getItemForID(id: "description", section: .METADATASECTION) == nil {
            let description = addDescription(description: "aDescription")
            addItem(item: description, section: .METADATASECTION)
        }
        
//        if getItemForID(id: "keyboard", section: .METADATASECTION) == nil {
//            let descriptionDesc = MetaDataDefault().keyboard
//            let keyboardItem  = MetaDataItem(description: descriptionDesc, value: "keyboard test item")
//            addItem(item: keyboardItem, section: .METADATASECTION)
//        }
    }
    
    private func addAudioFormatData(formatString: String) {
        if getItemForID(id: "addTakeFormat", section: .TAKEFORMAT) == nil {
            let descriptionDesc = MetaDataDefault().takeFormat
            let addTakeFormat = MetaDataItem(description: descriptionDesc, value: formatString)
            addItem(item: addTakeFormat, section: .TAKEFORMAT)
        }
        
        itemSections.append(MetaDataSections.TAKEFORMAT)
    }
    
    
    private func formatTakeFormat() -> String {
        return (takeFormat?.asString())!
    }
    
    /**
     Entry point for new recorded take
     Save new recorded take file name and url as MetaDataItem
     
     - parameter url: full path to new record
    */
    func setURL(takeURL: URL) -> [MetaDataItem] {
        var metaDateItems = [MetaDataItem]()
        
        // new metadata description
        let takeNameDesc = MetaDataDefault().takeName
        takeType = takeURL.pathExtension
        takeName = takeURL.deletingPathExtension().lastPathComponent
        //takeName = pathNoExtension.lastPathComponent
        let takeNameItem = MetaDataItem(description: takeNameDesc, value: takeName!)
        metaDateItems.append(takeNameItem)
        
        //let pathDesc = MetaDataDefault().path
        //let pathItem = MetaDataItem(description: pathDesc, value: takeURL.path)
        //metaDateItems.append(pathItem)
        
        url = takeURL
        takePath = takeURL.path
        
        return metaDateItems
    }
    
    
    func setLocation(location: CLLocation) -> MetaDataItem {
        //print("Take.location: \(location)")
        let locationDesc = MetaDataDefault().location
//        let locationValue = "Lat: \(location.coordinate.latitude) Lon: \(location.coordinate.longitude)"
        let locationValue = ["lat" : location.coordinate.latitude, "lon": location.coordinate.longitude]
        let takeLocation = MetaDataItem(description: locationDesc, value: locationValue)
        
        //items.append(takeLocation)
        //let loction = MetadataItem(type: MetadataItem.String, id: <#T##String#>)
        self.location = location
        return takeLocation
    }
    
    func setRecordedAt(date: Date) -> MetaDataItem {
        let recordingTimeDesc = MetaDataDefault().creationDate
        
        let takeRecordingTime = MetaDataItem(description: recordingTimeDesc, value: date.toString(dateFormat: "dd.MM.YY' at' HH:mm:ss"))
//        items.append(takeRecordingTime)
        self.recordedAt = date
        return takeRecordingTime
    }
    
    // MARK: MetaData
    
    func addCategory(category: String = "", subCategory: String = "") -> MetaDataItem {
        
//        let activeItemDescription = ["id": "addCategory",
//                                     "type": MetaDataTypes.STRING.rawValue,
//                                     "name": "Category",
//                                     "description": "Add Category"]
        let categoryDesc = MetaDataOptional().category
        let activeItem = MetaDataItem(description: categoryDesc, value: category)
        
        let subCategoryItem = getSubCategory(subCategory: subCategory)
        activeItem.addChild(child: subCategoryItem)
        //items.append(activeItem)
        
        return activeItem
    }
    
    /**
     A sub category is a child of a category
    */
    func getSubCategory(subCategory: String = "") -> MetaDataItem {
        let subCategoryDesc = MetaDataOptionalSub().subCategory
       // let activeItemDesc = ["id": "addSubCategory", "type": MetaDataTypes.STRING.rawValue, "name": "Add Subcategory", "description": "Add a Subcategory"]
        let activeItem = MetaDataItem(description: subCategoryDesc, value: subCategory)
        return activeItem
    }
    
    func addDescription(description: String = "") -> MetaDataItem {
        let descriptionDesc = MetaDataOptional().description
        let descriptionItem  = MetaDataItem(description: descriptionDesc, value: description)
        
        return descriptionItem
    }
    
    func addImage(imageURL: String = "") -> MetaDataItem {
        let imageDesc = MetaDataOptional().image
        let imageItem = MetaDataItem(description: imageDesc, value: imageURL)
        
        return imageItem
    }
    
    func addAudio(audioURL: String = "") -> MetaDataItem {
        let audioDesc = MetaDataOptional().audio
        let audioItem = MetaDataItem(description: audioDesc, value: audioURL)
        
        return audioItem
    }
    
    
    // MARK: CoreData
    
    /**
     Save new take or update take in CoreData.
     This are all default values, no user defined ones.
     If fileName different to original, update fileName and filePath.
     Rename file.
     */
    func saveTake(writeJson: Bool = false) {
        if newTake == true {
            let rename = renameTake(takeURL: url!)
            if rename.result == true {
                takeName = rename.name
                url = url?.deletingLastPathComponent().appendingPathComponent(rename.name!)
            }
            //print("saveTake.latitude: \(location?.coordinate.latitude)")
            guard (coreDataController?.seedTake(name : takeName!,
                                                filePath: takePath,
                                                recordeAt: recordedAt!,
                                                length: takeLength,
                                                latitude: location?.coordinate.latitude,
                                                longitude: location?.coordinate.longitude)) != nil else {
                                                    
                                                    print("error saving take")
                                                    return
            }
            
            saveMetaDataForTake(takeNameWithExtension: takeName!)
            takeSaved = true
            
            
            if writeJson {
                writeJsonForTake() { result, error in
                    print("writeJsonForTake: \(result)")
                }
            }
        } else {
            updateTake()
        }
    }
    
    
    
    /**
     Update take: take name changed - update filePath and file
     Compare property takeName with item takeName.value (both are without extension)
     
     */
    func updateTake() {
        print("updateTake: \(String(describing: takeName))")
        
        // takeName changed?
        guard let takeNameItem = items[0].first(where: { $0.id == "takeName"}) else {
            print("Error no item takeName")
            return
        }
        let takeNameInItem = takeNameItem.value as! String
        let takeNameWithExtension = takeName?.appending(".").appending(takeType!)
        
        if (takeNameInItem != takeName) {
            let newTakeNameWithExtension = takeNameInItem.appending(".").appending(takeType!)
            let renamed = Takes().renameTake(takeName: (url?.lastPathComponent)!, newTakeName: newTakeNameWithExtension)
            if renamed {
                let newPath = url?.deletingLastPathComponent().appendingPathComponent(newTakeNameWithExtension)
                url = newPath
                
                if  coreDataController?.updateTake(takeNameToUpdate: takeNameWithExtension!,
                                                   name : newTakeNameWithExtension,
                                                   filePath : (url?.absoluteString)!,
                                                   recordedAt: recordedAt!,
                                                   latitude: location?.coordinate.latitude,
                                                   longitude: location?.coordinate.longitude ) == true {
                    
                    saveMetaDataForTake(takeNameWithExtension : takeNameWithExtension!)
                }
            }
        } else {
            // update user defined metadata
            updateMetaDataForTake(takeNameWithExtension : takeNameWithExtension!)
        }
    }
    
    /**
     Is name in takeName item different to poperty takeName then try to rename.
     Updata name of audio note.
     
     - Parameters:
     - takeURL:
     - newName: new name of take without extension
     */
    func renameTake(takeURL: URL) -> (result: Bool, name: String?) {
        // get takeName from item
        if items.isEmpty {
            return(false, nil)
        }
        guard let takeNameItem = items[0].first(where: { $0.id == "takeName"} ) else {
            print("No item with id = takeName")
            return (false, nil)
        }
        let takeNameInItem = takeNameItem.value as! String
        
        // takeName changed?
        if takeNameInItem != takeName {
            let renamed = Takes().renameTake(takeURL: takeURL, newTakeName: takeNameInItem)
            if renamed {
                // rename take in CoreData
                //coreDataController?.updateMetadataForTake(takeName: takeNameInItem, metadata: <#T##Dictionary<String, String>#>)
//                if var noteURL = getNoteForTake() {
//
//                }
                // update to new name and path
                return (true, takeNameInItem)
            }
        }
        
        return (false, nil)
    }
    
    /**
     Rename note file
     
     - parameters oldName: file name with extension
     - parameters newName: file name without extension
     */
    func renameTakeNote(oldName: String, newName: String) {
        if let noteURL = getNoteForTake() {
            let fextension = noteURL.pathExtension
            var newNoteURL = noteURL.deletingLastPathComponent()
            newNoteURL.appendPathComponent(newName)
            newNoteURL.appendPathExtension(fextension)
            
            do {
                try FileManager.default.moveItem(at: noteURL, to: newNoteURL)
            } catch {
                print("Error renaming file: \(error.localizedDescription)")
            }
        }
    }
    
    
    /**
     Read saved MetaData from CoreData MetaDataMO
     
     */
    func getMetaDateForTake(takeNameWithoutExtension: String) {
        var mdItems = [MetaDataItem]()
        let takeMetaDataItems = coreDataController?.getMetadataForTake(takeName: takeNameWithoutExtension)
        
        for mdItem in takeMetaDataItems! {
            guard let itemName = mdItem.name else {
                break
            }
            
            switch itemName {
            case "category":
                let category = mdItem.value
                
                guard let subCategory = takeMetaDataItems?.first(where: { $0.name == "subCategory"}) else {
                    mdItems.append(addCategory(category: category!))
                    break
                }
                let categoryItem = addCategory(category: category!, subCategory: subCategory.value!)
                
                mdItems.append(categoryItem)
    
                
            case "description":
                let description = mdItem.value
                let descriptionItem = addDescription(description: description!)
                
                mdItems.append(descriptionItem)
             
            case "image" :
                let image = mdItem.value
                let imageItem = addImage(imageURL: image!)
                
                mdItems.append(imageItem)
            
            case "audio":
                let audio = mdItem.value
                let audioItem = addAudio(audioURL: audio!)
                
                mdItems.append(audioItem)
                
            default:
                print("Unkown item name \(String(describing: mdItem.name))")
            }
        }
        
        itemSections.append(MetaDataSections.METADATASECTION)
        items.append(mdItems)
    }
    
    func getTakeFormat() -> AudioFormatDescription? {
        //let takeNameWithExtension = takeName! + "." + takeType!
        //let takeURL = Takes().getUrlforFile(fileName: takeNameWithExtension)
        let takeURL = Takes().getURLForFile(takeName: takeName!, fileExtension: takeType!, takeDirectory: "takes")
        let asset = AVAsset(url: takeURL!)
        let assetTrack = asset.tracks
        
        var formatStruct = AudioFormatDescription()
        
        guard let firstTrack = assetTrack.first else {
            return nil
        }
        
        let audioFormatDescriptions = firstTrack.formatDescriptions as! [CMAudioFormatDescription]
        guard let audioFormatDescription = audioFormatDescriptions.first else {
            print("Error: Take has no CMAudioFormatDescription")
            return formatStruct
        }
        
        var formatList = [Int]()
        let mediaSpecific = CMAudioFormatDescriptionGetFormatList(audioFormatDescription, sizeOut: &formatList)
        // format lpcm == wav
        let type = mediaSpecific?.pointee.mASBD.mFormatID
        formatStruct.type = type!.toString()
        
        let sampleRate = mediaSpecific?.pointee.mASBD.mSampleRate
        formatStruct.sampleRate = sampleRate!
        
        let channelsPerFrame = mediaSpecific?.pointee.mASBD.mChannelsPerFrame
        formatStruct.channelsPerFrame = channelsPerFrame!
        
        let bitsPerChannel = mediaSpecific?.pointee.mASBD.mBitsPerChannel
        formatStruct.bitPerChannel = bitsPerChannel
        
        let bytesPerFrame = mediaSpecific?.pointee.mASBD.mBytesPerFrame
        formatStruct.bytesPerFrame = bytesPerFrame!
        
        return formatStruct
        
//        let workItem = DispatchWorkItem {
//            print("dispatchWorkItem")
//        }
//
//        let queue = DispatchQueue.global()
//        queue.async {
//            workItem.perform()
//        }
//
//        workItem.notify(queue: DispatchQueue.main) {
//
//        }
        
//        let group = DispatchGroup()
//        group.enter()
//        DispatchQueue.global(qos: .default).async {
//
//            firstTrack.loadValuesAsynchronously(forKeys: ["estimatedDataRate"]) {
//                var error: NSError? = nil
//                let status = firstTrack.statusOfValue(forKey: "estimatedDataRate", error: &error)
//
//                if status == .loaded {
//                    print("trackId: \(firstTrack.estimatedDataRate)")
//                    print("formatDescription: \(firstTrack.formatDescriptions)")
//                    print("preferredVolume: \(firstTrack.preferredVolume)")
//                    //print("metadata: \(firstTrack.metadata)")
//
//                    //let formatDescription = firstTrack.formatDescriptions as! [CMFormatDescription]
//                    let audioFormatDescriptions = firstTrack.formatDescriptions as! [CMAudioFormatDescription]
//                    guard let audioFormatDescription = audioFormatDescriptions.first else {
//                        print("Error: Take has no CMAudioFormatDescription")
//                        return
//                    }
//
//                    var formatList = [Int]()
//                    let mediaSpecific = CMAudioFormatDescriptionGetFormatList(audioFormatDescription, sizeOut: &formatList)
//                    // format lpcm == wav
//                    let type = mediaSpecific?.pointee.mASBD.mFormatID
//                    formatStruct.type = type!.toString()
//
//                    let sampleRate = mediaSpecific?.pointee.mASBD.mSampleRate
//                    formatStruct.sampleRate = sampleRate!
//
//                    let channelsPerFrame = mediaSpecific?.pointee.mASBD.mChannelsPerFrame
//                    formatStruct.channelsPerFrame = channelsPerFrame!
//
//                    let bitsPerChannel = mediaSpecific?.pointee.mASBD.mBitsPerChannel
//                    formatStruct.bitPerChannel = bitsPerChannel
//
//                    let bytesPerFrame = mediaSpecific?.pointee.mASBD.mBytesPerFrame
//                    formatStruct.bytesPerFrame = bytesPerFrame!
//
//                }
//            }
//
//            group.leave()
//        }
//
//        group.wait()
//
//        return formatStruct
    }
                

    
    /**
     Save user generatet metadata
     [Category, SubCategory, Description, Image, Supporting Recording]
     Extract this ones from items, use item.id as metadata name
     
     */
    func saveMetaDataForTake(takeNameWithExtension : String) {
        var skip = ["creationDate"]
        
        let takeNameWithoutExtension = Takes().stripFileExtension(takeNameWithExtension)
        if takeNameWithoutExtension != takeName {
            takeName = takeNameWithoutExtension
        } else {
            skip.append("takeName")
            skip.append("path")
        }
        
        let dataDict = makeTakeForSaving(skip: skip)
        
        coreDataController?.seedMetadataForTake(takeName: takeNameWithExtension, metadata: dataDict)
    }
    
    /**
     Update MetaData
     Check for changed take name -> save RECORDINGDATA section
     
     */
    func updateMetaDataForTake(takeNameWithExtension: String) {
        var skip = ["creationDate"]
        
        let takeNameWithoutExtension = Takes().stripFileExtension(takeNameWithExtension)
        let takeNameInItem = getItemForID(id: "takeName", section: .RECORDINGDATA)
        let tn = takeNameInItem!.value as! String
        // let tnWithExtension = tn + "." + takeType!
        
        if takeNameWithoutExtension != tn {
            takeName = takeNameWithoutExtension
            if updateItem(id: "takeName", value: tn, section: .RECORDINGDATA) == false {
                NSLog("Error updateing item takename to \(tn)")
            }
            
            if let newNameURL = Takes().getURLForFile(takeName: tn, fileExtension: "wav", takeDirectory: "takes") {
            //if let newNameURL = Takes().getUrlforFile(fileName: tnWithExtension)  {
                // first save new take name
                if coreDataController?.updateTake(takeNameToUpdate: takeName!, name: tn, filePath: newNameURL.path, recordedAt: recordedAt!, latitude: location?.coordinate.latitude, longitude: location?.coordinate.longitude) == true {
                    
                    // update metadata
                    let dataDict = makeTakeForSaving(skip: skip)
                    coreDataController?.updateMetadataForTake(takeName: takeNameWithoutExtension, metadata: dataDict)
                }
            }
            
            //updateItem(id: "path", value: <#T##String#>, section: .RECORDINGDATA)
        } else {
            skip.append("takeName")
            skip.append("path")
            
            let dataDict = makeTakeForSaving(skip: skip)
            coreDataController?.updateMetadataForTake(takeName: takeNameWithoutExtension, metadata: dataDict)
        }
        
    }
    
    
    private func makeTakeForSaving(skip: [String] ) -> [String: String] {
        var metaDataDict = [String: String]()
        
        for itemArray in items {
            for item in itemArray {
                if skip.contains(item.id) == false {
                    metaDataDict[item.id] = item.value as? String
                    // any children?
                    if (item.children != nil) {
                        //if (item.children?.count)! > 0 {
                        for child in item.children! {
                            metaDataDict[child.id] = child.value as! String?
                        }
                    }
                }
            }
        }
        
        return metaDataDict
    }
    
    // MARK: Services
    
    
    /// Return path url
    ///
    /// - returns url to take in documents directory
    ///
    func getTakeURL() -> URL? {
        let takeURL = Takes().getURLForFile(takeName: takeName!, fileExtension: takeType!, takeDirectory: "takes")!
        
        if FileManager.default.fileExists(atPath: takeURL.path) {
            return takeURL
        }
        
        return nil
    }
    
    /// Return take folder url
    ///
    func getTakeFolder() -> URL? {
        if let takeFolderURL = Takes().getDirectoryForFile(takeName: takeName!, takeDirectory: "takes") {
            return takeFolderURL
        }
        return nil
    }
    
    /**
     Add a MetadataItem
     
     - parameters item: item objcect
     */
    func addItem(item: MetaDataItem, section: MetaDataSections) {
        guard let sectionIndex = getItemSectionIndex(section: section) else {
            // no section, create section
            let sectionArray = [item]
            items.append(sectionArray)
            return
        }
        // section exist, add item
        items[sectionIndex].append(item)
    }
    
    /**
     Add new item to take
     Create the item then add
     */
    func addItem(name: String, section: MetaDataSections) -> Bool {
        if section == .METADATASECTION {
            // get description from MetaDataOptional
            switch name {
            case "Image":
                let itemDescription = MetaDataOptional().image
                let item = MetaDataItem(description: itemDescription, value: "")
                addItem(item: item, section: .METADATASECTION)
                
            case "Audio" :
                let itemDescription = MetaDataOptional().audio
                let item = MetaDataItem(description: itemDescription, value: "")
                addItem(item: item, section: .METADATASECTION)
                
            default:
                print("Unknow item name \(name)")
                return false
            }
            
            updateTake()
        }
        return true
    }
    
    /**
     Check section for item
     */
    func getItemForID(id: String, section: MetaDataSections) -> MetaDataItem? {
        guard let sectionIndex = itemSections.firstIndex(of: section) else { return nil }
        guard let item = items[sectionIndex].first(where: { $0.id == id }) else {
            return nil
        }
        return item
    }
    
    func updateItem(id: String, value: String, section: MetaDataSections) -> Bool {
        guard let sectionIndex = itemSections.firstIndex(of: section) else { return false }
        guard let item = items[sectionIndex].first( where: { $0.id == id }) else {
            return false
        }
        item.value = value
        return true
    }
    
    func deleteItem(id: String, section: MetaDataSections) -> Bool? {
        guard let sectionIndex = itemSections.firstIndex(of: section) else { return false }
        guard let idx = items[sectionIndex].firstIndex(where: {$0.id == id}) else {
            return nil
        }
        items[sectionIndex].remove(at: idx)
        return true
        
    }
        
    func getHeaderForSection(sectionIndex: Int) -> String? {
        if sectionIndex < itemSections.count {
            return itemSections[sectionIndex].rawValue
        }
        //guard var sectionDescription = itemSections[sectionIndex] else { return nil }
        
        return "?"
    }
    
    func getHeaderIDForSection(sectionIndex: Int) -> MetaDataSections? {
        if sectionIndex < items.count {
            return itemSections[sectionIndex]
        }
        return nil
    }
    
    
    func getItemSectionIndex(section: MetaDataSections) -> Int? {
        guard let sectionIndex = itemSections.firstIndex(of: section) else { return nil }
        return sectionIndex
    }
    
    func getItemIndexInSection(id: String, section: MetaDataSections) -> Int? {
        guard let sectionIndex = getItemSectionIndex(section: section ) else {
            return nil
        }
        
        guard let itemIndex = items[sectionIndex].firstIndex(where: {$0.id == id}) else {
            return nil
        }
        
        return itemIndex
    }
    
    /// Returns the metadata file url
    ///
    func metadataFile() -> URL? {
        guard let metadataFileUrl = url?.deletingPathExtension().appendingPathExtension("json") else {
            return nil
        }
        if FileManager.default.fileExists(atPath: metadataFileUrl.path) {
           return metadataFileUrl
        }
        return nil
    }
    
    /**
     Does a recorded note for take exist?
     Save note to take directory
     
     - return URL?
     */
    func getNoteForTake() -> URL? {
        let notesDirectoryName = RecordingTypes.TAKE.rawValue
        var notesDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        notesDirectory.appendPathComponent(notesDirectoryName, isDirectory: true)
        notesDirectory.appendPathComponent(takeName!, isDirectory: true)
        
        var noteForTakeURL = notesDirectory.appendingPathComponent(takeName! + AppConstants.notesFileExtension.rawValue)
        noteForTakeURL.appendPathExtension(takeType!)
        if FileManager.default.fileExists(atPath: noteForTakeURL.path) {
            return noteForTakeURL
        }
        return nil
    }
    
    /// This add's an image to take. Copy image into take directory and save image name as metadataItem value.
    /// Delete existing metadata image and update metadateItem value.
    ///
    /// - Parameter imageURL
    ///
    func addImageToTake(imageURL: URL, completion: ((URL, Error?) -> Void) ) {
        if let takeURL = getTakeURL() {
            let takeFolderURL = takeURL.deletingLastPathComponent()
            let destinationURL = takeFolderURL.appendingPathComponent(imageURL.lastPathComponent)
            
            do {
                try FileManager.default.copyItem(at: imageURL, to: destinationURL)
                
                // there should always be a imageItem!
                if let imageItem = getItemForID(id: "image", section: .METADATASECTION) {
                    if imageItem.value as? String != "" {
                        // remove previous imgage and update metadata item
                        let previousImagePath = imageItem.value as? String
                        let previousImageURL = takeFolderURL.appendingPathComponent(previousImagePath!)
                        // valid image url?
                        if FileManager.default.fileExists(atPath: previousImageURL.path) {
                            if FileManager.default.isDeletableFile(atPath: previousImageURL.path) {
                                try FileManager.default.removeItem(atPath: previousImageURL.path)
                                imageItem.value = imageURL.lastPathComponent
                            }
                        } else {
                            imageItem.value = imageURL.lastPathComponent
                        }
                    } else {
                        _ = updateItem(id: "image", value: imageURL.lastPathComponent, section: .METADATASECTION)
                    }
                    updateTake()
                    completion(destinationURL, nil)
                }
            } catch {
                print(error.localizedDescription)
                completion(destinationURL, error)
            }
        }
    }
    
    func sortMetadataForDisplay() -> Bool?{
        let itemOrder = MetaDataOptional().itemOrder
        
        guard let sectionIdx = getItemSectionIndex(section: .METADATASECTION) else {
            return nil
        }
        items[sectionIdx].sort(by: {itemOrder.firstIndex(of: $0.id)! < itemOrder.firstIndex(of: $1.id)! } )
            
        return true
    }

    /// To move a take from iCloud to app's documents directory is only possible if
    /// - no take with same name exist in app
    /// - there is a TakeCKRecord in TakeCKRecordModel with matching name
    ///
    func canMoveTakeToLocal() throws {
        if (Takes.sharedInstance.takeInLocal(takeName: takeName!)) {
            //return TakeError.NameNotUnique(takeName ?? "unknown")
            throw TakeError.NameNotUnique(takeName ?? "unknown")
        }
        if !TakeCKRecordModel.sharedInstance.takeCKRecordExist(takeName: takeName!) {
            throw TakeError.NoTakeCKRecord
        }
    }
    
    /// Copy assets of iCloud take to app's documents directory
    ///
    func copyAssetsToLocal() {
        // copy files to app directory "takes/takeName"
        var documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentPath.appendPathComponent("takes/\(takeName!)", isDirectory: true)
        
        // take assets to copy: take, metadata, note, image
        let assetFields = ["take": "wav", "metadata": "json", "note": "wav", "image": "png"]
        
        // get record
        guard let takeCKRecord = TakeCKRecordModel.sharedInstance.getTakeCKRecord(takeName: takeName!) else {
            print("No iCloud Record for take \(takeName!)")
            return
        }
        
        // fetch record
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: takeCKRecord.record.recordID) { [unowned self] record, error in
            if (error != nil) {
                print(error?.localizedDescription)
            } else {
                if let record = record {
                    // first create take directory
                    do {
                        try FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil)
                        var fileCount = 0
                        // get all assets and copy
                        for asset in assetFields {
                            if let takeAsset = record[asset.key] as? CKAsset {
                                let takeURL = takeAsset.fileURL
                                let takeDestinationURL = documentPath.appendingPathComponent(takeName!).appendingPathExtension(asset.value)
                                fileCount += 1
                                print("fileCount + :\(fileCount)")
                                assetToApp(assetURL: takeURL!, destinationURL: takeDestinationURL) { result in
                                    if result {
                                        print("Take \(takeName!) \(asset) copy to app")
                                        fileCount -= 1
                                        //if fileCount == 0 { deleteTakeFromICloud(recordID: record.recordID, takeURL: documentPath)}
                                    }
                                }
                            }
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                
            }
        }
        
        
    }
    
    
    /// A cloud take should become a local take.
    /// Takename has to be unique. This always adds a new take to app.
    ///
    /// 1. Copy take to app's document directory and remove from cloud
    /// 2. Get audio format details and save coredata record
    ///
    func cloudTakeToLocal(completion: @escaping (String) -> Void) {
        guard let takeCKRecord = TakeCKRecordModel.sharedInstance.getTakeCKRecord(takeName: takeName!) else {
            print("No iCloud Record for take \(takeName!)")
            completion("No TakeCKRecord")
            return
        }
        
        // only proceed if no take with same name in takesLocal
        if !(Takes.sharedInstance.takeInLocal(takeName: takeName!)) {
            
        } else {
            completion("Take exist!")
            return
        }
        
        // assets: take, metadata, note, image
        // let assetFields = ["take", "metadata", "note", "image"]
        
        // is there a local take with same name?
        if !(Takes.sharedInstance.takeInLocal(takeName: takeName!)) {
            // copy files to app directory "takes/takeName"
            var documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentPath.appendPathComponent("takes/\(takeName!)", isDirectory: true)
            
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: takeCKRecord.record.recordID) { [unowned self] record, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    if let record = record {
                        var fileCount = 0
                        // there should be a better way to do this
                        do {
                            // create root for take
                            try FileManager.default.createDirectory(at: documentPath, withIntermediateDirectories: true, attributes: nil)
                            // three possible files (take, metadata and note)
                            if let takeAsset = record["take"] as? CKAsset {
                                let takeURL = takeAsset.fileURL
                                let takeDestinationURL = documentPath.appendingPathComponent(takeName!).appendingPathExtension("wav")
                                fileCount += 1
                                print("fileCount + :\(fileCount)")
                                assetToApp(assetURL: takeURL!, destinationURL: takeDestinationURL) { result in
                                    if result {
                                        print("Take \(takeName!) audio copy to app")
                                        fileCount -= 1
                                        if fileCount == 0 { deleteTakeFromICloud(recordID: record.recordID, takeURL: documentPath, completion: completion)}
                                    }
                                }
                            }
                            
                            
                            if let metadataAsset = record["metadata"] as? CKAsset {
                                let metadataURL = metadataAsset.fileURL
                                let metadataDestinationURL = documentPath.appendingPathComponent("metadata").appendingPathExtension("json")
                                fileCount += 1
                                print("fileCount + : \(fileCount)")
                                assetToApp(assetURL: metadataURL!, destinationURL: metadataDestinationURL) { result in
                                    if result {
                                        print("Take \(takeName!) metadata copy to app")
                                        fileCount -= 1
                                        if fileCount == 0 { deleteTakeFromICloud(recordID: record.recordID, takeURL: documentPath, completion: completion)}
                                        
                                    }
                                }
                            } else {
                                // create an take coredata record if no metadata file
                            }
                            
                            if let noteAsset = record["note"] as? CKAsset {
                                let noteURL = noteAsset.fileURL
                                let noteDestinationURL = documentPath.appendingPathComponent("note").appendingPathExtension("wav")
                                fileCount += 1
                                print("fileCount + : \(fileCount)")
                                assetToApp(assetURL: noteURL!, destinationURL: noteDestinationURL) { result in
                                    if result {
                                        print("Take \(takeName!) note copy to app")
                                        fileCount -= 1
                                        if fileCount == 0 { deleteTakeFromICloud(recordID: record.recordID, takeURL: documentPath, completion: completion) }
                                    }
                                }
                            }
                            
                            if let imageAsset = record["image"] as? CKAsset {
                                let imageURL = imageAsset.fileURL
                                let imageDestinationURL = documentPath.appendingPathComponent("image")
                                fileCount += 1
                                imageToApp(assetURL: imageURL!, destinationURL: imageDestinationURL) { result, format in
                                    if result {
                                        fileCount -= 1
                                        
                                        if fileCount == 0 { deleteTakeFromICloud(recordID: record.recordID, takeURL: documentPath, completion: completion)}
                                    }
                                }
                            }
                            
                        } catch {
                            print(error.localizedDescription)
                        }
            
                    }
                }
            }
            
            
        }
        
    }
    
    func assetToApp(assetURL: URL, destinationURL: URL, with completion: @escaping (Bool) -> Void ) {
        DispatchQueue.main.async {
            do {
                try FileManager.default.copyItem(at: assetURL, to: destinationURL)
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
    }
    
    
    func imageToApp(assetURL: URL, destinationURL: URL, with completion: @escaping (Bool, ImageFormat) -> Void) {
        DispatchQueue.main.async {
            do {
                try FileManager.default.copyItem(at: assetURL, to: destinationURL)
                
                let imageData = try Data(contentsOf: destinationURL) as NSData
                let imageFormat = imageData.imageFormat
                var imageTypeExtension = ""
                switch imageFormat {
                case .JPEG :
                    imageTypeExtension = "jpeg"
                case .PNG:
                    imageTypeExtension = "png"
                default:
                    imageTypeExtension = "unknown"
                }
                
                let fullURL = destinationURL.appendingPathExtension(imageTypeExtension)
                try FileManager.default.moveItem(at: destinationURL, to: fullURL)
                
                completion(true, imageFormat)
            } catch {
                print(error.localizedDescription)
                completion(false, ImageFormat.Unknown)
            }
        }
    }
    
    
    /// Clear take from TakeCKRecordModel
    /// Instanciate new Take object ( and CoreData record)
    /// Update TakeVC tableView
    ///
    func deleteTakeFromICloud(recordID: CKRecord.ID, takeURL: URL, completion: (String) -> Void) {
        print("deleteTakeFromICloud")
        TakeCKRecordModel.sharedInstance.deleteTake(with: recordID)
        
        // no we have take files in app's documents directory and take removed form iCloud
        let metadataURL = takeURL.appendingPathComponent("metadata").appendingPathExtension("json")
        if FileManager.default.fileExists(atPath: metadataURL.path) {
            let takeAudioURL = takeURL.appendingPathComponent(takeName!).appendingPathExtension("wav")
            let importTake = Take.init(takeURL: takeAudioURL, metaDataURL: metadataURL)
            
            importTake.storageState = .LOCAL
            importTake.iCloudState = .NONE
            
            if !Takes.sharedInstance.moveTakeToLocal(take: importTake) {
                print("Error: Could not move take \(String(describing: importTake.takeName)) to local")
            } else {
                
                print("Take transfer from iCloud to App complete")
                completion("complete")
            }
            
        }
    }
    
//    guard (coreDataController?.seedTake(name : takeName!,
//                                        filePath: takePath,
//                                        recordeAt: recordedAt!,
//                                        length: takeLength,
//                                        latitude: location?.coordinate.latitude,
//                                        longitude: location?.coordinate.longitude)) != nil else {
//
//                                            print("error saving take")
//                                            return
//    }
    /// Read metadata.json file and make coredata record of it
    ///
    /// - Parameter url: metadata json file url
    ///
    func metadataFileToRecord(metaDataURL: URL) {
        //Take.init(takeURL: <#T##URL#>, metaDataURL: url)
    }
    
    
    // MARK: Take to Json
    
    
    /// Write take metadata to *.json file. Use TakeMO for data
    /// First update take record in CoreData.
    /// Metadata file contains all Metadata items and location details, recording date and length?
    ///
    func writeJsonForTake(completion: (URL, Error?) -> Void ) {
        print("writeJsonForTake")
        // update CoreData record
        updateMetaDataForTake(takeNameWithExtension: takeName!)
        if let takeMO = try? coreDataController?.getTake(takeName: takeName!) {
            var jsonData = [String: Any]()
            // this will update property items
            getMetaDateForTake(takeNameWithoutExtension: takeName!)
            // transform items format to be serialized or use MetadataMO
            if let takeMetaDataItems = coreDataController?.getMetadataForTake(takeName: takeName!) {
                for item in takeMetaDataItems {
                    jsonData[item.name!] = item.value
                    print(item.value)
                }
            } else {
                // no metadata records for take
            }
            
            // now add TakeMO attributes to jsonData
            // use first one - more with same name?
            if let firstTakeMO = takeMO.first {
                jsonData["name"] = firstTakeMO.name
                jsonData["length"] = firstTakeMO.length
                jsonData["recordedAt"] = firstTakeMO.recordedAt!.toString(dateFormat: "dd-MM-YY")
                jsonData["latitude"] = firstTakeMO.latitude
                jsonData["longitude"] = firstTakeMO.longitude
            }
            
            // validate json data and try to write file
            if JSONSerialization.isValidJSONObject(jsonData) {
                do {
                    let data = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
                    let dataString = NSString(data: data, encoding: 8)
                    print(dataString?.description ?? "no data!")
                    
                    guard let takeURL = Takes().getURLForFile(takeName: takeName!, fileExtension: "wav", takeDirectory: "takes") else {
                        completion(url!, TakeError.JSONWriteError("No take url"))
                        return
                    }
                    let result = try JSONParser().writeTakeMeta(url: takeURL, data: data)
                    completion(result, nil)
                    
                } catch {
                    print (error)
                    completion(url!, error)
                }
            }
            
        }
    }
        
//        var metaData = [String: Any]()
//        let itemIds = ["location", "description", "addCategory"]
//        //let itemIds = [String]()
//        for itemArray in items {
//            for item in itemArray {
//                if itemIds.firstIndex(of: item.id) != nil {
//                    switch item.id {
//                    case "addCategory":
//                        metaData["category"] = item.value as? String
//                        if (item.children?.count)! > 0 {
//                            if let subCategoryItem = item.children?.first {
//                                metaData["subcategory"] = subCategoryItem.value as? String
//                            }
//                        }
//
//                    case "location":
//                        metaData["location"] = item.value
//
//                    default:
//                        metaData[item.name!] = item.value as? String
//                    }
//
//                    // special case item with possible children (addCategory)
////                    if item.id == "addCategory" {
////                        metaData["category"] = item.value as? String
////                        if (item.children?.count)! > 0 {
////                            if let subCategoryItem = item.children?.first {
////                                metaData["subcategory"] = subCategoryItem.value as? String
////                            }
////                        }
////                    } else {
////                        metaData[item.name!] = item.value as? String
////                    }
//
//                }
//            }
//        }
        
//        if JSONSerialization.isValidJSONObject(metaData) {
//            do {
//                let data = try JSONSerialization.data(withJSONObject: metaData, options: .prettyPrinted)
//                let dataString = NSString(data: data, encoding: 8)
//                print(dataString?.description ?? "no data!")
//
//                guard let takeURL = Takes().getURLForFile(takeName: takeName!, fileExtension: "wav", takeDirectory: "takes") else {
//                    completion(url!, TakeError.JSONWriteError("No take url"))
//                    return
//                }
////                if !FileManager.default.fileExists(atPath: url!.path)  {
////                    completion(url!, TakeError.JSONWriteError("No take at \(url!)"))
////                    return
////                }
//
////                let takeURL = url
////                var jsonURL = takeURL.deletingPathExtension().appendingPathExtension("json")
//
//                let result = try JSONParser().writeTakeMeta(url: takeURL, data: data)
//                completion(result, nil)
//
//
////                if JSONParser().write(url: jsonURL, data: data) == false {
////                    print("Error writing json")
////                    completion(jsonURL, TakeError.JSONWriteError("Error writing json"))
////                } else {
////                    completion(url!, nil)
////                }
//            } catch {
//                print (error)
//                completion(url!, error)
//            }
//        }
//
//        //completion(url!, TakeError.JSONSerilizationError("JSONSerilization error!"))
//    }
    
}

enum TakeError: Error {
    case TakeNameError(String)
    case JSONWriteError(String)
    case JSONSerilizationError(String)
    case NoTakeCKRecord
    case NameNotUnique(String)
}

extension TakeError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .TakeNameError:
            return NSLocalizedString("Take name error", comment: "")
        case .JSONSerilizationError:
            return NSLocalizedString("Json seriliztion error", comment: "")
            
        case .JSONWriteError:
            return NSLocalizedString("Json writer error", comment: "")
        case .NoTakeCKRecord:
            return NSLocalizedString("No TakeCKRecord for take", comment: "")
        case .NameNotUnique:
            return NSLocalizedString("Take name not unique", comment: "")
        }
        
    }
}


struct AudioFormatDescription {
    var type: String?
    var sampleRate: Float64?
    var bitPerChannel: UInt32?
    var channelsPerFrame: UInt32?
    var bytesPerFrame: UInt32?
    
    func asString() -> String {
        let s = "Type: \(type!) \nSampelRate: \(sampleRate!) \nBitPerChannel: \(bitPerChannel!) \nChannelsPerFrame: \(channelsPerFrame!) \nBytesPerFrame: \(bytesPerFrame!)"
        
        //print(s)
        
        return s
    }
}


enum TakeStorageState {
    case LOCAL
    case ICLOUD
    case IDRIVE
    case DROPBOX
    case NONE
}
