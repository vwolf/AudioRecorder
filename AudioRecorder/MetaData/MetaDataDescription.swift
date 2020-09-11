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
    var description = ["id": "description", "type": MetaDataTypes.STRING.rawValue, "name": "Description", "description": "Description 255 characters"]
    var image = ["id": "image", "type": MetaDataTypes.ANY.rawValue, "name": "Image", "description": "Add Image for recording"]
    var audio = ["id": "audio", "type": MetaDataTypes.ANY.rawValue, "name": "Audio", "description": "Record an audio for recording"]
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
    case RECORDINGDATA = "Take Recording Data"
    case METADATASECTION = "METADATA"
    case TAKEFORMAT = "Take Format"
}
