//
//  ShareVC.swift
//  AudioRecorder
//
//  Created by Wolf on 14.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

class ShareVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var toolbarCancelBtn: UIBarButtonItem!
    @IBOutlet weak var toolbarSaveBtn: UIBarButtonItem!
    @IBOutlet weak var toolbarBottom: UIToolbar!
    
    
    var takeCKRecordModel = TakeCKRecordModel()
    var cloudDataManager = CloudDataManager.sharedInstance
    
    var takeNames = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    var takeNamesNew = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbarSaveBtn.isEnabled = false
        toolbarCancelBtn.isEnabled = false
        
        //toolbarBottom.viewWithTag(2)?.isHidden = true
        if let cancelItem = toolbarBottom.items?.first(where: { $0.tag == 2 }) {
            cancelItem.isEnabled = false
        }
        
        tableView.allowsMultipleSelection = true
        
        takeNames = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
        if takeNames.count > 0 {
            takeNamesNew = takeCKRecordModel.getNewRecords(with: "name", in: takeNames)
        }
        
        takeCKRecordModel.refresh()
    }
    
    @IBAction func toolbarSaveBtnAction(_ sender: UIBarButtonItem) {
        let selected = tableView.indexPathsForSelectedRows
        if selected != nil {
            let selectedRows = selected?.map { $0.row }
            for row in 0..<selectedRows!.count {
                if let url = Takes().getUrlforFile(fileName: takeNames[row]) {
                    takeCKRecordModel.addTake(url: url)
                }
            }
        }
    }
    
    @IBAction func toolbarCancelBtnAction(_ sender: UIBarButtonItem) {
    }
    
}


extension ShareVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return takeNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShareTableViewCellIdentifier", for: indexPath) as? ShareTableViewCell else {
            fatalError("The dequeued cell is not an instance of ShareTableViewCell")
        }
        
        cell.takeNameLabel.text = takeNames[indexPath.row]
        cell.accessoryType = .none
        
        if takeNamesNew.contains( takeNames[indexPath.row]) {
            cell.takeStatusLabel.text = "not in Cloud"
        } else {
            cell.takeStatusLabel.text = "in Cloud"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if takeNamesNew.contains( takeNames[indexPath.row]) {
            return indexPath
        }
        return indexPath
//        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("indexPathForSelectedRows: \(tableView.indexPathsForSelectedRows?.count ?? -1)")
        if let cell = tableView.cellForRow(at: indexPath) {
            if takeNamesNew.contains( takeNames[indexPath.row]) {
                if cell.accessoryType == .none {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                if cell.accessoryType == .none {
                    cell.accessoryType = .detailButton
                } else {
                    cell.accessoryType = .none
                }
            }
            
            if (tableView.indexPathsForSelectedRows != nil) {
                toolbarSaveBtn.isEnabled = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
         if (tableView.indexPathsForSelectedRows == nil) {
            toolbarSaveBtn.isEnabled = false
        }
    }
   
}


class ShareTableViewCell: UITableViewCell {
    
    @IBOutlet weak var takeNameLabel: UILabel!
    @IBOutlet weak var takeStatusLabel: UILabel!
}
