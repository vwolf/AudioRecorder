//
//  MetadataAddPopoverVC.swift
//  AudioRecorder
//
//  Created by Wolf on 18.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class MetadataAddPopoverVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var doneBtn: UIButton!
    //    let tableData = ["Image", "Audio"]
    var take: Take? = nil
    var allMetaDataNames = MetaDataOptional().getAllNames()
    var existingMetaData = [String]()
    
    var delegate: MetadataAddPopoverDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        instructionLabel.text = MetaDataStrings().addMetadataInstruction
        tableView.register(UINib.init(nibName: "MetadataAddCell", bundle: nil), forCellReuseIdentifier: "MetadataAddCellIdentifier")
        
        if take != nil {
            
            let sectionIdx = take?.getItemSectionIndex(section: MetaDataSections.METADATASECTION )
            if sectionIdx != nil {
                let takeItems = take!.items[sectionIdx!]
                //var metaDataIn = [String]()
                //takeItems.map( { metaDataIn.append($0.name!)} )
                existingMetaData = takeItems.map { $0.name! }
                tableView.reloadData()
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
    }
    
    @objc func addAction(sender: UIButton) {
        print("addAction button tag: \(sender.tag)")
        print("add \(allMetaDataNames[sender.tag])")
        if (take?.addItem(name: allMetaDataNames[sender.tag], section: .METADATASECTION)) == true {
            sender.isHidden = true
            take?.takeModified = true
        }
    }

    @IBAction func doneBtnAction(_ sender: UIButton) {
//        if let pvc = self.presentationController {
//            pvc.delegate?.presentationControllerWillDismiss?(pvc)
//        }
        self.dismiss(animated: true, completion: nil)
        delegate?.dismissMetadataAddPopover()
    }
}

extension MetadataAddPopoverVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allMetaDataNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MetadataAddCellIdentifier", for: indexPath) as! MetadataAddCellController
        cell.nameLabel.text = allMetaDataNames[indexPath.row]
//        cell.textLabel?.text = tableData[indexPath.row]
        
        if (existingMetaData.firstIndex(of: allMetaDataNames[indexPath.row]) != nil) {
            cell.addBtn.isHidden = true
        } else {
            cell.addBtn.tag = indexPath.row
            cell.addBtn.addTarget(self, action: #selector(addAction(sender:)), for: .touchUpInside)
        }
        
        return cell
    }
    
}


protocol MetadataAddPopoverDelegate {
    func dismissMetadataAddPopover()
}
