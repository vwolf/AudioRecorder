//
//  TakesVC.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

/// List of recorded takes
///
class TakesVC: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var takesTableView: UITableView!
    
    var takes = [String]()
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
    
    override func viewDidLoad() {
        print("TakesVC.viewDidLoad")
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("TakesVC viewWillAppear")
        
        if Takes.sharedInstance.reloadFlag {
            takesTableView.reloadData()
        }
    }
    
    
    func reloadTakes() {
        //takes = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
        takes = Takes().getAllTakeNames()
        
        takesTableView.reloadData()
    }
    
    
    /// Load all metadata for take, then trigger segue to 'TakeVC'
    ///
    /// - parameter row:  row index
    /// - parameter cell: selected table cell
    ///
    func loadTake(row: Int, cell: UITableViewCell?) {
        let takeName = Takes().stripFileExtension( takes[row] )
        guard let take = Takes().loadTake(takeName: takeName) else {
            return
        }
        self.performSegue(withIdentifier: "TakeSegueIdentifier", sender: take)
    }
    
    
    /// Delete action from table cell
    /// First let user confirm delete action (alert)
    ///
    /// - parameter row: row index
    /// - parameter cell: selected table cell
    ///
    func deleteTake(row: Int, cell: UITableViewCell? ) {
        //let takeName = takes[row]
        guard let takeName = Takes.sharedInstance.takesLocal[row].takeName else {
            print("Error: deleting take, no take in takeLocal at index \(row) ")
            return
        }
        
        let alertController = alertDeleteFile(name: takeName, completion: { deleteAction in
            if deleteAction {
                // delete action
                let deleteAction = Takes().deleteTake(takeName: takeName)
                if deleteAction == true {
                    let takeNameWithOutExtension = Takes().stripFileExtension(takeName)
                    if (self.coreDataController?.deleteTake(takeName: takeNameWithOutExtension))! {
                        //self.takes.remove(at: row)
                        Takes.sharedInstance.takesLocal.remove(at: row)
                        self.takesTableView.reloadData()
                    } else {
                        // when file but no coredata entry
                        //self.takes.remove(at: row)
                        Takes.sharedInstance.takesLocal.remove(at: row)
                        self.takesTableView.reloadData()
                    }
                }
            } else {
                // cancel action
            }
        })
        
        self.present(alertController, animated: true)
    }
    
    /**
     Alert to get confirmation to delete a take
     
     - parameter name: name of take
     - parameter completion: closure to get alert result
     
     - Returns: Alert
     */
    func alertDeleteFile(name: String, completion: @escaping (Bool) -> ()) -> UIAlertController {
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            completion(true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }
        
        let alertController = UIAlertController(title: "Delete", message: "Deleter Recording \(name)!", preferredStyle: .alert)
        alertController.addAction(ok)
        alertController.addAction(cancel)
        
        return alertController
    }
    
    
    /// Play take through ModalAudioPlayerVC
    ///
    /// - Parameters:
    ///   - row:
    ///   - cell:
    func playTake(row: Int, cell: UITableViewCell? ) {
        print("playTake Popover")
        //let sourceRect = cell.frame
        
        let popoverContentController = self.storyboard?.instantiateViewController(withIdentifier: "ModalAudioPlayerView") as? ModalAudioPlayerVC
        
        popoverContentController?.modalPresentationStyle = .popover
       // popoverContentController?.modalTransitionStyle = .crossDissolve
        popoverContentController?.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 320)
        popoverContentController?.view.backgroundColor = Colors.AVModal.background.toUIColor()
        
        if let popoverPresentationController = popoverContentController?.popoverPresentationController {
            popoverPresentationController.delegate = self
            // no arrow on popover
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            // with arrow
//            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.backgroundColor = Colors.Base.background.toUIColor()
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: 10, y: self.view.bounds.height / 2 + 120, width: self.view.frame.size.width, height: 240)
            
            
            if let popoverController = popoverContentController {
                present(popoverController, animated: true, completion: nil)
                
                popoverContentController?.takeName = takes[row]
            }
        }
    }
    
    // MARK: ModalPopup Delegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    /**
     Segue to full take page
     
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TakeSegueIdentifier" {
            guard let object = sender as? TakeMO else { return }
            
            if let destinationVC = segue.destination as? TakeVC {
                destinationVC.takeMO = object
            }
        }
        
        if segue.identifier == "CloudSegueIdentifier" {
            guard let object = sender as? Take else { return }
            
            if let destinationVC = segue.destination as? CloudVC {
                destinationVC.take = object
            }
        }
    }
    
    @objc func playTakeForCell(_ sender: UIButton) {
        print("playTakeForCell!")
        playTake(row: sender.tag, cell: nil)
    }
    
    /// Cloud button action
    /// Present choice 
    ///
    @objc func takeCloudAction(_ sender: UIButton) {
        //let takeName = takes[sender.tag]
        if let cell = takesTableView.cellForRow(at: IndexPath(row: sender.tag, section: 0)) as? TakesTableDetailViewCell {
            self.performSegue(withIdentifier: "CloudSegueIdentifier", sender: cell.take)
        }
        
//        guard let take = Takes().loadTake(takeName: takeName) else {
//            return
//        }
//        self.performSegue(withIdentifier: "CloudSegueIdentifier", sender: take)
    }
    
    @objc func loadMetadataForCell(_ sender: UIButton) {
        loadTake(row: sender.tag, cell: nil)
    }
    
    @objc func deleteTake(_ sender: UIButton) {
        deleteTake(row: sender.tag, cell: nil)
    }
}

