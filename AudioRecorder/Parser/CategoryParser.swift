//
//  CategoryParser.swift
//  AudioRecorder
//
//  Created by Wolf on 07.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation

class CategoryParser {
    
    /**
     Parse data into categories
     Categories have Subcategories (optional)
     Categories are saved in [categorie: [subcategories]]
     
    */
    func parseCategories() -> [String: [String]] {
        
        var categoriesDict =  [String: [String]]()
        
        guard let categoryFileUrl = Bundle.main.url(forResource: "category", withExtension: "json", subdirectory: "data") else {
            print("No category.json file!")
            return categoriesDict
        }
        
        let parser = JSONParser()
        if let categoryData = parser.parseJSONFile(categoryFileUrl) as? [String: Any] {
            // check contents type
            guard let contentType = categoryData["Contents"] as? String else {
                print("No content type in category.json file!")
                return categoriesDict
            }
            // all categories
            if let categories = categoryData[contentType] as? [String] {
                // any subcategories?
                for category in categories {
                    if let subCategorys = categoryData[category] as? [String] {
                        categoriesDict[category] = subCategorys
                    } else {
                        categoriesDict[category] = [String]()
                    }
                }
            }
        } else {
            print("No data from parser")
        }
        return categoriesDict
    }
}
