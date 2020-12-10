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

/**
 Take properties
 Each property is an MetaDataItem and belongs to a Section
 */
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
            
            let audioPlayer = try AVAudioPlayer(contentsOf: takeURL)
            takeLength = audioPlayer.duration
            
            // location only if metadata file url
            if metaDataURL != nil {
                if let parserResult = JSONParser().parseJSONFile(metaDataURL!) as? [String: Any] {
                    for item in parserResult {
                        print(item.key)
                    }
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
    
    /// Take from TakeCKRecord. These are always .ICOUD takes
    ///
    init(takeCKRecord: TakeCKRecord, takeName: String) {
        // takename in takeRecord is with file extension
        self.takeName = takeName
        // let url = takeCKRecord.audioAsset.fileURL
        
        iCloudState = .ICLOUD
        
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
        print("Take.location: \(location)")
        let locationDesc = MetaDataDefault().location
        let locationValue = "Lat: \(location.coordinate.latitude) Lon: \(location.coordinate.longitude)"
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
                writeJsonForTake()
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
    
    /**
     Return path url
     
     - returns path to take in documents directory
     */
    func getTakePath() {
        
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
    
    func sortMetadataForDisplay() -> Bool?{
        let itemOrder = MetaDataOptional().itemOrder
        
        guard let sectionIdx = getItemSectionIndex(section: .METADATASECTION) else {
            return nil
        }
        items[sectionIdx].sort(by: {itemOrder.firstIndex(of: $0.id)! < itemOrder.firstIndex(of: $1.id)! } )
            
        return true
    }
    
    // MARK: Take to Json
    
    /**
     Write take metadata to *.json file
     
     */
    func writeJsonForTake() {
        print("writeJsonForTake")
        var metaData = [String: String]()
        let itemIds = ["location", "description", "addCategory"]
        //let itemIds = [String]()
        for itemArray in items {
            for item in itemArray {
                if itemIds.firstIndex(of: item.id) != nil {
                    // special case item with possible children (addCategory)
                    if item.id == "addCategory" {
                        metaData["category"] = item.value as? String
                        if (item.children?.count)! > 0 {
                            if let subCategoryItem = item.children?.first {
                                metaData["subcategory"] = subCategoryItem.value as? String
                            }
                        }
                    } else {
                        metaData[item.name!] = item.value as? String
                    }
                    
                }
            }
        }
        
        if JSONSerialization.isValidJSONObject(metaData) {
            do {
                let data = try JSONSerialization.data(withJSONObject: metaData, options: .prettyPrinted)
                let dataString = NSString(data: data, encoding: 8)
                print(dataString?.description ?? "no data!")
                
                let takeURL = Takes().getUrlforFile(fileName: takeName! + ".wav")
                
                if JSONParser().write(url: takeURL!, data: data) == false {
                    print("Error writing json")
                }
            } catch {
                print (error)
            }
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
        
        print(s)
        
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
