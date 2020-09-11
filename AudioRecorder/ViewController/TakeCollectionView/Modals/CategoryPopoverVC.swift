//
//  CategoryPopoverVC.swift
//  AudioRecorder
//
//  Created by Wolf on 07.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class CategoryPopoverVC: UIViewController {
    
    @IBOutlet weak var categoryTextField: UITextField!
    
    let tableData = ["Car", "Bike", "Bus", "Van", "Bicycle"]

    let categoryDict = [String: [String]]()
    var sortedCategories = [String]()
    var categoryType = "category"
    
    var delegate: CategoryPopoverDelegate?
    var cellIdx: Int = 1
    
    override func viewDidLoad() {
           super.viewDidLoad()
           
           //sortedCategories = Array(categoryDict.keys).sorted(by: {$0 < $1} )
       }
       
       
       override func didReceiveMemoryWarning() {
           super.didReceiveMemoryWarning()
       }
    
    @IBAction func okBtnAction(_ sender: UIButton) {
        if self.delegate != nil {
            delegate?.saveCategory(userText: categoryTextField.text!, cellIdx: cellIdx, categoryType: categoryType)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func updateCategory(category: String) {
        categoryTextField.text = category
    }
}

extension CategoryPopoverVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sortedCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryTableViewCell", for: indexPath) as? CategoryTableViewCell else {
//            fatalError("The dequeued cell in not and instance of CategoryTableViewCell")
//        }
                //cell.category.text = tableData[indexPath.row]
        //        cell.category.text = tableData[indexPath.row]
        
        let cell = UITableViewCell(style: .default , reuseIdentifier: "ids")
        cell.textLabel?.text = sortedCategories[indexPath.row]
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(sortedCategories[indexPath.row])
        
        updateCategory(category: sortedCategories[indexPath.row])
    }
    
//    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
//        print(sortedCategories[indexPath.row])
//    }
//    
//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        return indexPath
//    }
}


protocol CategoryPopoverDelegate {
    func saveCategory(userText: String, cellIdx: Int, categoryType: String)
}


class CategoryTableViewCell: UITableViewCell {
    
   
    @IBOutlet weak var category: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
