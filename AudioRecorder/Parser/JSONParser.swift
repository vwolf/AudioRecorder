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
            let data = try Data(contentsOf: resourcePath, options: .mappedIfSafe)
            
            json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
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
        
//        let nameWithOutExtension = url.deletingPathExtension()
//        let jsonFile = nameWithOutExtension.appendingPathExtension("json")
        
        if FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil) {
            return true
        } else {
            print("Error writing file: \(url)")
            return false
        }
    }
     
   
    /// Write *,json file at url.
    ///
    /// - Parameter url: take audio recording file url.
    /// - Parameter data: Data to write to json file
    ///
    func writeTakeMeta(url: URL, data: Data) throws -> URL {
    
        let takeMetaURL = url.deletingPathExtension().appendingPathExtension("json")
        
        guard FileManager.default.createFile(atPath: takeMetaURL.path, contents: data, attributes: nil) else {
            throw JSONParserError.createFileError(takeMetaURL)
        }
        
        return takeMetaURL
    }
    
    enum JSONParserError: Error {
        case createFileError(URL)
        
        //func map<P>(f: T -> P) ->
    }
}
