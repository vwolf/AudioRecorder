//
//  Extensions.swift
//  AudioRecorder
//
//  Created by Wolf on 01.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import ImageIO
import UIKit

extension Date {
    func toString( dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: self)
    }
    
    func fromString( dateFormat format: String, dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }
        return date
    }
    
    
    func encodeToJson() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
            
        do {
            let encodedDate = try encoder.encode(self)
            let jsonString = String(data: encodedDate, encoding: .utf8)
            print("dateEnc: \(jsonString!)")
            return jsonString!
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
//    func decodeFromJson(date: String) -> Date? {
//        struct createdAt: Decodable {
//            let createdAt: Date
//        }
//        let json = """
//        {"createdAt" : \(date)}
//        """
//        let data = Data(json.utf8)
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .iso8601
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//
//        let dec = try! decoder.decode(createdAt.self, from: data)
//        let createdAtValue = dec.createdAt
//    }
}


extension FourCharCode {
    // Create a String representation of a FourCC
    func toString() -> String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xff),
            CChar((self >> 16) & 0xff),
            CChar((self >> 8) & 0xff),
            CChar(self & 0xff),
            0
        ]
        let result = String(cString: bytes)
        let characterSet = CharacterSet.whitespaces
        return result.trimmingCharacters(in: characterSet)
    }
}

enum ImageFormat {
    case Unknown, PNG, JPEG, GIF, TIFF
}

extension NSData {
    var imageFormat: ImageFormat{
        var buffer = [UInt8](repeating: 0, count: 1)
        self.getBytes(&buffer, range: NSRange(location: 0, length: 1))
        switch buffer {
        case [0x89]:
            return .PNG
        case [0xFF]:
            return .JPEG
        case [0x47]:
            return .GIF
        case [0x49], [0x40]:
            return .TIFF
        default:
            return .Unknown
        }
        
    }
}