extension TakesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return takes.count
        return Takes.sharedInstance.takesLocal.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TakesDetailsTableViewCellIdentifier", for: indexPath) as? TakesTableDetailViewCell else {fatalError("The dequeued cell is not an instance of TakesTableDetailViewCell")
        }
        
        let take = Takes.sharedInstance.takesLocal[indexPath.row]
        cell.take = take
        
        if cell.take.takeLength > 0 {
            cell.playBtn.tag = indexPath.row
            cell.playBtn.addTarget(self, action: #selector(playTakeForCell(_:)), for: .touchUpInside)
            
            cell.cloudBtn.tag = indexPath.row
            cell.cloudBtn.addTarget(self, action: #selector(takeCloudAction(_:)), for: .touchUpInside)
            
            if take.iCloudState == .ICLOUD {
                //cell.cloudBtn.layer.backgroundColor = UIColor.green.cgColor
                cell.cloudBtn.tintColor = UIColor.systemGreen
            }
            
            cell.metadataBtn.tag = indexPath.row
            cell.metadataBtn.addTarget(self, action: #selector(loadMetadataForCell(_:)), for: .touchUpInside)
        }
       
        cell.trashBtn.tag = indexPath.row
        cell.trashBtn.addTarget(self, action: #selector(deleteTake(_:)), for: .touchUpInside)
        
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("TakesVC.didDelectRowAt: \(indexPath.row), name: \(takes[indexPath.row])")
//
//        let cell = tableView.cellForRow(at: indexPath)
//        //self.loadTake(row: indexPath.row, cell: cell!)
//        self.playTake(row: indexPath.row, cell: cell!)
//
//    }
    
//    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
//        print("accesoryButtonTappedForRow")
//    }
    
//    @available(iOS 11.0, *)
//    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//
//        let action = UIContextualAction(style: .destructive, title: "Delete", handler: { (action, view, completionHandler) in
//            self.deleteTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath)!)
//            completionHandler(true)
//        })
//
//        let configuration = UISwipeActionsConfiguration(actions: [action])
//        return configuration
//    }
//
//    @available(iOS 11.0, *)
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let action = UIContextualAction(style: .normal, title: "More", handler: { (action, view, completionHandler) in
//            self.loadTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath))
//            completionHandler(true)
//        })
//
//        let configuration = UISwipeActionsConfiguration(actions: [action])
//        return configuration
//    }
    
    
//    @available(iOS 10.0, *)
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        var actions = [UITableViewRowAction]()
//
//        let actionDelete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
//            self.deleteTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath)!)
//        }
//        let actionMore = UITableViewRowAction(style: .normal, title: "More") { (action, indexPath) in
//            self.loadTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath))
//        }
//
//        actions.append(actionDelete)
//        actions.append(actionMore)
//
//        return actions
//    }
}
