//
//  MetaDataDescription.swift
//  AudioRecorder
//
//  Created by Wolf on 03.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation

import Foundation

struct MetaDataDefault {
    var takeName = ["id": "takeName", "type": MetaDataTypes.STRING.rawValue, "name": "Name of take", "description": "Name of take"]
    var path = ["id": "path", "type": MetaDataTypes.STRING.rawValue, "name": "Path", "description": "Path of sound file"]
    var creationDate = ["id": "creationDate", "type": MetaDataTypes.STRING.rawValue, "name": "Recorded At", "description": "Date of recording"]
    var location = ["id": "location", "type": MetaDataTypes.ANY.rawValue, "name": "Location", "description": "Location of recording"]
    var takeFormat = ["id": "takeFormat", "type": MetaDataTypes.STRING.rawValue, "name": "Format", "description": "Take Audioformat"]
    //var keyboard = ["id": "keyboard", "type": MetaDataTypes.STRING.rawValue, "name": "Keyboard", "description": "Keyboard test"]
}

struct MetaDataOptional {
    var description = MetaDataDescription(id: "description",  type: MetaDataTypes.STRING, name: "Description", description: "Enter description (max 255 char's")
    var category = MetaDataDescription(id: "category", type: MetaDataTypes.STRING, name: "Category", description: "Choose a category")
    var image = MetaDataDescription(id: "image", type: MetaDataTypes.ANY, name: "Image", description: "Add Image to take")
    var audio = MetaDataDescription(id: "audio", type: MetaDataTypes.ANY, name: "Audio", description: "Record audio for take")
//    var image = ["id": "image", "type": MetaDataTypes.ANY.rawValue, "name": "Image", "description": "Add Image for recording"]
//    var audio = ["id": "audio", "type": MetaDataTypes.ANY.rawValue, "name": "Audio", "description": "Record an audio for recording"]
    
    //var metadataNames = ["Description"]
    func getAllNames() -> [String] {
        return [description.name, category.name, image.name, audio.name]
    }
    
    func getDescription(name: String) -> MetaDataDescription? {
        switch name {
        case "Description":
            return description
        case "Category" :
            return category
        case "Image":
            return image
        case "audio":
            return audio
        default:
            return nil
        }
    }
    
}

struct MetaDataOptionalSub {
    var subCategory = MetaDataDescription(id: "subCategory", type: MetaDataTypes.STRING, name: "Subcategory", description: "Add subcategory")
}


struct MetaDataStrings {
    let addMetadataInstruction = "Select the metadata types you want to add to take."
}
/**
 All posible CategoryItem types
 */
enum MetaDataTypes: String {
    case STRING = "string"
    case INTEGER = "integer"
    case DOUBLE = "double"
    case ANY = "any"
}

//struct MetaDataSections {
//    var takeRecordingData = ["id": "Take Recording Data"]
//}

enum MetaDataSections: String {
    case RECORDINGDATA = "Recording Data"
    case METADATASECTION = "Metadata"
    case TAKEFORMAT = "Format"
}


struct MetaDataDescription {
    var id: String
    var name: String
    var type: MetaDataTypes
    var description: String
    
    init(id: String, type: MetaDataTypes, name: String, description: String) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
    }
}
