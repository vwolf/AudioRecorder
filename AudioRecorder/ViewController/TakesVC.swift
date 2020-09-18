//
//  TakesVC.swift
//  AudioRecorder
//
//  Created by Wolf on 04.08.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import UIKit

class TakesVC: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var takesTableView: UITableView!
    
    var takes = [String]()
    var coreDataController = (UIApplication.shared.delegate as! AppDelegate).coreDataController
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func reloadTakes() {
        takes = Takes().getAllTakeNames(fileExtension: "wav", directory: nil, returnWithExtension: true)
        takesTableView.reloadData()
    }
    
    /**
     Load all metadata for take, then trigger segue to TakeVC
     
     - parameter row:  row index
     - parameter cell: selected table cell
     */
    func loadTake(row: Int, cell: UITableViewCell?) {
        let takeName = Takes().stripFileExtension( takes[row] )
        guard let take = Takes().loadTake(takeName: takeName) else {
            return
        }
        self.performSegue(withIdentifier: "TakeSegueIdentifier", sender: take)
    }
    
    /**
     Delete action from table cell
     First let user confirm delete action (alert)
     
     - parameter row: row index
     - parameter cell: selected table cell
     */
    func deleteTake(row: Int, cell: UITableViewCell ) {
        let takeName = takes[row]
        
        
        let alertController = alertDeleteFile(name: takeName, completion: { deleteAction in
            if deleteAction {
                // delete action
                let deleteAction = Takes().deleteTake(takeName: takeName)
                if deleteAction == true {
                    let takeNameWithOutExtension = Takes().stripFileExtension(takeName)
                    if (self.coreDataController?.deleteTake(takeName: takeNameWithOutExtension))! {
                        self.takes.remove(at: row)
                        self.takesTableView.reloadData()
                    }
                }
            } else {
                // cancel action
            }
        })
        
        self.present(alertController, animated: true)
    }
    
    
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
    }
}

extension TakesVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return takes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TakesTableViewCellIdentifier", for: indexPath) as? TakesTableViewCell else {fatalError("The dequeued cell is not an instance of TakesTableViewCell")
        }
        
        cell.takeNameLabel.text = takes[indexPath.row]
        //cell.accessoryType = .detailButton
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("TakesVC.didDelectRowAt: \(indexPath.row), name: \(takes[indexPath.row])")
        
        let cell = tableView.cellForRow(at: indexPath)
        //self.loadTake(row: indexPath.row, cell: cell!)
        self.playTake(row: indexPath.row, cell: cell!)
           
    }
    
//    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
//        print("accesoryButtonTappedForRow")
//    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let action = UIContextualAction(style: .normal, title: "Delete", handler: { (action, view, completionHandler) in
            self.deleteTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath)!)
            completionHandler(true)
        })
        
//        action.title = "A"
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "More", handler: { (action, view, completionHandler) in
            self.loadTake(row: indexPath.row, cell: tableView.cellForRow(at: indexPath))
            completionHandler(true)
        })
        
//        action.title = "B"
//        action.image = UIImage(named: <#T##String#>)
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
}
