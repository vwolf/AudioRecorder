//
//  MetaDataItem.swift
//  AudioRecorder
//
//  Created by Wolf on 03.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation

class MetaDataItem {
    
    /// Type of item value
    let type: String
    
    /// Id of item
    let id: String
    
    // Name of item
    var name: String?
    
    // Item description
    var description: String?
    var value: Any?
    
    var stringValue: String?
    
    var children: [MetaDataItem]?
    
    
    init(type: MetaDataTypes, id: String) {
        self.type = type.rawValue
        self.id = id
    }

    init(description: [String: String], value: String) {
        self.id = description["id"]!
        self.name = description["name"]!
        self.type = description["type"]!
        self.description = description["description"]!
        
        self.value = value
    }
    
     func addChild(child: MetaDataItem) {
           if children != nil {
               children?.append(child)
           } else {
               children = [child]
           }
       }
}
