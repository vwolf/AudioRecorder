//
//  JSONParser.swift
//  AudioRecorder
//
//  Created by Wolf on 03.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation

class JSONParser {
    
    /**
     Parse file at URL.
     
     - parameter: resourcePath
     - return: data or nil
    */
    func parseJSONFile(_ resourcePath: URL) -> Any? {
        var json: Any
        
        do {
            let data = try Data(contentsOf: resourcePath)
            
            json = try JSONSerialization.jsonObject(with: data, options: [])
            return json
            
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    /**
        Write file to url
     
        - parameter url: file path
        - parameter data: data to write (json string)
     
        - return Bool
     */
    func write(url: URL, data: Data) -> Bool? {
        
        let nameWithOutExtension = url.deletingPathExtension()
        let jsonFile = nameWithOutExtension.appendingPathExtension("json")
        
        if FileManager.default.createFile(atPath: jsonFile.path, contents: data, attributes: nil) {
            return true
        } else {
            print("Error writing file: \(jsonFile)")
            return false
        }
    }
     
   
}
