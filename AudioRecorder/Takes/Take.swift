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
 Each property is an MetaDataItem and belongs to a Seciton
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
    
    var location: CLLocation?
    var newTake = true
    var takeSaved = false
    
    var takeFormat: AudioFormatDescription?
    
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
    
    init() {}
    
    
    init(takeURL: URL, date: Date, userLocation: CLLocation?) {
        // set takeName and takeType and get items
        var recordingDataItems = self.setURL(takeURL: takeURL)
        // recorded at
        recordingDataItems.append(self.setRecordedAt(date: date))
        // location
        if userLocation != nil {
            recordingDataItems.append(self.setLocation(location: userLocation!))
        }
        
        itemSections.append(MetaDataSections.RECORDINGDATA)
        items.append(recordingDataItems)
    }
    
    /**
     First add recording data (name, location, recording date, filePath)
     Then read metadata from db
     Next add default metadata items, which have no entry in db
     
     */
    init(withTakeMO takeMO: TakeMO) {
        takeName = takeMO.name!
        
        self.addRecordingData(takeMO: takeMO)
        
        // MetaData
        
        // Saved MetaData in CoreData?
        getMetaDateForTake(takeNameWithoutExtension: takeName!)
        
        // Default Metadata
        self.addDefaultMetaData()
        
        // take format info
        self.takeFormat = self.getTakeFormat()
        if self.takeFormat != nil {
            let formatString = formatTakeFormat()
            addAudioFormatData(formatString: formatString)
        }
//        let group = DispatchGroup()
        
//        group.enter()
//        DispatchQueue.global(qos: .default).async {
//            self.takeFormat = self.getTakeFormat()
//            group.leave()
//        }
//        group.wait()
//
        print(self.takeFormat?.sampleRate ?? "no sampleRate value")
    }
    
    /**
     Add data generated at recording of take
     */
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
    
    /**
     Default MetaData are
     Category
     Description
     
     */
    private func addDefaultMetaData() {
       
        if getItemForID(id: "addCategory", section: .METADATASECTION) == nil {
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
        
//        var format = ""
//        format.append("SampleRate: \(takeFormat?.sampleRate!)")
//        format.append("\n")
//        format.append("Bit per Channel: \(takeFormat?.bitPerChannel!)")
//
//        return format
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
        
        
        let activeItemDescription = ["id": "addCategory",
                                     "type": MetaDataTypes.STRING.rawValue,
                                     "name": "Category",
                                     "description": "Add Category"]
        let activeItem = MetaDataItem(description: activeItemDescription, value: category)
        
        let subCategoryItem = getSubCategory(subCategory: subCategory)
        activeItem.addChild(child: subCategoryItem)
        //items.append(activeItem)
        
        return activeItem
    }
    
    /**
     A sub category is a child of a category
    */
    func getSubCategory(subCategory: String = "") -> MetaDataItem {
        let activeItemDesc = ["id": "addSubCategory", "type": MetaDataTypes.STRING.rawValue, "name": "Add Subcategory", "description": "Add a Subcategory"]
        let activeItem = MetaDataItem(description: activeItemDesc, value: subCategory)
        return activeItem
    }
    
    func addDescription(description: String = "") -> MetaDataItem {
        let descriptionDesc = MetaDataDefault().description
        let descriptionItem  = MetaDataItem(description: descriptionDesc, value: description)
        
        return descriptionItem
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
     Is name in takeName item different to poperty takeName then try to rename
     
     - Parameters:
     - takeURL:
     - newName: new name of take without extension
     */
    private func renameTake(takeURL: URL) -> (result: Bool, name: String?) {
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
                // update to new name and path
                return (true, takeNameInItem)
            }
        }
        
        return (false, nil)
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
            case "addCategory":
                let category = mdItem.value
                
                guard let subCategory = takeMetaDataItems?.first(where: { $0.name == "addSubCategory"}) else {
                    mdItems.append(addCategory(category: category!))
                    break
                }
                let categoryItem = addCategory(category: category!, subCategory: subCategory.value!)
                
                mdItems.append(categoryItem)
                
            case "description":
                let description = mdItem.value
                let descriptionItem = addDescription(description: description!)
                
                mdItems.append(descriptionItem)
                
            default:
                print("Unkown item name \(String(describing: mdItem.name))")
            }
        }
        
        itemSections.append(MetaDataSections.METADATASECTION)
        items.append(mdItems)
    }
    
    func getTakeFormat() -> AudioFormatDescription? {
        let takeNameWithExtension = takeName! + "." + takeType!
        let takeURL = Takes().getUrlforFile(fileName: takeNameWithExtension)
        
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
        let tnWithExtension = tn + "." + takeType!
        
        if takeNameWithoutExtension != tn {
            takeName = takeNameWithoutExtension
            if updateItem(id: "takeName", value: tn, section: .RECORDINGDATA) == false {
                NSLog("Error updateing item takename to \(tn)")
            }
            
            if let newNameURL = Takes().getUrlforFile(fileName: tnWithExtension)  {
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
