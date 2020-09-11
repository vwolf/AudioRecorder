//
//  TakeVC.swift
//  AudioRecorder
//
//  Created by Wolf on 04.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

import Foundation
import UIKit

/**
 Take details
 */
class TakeVC: UIViewController, CategoryPopoverDelegate  {
  
    
    @IBOutlet weak var collectionView: UICollectionView!
    var takeMO:TakeMO?
    var take = Take()
    
    var categoryDict = [String: [String]]()
    var categorys = [String]()
    
    var modified = false
    var newTakeName = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(UINib.init(nibName: "MDataStaticCell", bundle: nil), forCellWithReuseIdentifier: "MDataStaticCell")
        collectionView.register(UINib.init(nibName: "MDataEditCell", bundle: nil), forCellWithReuseIdentifier: "MDataEditCell")
        collectionView.register(UINib.init(nibName: "MDataActiveDoubleCell", bundle: nil), forCellWithReuseIdentifier: "MDataActiveDoubleCell")
        collectionView.register(UINib.init(nibName: "MDataTextEditCell", bundle: nil), forCellWithReuseIdentifier: "MDataTextEditCell")
        
        collectionView.register(UINib.init(nibName: "MDataSectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "MDataSectionHeader")
        
        if (takeMO != nil) {
            print(takeMO!.name!)
            take = Take(withTakeMO: takeMO!)
        }
        
        collectionView.contentInset = .zero
        
        let estimatedItemWidth = UIScreen.main.bounds.size.width
        print("estimatedItemWidth: \(estimatedItemWidth)")
        //widthConstraint.constant = screenWidth - (2 * 8)
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            //flowLayout.estimatedItemSize = CGSize(width: estimatedItemWidth, height: 80)
            flowLayout.headerReferenceSize = CGSize(width: self.view.frame.width, height: 60)
            
        }
        
        collectionView.layoutIfNeeded()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive
        
        // categories
        categoryDict = CategoryParser().parseCategories()
        categorys = Array(categoryDict.keys)
        categorys.sort()
        
        // register keyboard change notifications
        let notifictationCenter = NotificationCenter.default
        notifictationCenter.addObserver(self, selector: #selector(adjustForKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil )
        notifictationCenter.addObserver(self, selector: #selector(adjustForKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil )
        
    }
    
//    override func willMove(toParent parent: UIViewController?) {
//        super.willMove(toParent: parent)
//
//        if parent == nil {
//            print("willMove")
//
//            if modified == true {
//                var topVC = UIApplication.shared.keyWindow?.rootViewController
//                while let presentedViewController = topVC?.presentedViewController {
//                    topVC = presentedViewController
//                }
//                DispatchQueue.main.async {
//                    let alertController = self.alertOnNavigationBack(completion: { saveTake in
//                        if saveTake {
//                            print("save take!!!")
//                            self.take.updateMetaDataForTake(takeNameWithExtension: self.take.takeName!  + "." + (self.take.takeType ?? "wav"))
//
//
//                        }
//                    })
//
//                    topVC?.present(alertController, animated: true, completion: nil)
//                }
//            }
//        }
//
//    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        if let vc = self.findParentController() as TakesVC? {
//            print ("TakesVC: \(vc.takes.count)")
//        }
        
        //self.findViewController()
        
        if isMovingToParent {
            print("isMovingToParent")
        }
        
        if isMovingFromParent && modified == true {
            
            var topVC = UIApplication.shared.keyWindow?.rootViewController
            while let presentedViewController = topVC?.presentedViewController {
                topVC = presentedViewController
            }
            
            DispatchQueue.main.async {
                let alertController = self.alertOnNavigationBack(completion: { saveTake in
                    if saveTake {
                        print("Save changes!")
                        self.take.updateMetaDataForTake(takeNameWithExtension: self.take.takeName! + "." + (self.take.takeType ?? "wav"))
                    }
                })
                
                topVC?.present(alertController, animated: true, completion: nil)
            }
            
            // new take name then reload TakeVC table data
            if self.newTakeName == true {
                if let viewControllers = self.navigationController?.viewControllers {
                    if (viewControllers.count >= 1) {
                        let previousViewController = viewControllers[viewControllers.count - 1] as! TakesVC
                        
                        if self.modified == true {
                            previousViewController.reloadTakes()
                        }
                        
                    }
                }
            }
        }
//        if isMovingFromParent && modified == true {
//            print("isMovingFromParent")
//
//            var topVC = UIApplication.shared.keyWindow?.rootViewController
//            while let presentedViewController = topVC?.presentedViewController {
//                topVC = presentedViewController
//            }
//            DispatchQueue.main.async {
//                let alertController = self.alertOnNavigationBack(completion: { saveTake in
//                    if saveTake {
//                        print("save take!!!")
//                        self.take.updateMetaDataForTake(takeNameWithExtension: self.take.takeName!  + "." + (self.take.takeType ?? "wav"))
//
//
//                    }
//                })
//
//                topVC?.present(alertController, animated: true, completion: nil)
//            }
//
//        }
    }
    
    @objc func alertOnNavigationBack(completion: @escaping (Bool) -> ()) -> UIAlertController {
        let ok = UIAlertAction(title: "Save", style: .default) { _ in
            completion(true)
        }
        let cancel = UIAlertAction(title: "No", style: .cancel) { _ in
            completion(false)
        }
        
        let alertController = UIAlertController(title: "Save Changes", message: "message", preferredStyle: .alert)
        alertController.addAction(ok)
        alertController.addAction(cancel)
        
        return alertController
//        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func alertFileName(name: String, completion: @escaping (Bool) -> ()) -> UIAlertController {
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            completion(true)
        }
        
        let alertController = UIAlertController(title: "Cant change name", message: "Take \(name) exist!", preferredStyle: .alert)
        alertController.addAction(ok)
        
        return alertController
    }
    
    /**
     Possible states:
     - category and subcategory are emtpy - send categories perdefined when categoryType == category
     - category set with predefined value, subcategory empty - send subcategories perdefined
     - category set with custom value, subcategory empty - send empty subcategories
     - category set with perdefined value, subcategory with perdefined value
     - category set with perdefined value, subcategory with custom value
     - category set with custom value, subcategory with perdefined value
     - category set with custom value, subcategory with custom value
     - category empty and subcategory not empty? That's not valid
     
     Clear subcategory when category is empty
     
     - parameter cellIdx: selected cell index
     - parameter categoryType: category or subcategory
    */
    func presentCategoryPopover(cellIdx: Int, categoryType: String) {
        
        // always set to predefined categories
        if categoryType == "category" {
            categorys = Array(categoryDict.keys).sorted(by: {$0 < $1} )
        }
        
        if categoryType == "subcategory" {
            let currentCategoryName = take.getItemForID(id: "addCategory", section: .METADATASECTION)?.value
            if currentCategoryName != nil {
                // is predefined category?
                let currentCategory = categoryDict.first(where: { $0.key == currentCategoryName as! String})
                if currentCategory != nil {
                    categorys = (currentCategory?.value)!
                } else {
                    categorys.removeAll()
                }
            }
        }
     
        let popoverContentController = CategoryPopoverVC(nibName: "CategoryPopoverView", bundle: nil)
        popoverContentController.categoryType = categoryType
        popoverContentController.sortedCategories = categorys
        popoverContentController.cellIdx = cellIdx
        popoverContentController.delegate = self
        self.present(popoverContentController, animated: true)
        
    }
    
    // MARK: Keyboard change notifications
    
    @objc func adjustForKeyboardWillShow(notification: Notification) {
        print("TakeVC: keyboardWillShow")
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print("keyboard height: \(keyboardSize.height)")
            let userInfo = notification.userInfo!
            let animationDuration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            collectionView.isScrollEnabled = true
            
            UIView.animate(
            withDuration: animationDuration) {
//                               self.collectionView.layoutIfNeeded()
                                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func adjustForKeyboardWillHide(notifiction: Notification) {
        print("keyboardWillHide")
        
        collectionView.contentInset = .zero
    }
    
    // MARK: DELEGATE CategoryPopoverVC
    
    /**
     Category returned from popup modal
     Parameter userText can be empty string, then set state
        
     ToDo: 
     - Parameters:
        - userText: Category from popup
        - cellIdx: Index of selected cell
        - categoryType: category or subcategory
    */
    func saveCategory(userText: String, cellIdx: Int, categoryType: String) {
        print("Category: \(userText) for cell: \(cellIdx)")
        
        let sectionIndex = take.getItemSectionIndex(section: .METADATASECTION)
        let cellData = take.items[sectionIndex!][cellIdx]
        
        if categoryType == "category" {
            cellData.value = userText
        }
        if categoryType == "subcategory" {
            cellData.children?.first?.value = userText
        }
        
        //let idp = IndexPath(item: cellIdx, section: sectionIndex!)
        //collectionView.reloadItems(at: [idp])
        collectionView.reloadSections(IndexSet(integer: sectionIndex!))
        modified = true
        
        //collectionView.reloadData()
    }
    
}


extension TakeVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return take.items[section].count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return take.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemId = take.items[indexPath.section][indexPath.row].id
        
        switch itemId {
        case "takeName" :
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataEditCell", for: indexPath) as! MDataEditCellController
            let takeItem = take.items[indexPath.section][indexPath.row]
            
            cell.nameLabel.text = takeItem.name
            cell.descriptionLabel.text = takeItem.description
            
            //cell.contentView.isUserInteractionEnabled = false
            cell.valueTextField.text = takeItem.value as! String?
            cell.originalValue = cell.valueTextField.text!
            
            cell.maxWidth = collectionView.bounds.width - 16
            
            cell.updateValue = { value, id in
                // validate new file name
                let checkResult = Takes().checkFileName(newTakeName: value, takeName: takeItem.value as! String, fileExtension: self.take.takeType ?? "wav")
                
                print("validationResult: \(checkResult)")
                switch checkResult {
                case "noChanges":
                    // do nothing
                    print("do nothing")
                    let al = self.alertFileName(name: value, completion:  { _ in
                        print("alert dismiss")
                    })
                    self.present(al, animated: true)
                    
                case "notUnique":
                    print("show alert")
                    
                default:
                    let takeNameWithExtensions = self.take.takeName! + "." + (self.take.takeType ?? "wav")
                    if Takes().renameTake(takeName: takeNameWithExtensions, newTakeName: value) {
                        self.take.getItemForID(id: id, section: MetaDataSections.RECORDINGDATA)?.value = value
                        //self.take.takeName = value
                        self.modified = true
                        self.newTakeName = true
                    }
                }
                
            }
            
            cell.id = itemId
            return cell
            
        case "addCategory":
            // category item can have two items, category and subcategory
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataActiveDoubleCell", for: indexPath) as! MDataActiveDoubleCellController
            let takeItem = take.items[indexPath.section][indexPath.row]
            cell.nameLabel.text = takeItem.name
            cell.descriptionLabel.text = takeItem.description
            cell.valueLabel.text = takeItem.value as! String?

            //cell.contentView.isUserInteractionEnabled = false
            // use btn.tak to identify the cell later
            cell.valueBtn.tag = indexPath.row
            cell.valueBtn.addTarget(self, action: #selector(categoryBtnTouched(_:)), for: .touchUpInside)

            cell.maxWidth = collectionView.bounds.width - 16
            
            let categoryValueSet = !(takeItem.value as! String).isEmpty

            if !categoryValueSet {
                // no category value, hide subCategory section
               // cell.subValueLabel.isHidden = true
                cell.subValueBtn.isEnabled = false
                cell.subValueLabel.text = ""
            } else {
                if takeItem.children != nil {
                    if takeItem.children?.first != nil {
                        cell.subValueLabel.text = takeItem.children?.first?.value as! String?
                        cell.subValueBtn.isEnabled = true
                        cell.subValueBtn.addTarget(self, action: #selector(subcategoryBtnTouched(_:)), for: .touchUpInside)
                    }
                }
            }
            // children
//            if takeItem.children != nil {
//                // first item for subcategory
//                if takeItem.children?.first != nil {
//                    cell.subValueLabel.text = takeItem.children?.first?.value as! String?
//                    if cell.subValueLabel.text == "" {
//                        cell.subValueLabel.isHidden = true
//                        cell.subValueBtn.isHidden = true
//                    }
//                } else {
//                    cell.subValueLabel.isHidden = true
//                    cell.subValueBtn.isHidden = true
//                }
//            } else {
//                cell.subValueLabel.isHidden = true
//                cell.subValueBtn.isHidden = true
//            }
            return cell

//        case "description":
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataTextEditCell", for: indexPath) as! MDataTextEditCellController
//            let takeItem = take.items[indexPath.section][indexPath.row]
//
//            cell.nameLabel.text = takeItem.name
//            cell.descriptionLabel.text = takeItem.description
//            cell.valueTextView.text = takeItem.value as! String?
//
//            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataStaticCell", for: indexPath) as! MDataStaticCellController
            
            let takeItem = take.items[indexPath.section][indexPath.row]
            cell.nameLabel.text = takeItem.name
            cell.descriptionLabel.text = takeItem.description
            cell.ValueLabel.text = takeItem.value as! String?
            cell.maxWidth = collectionView.bounds.width - 16
            
            return cell
        }
    }
    
    
    /**
     Header view for sections
     */
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "MDataSectionHeader", for: indexPath) as! MDataSectionHeader
        
        view.headerName.text = take.getHeaderForSection(sectionIndex: indexPath.section)
        
        return view
    }
    
    
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: collectionView.frame.size.width, height: 60)
//    }
    
    // MARK: Item button events
    
    @objc func categoryBtnTouched(_ sender: UIButton) {
        // open category overlay
        print("categoryBtnTouched")
        presentCategoryPopover(cellIdx: sender.tag, categoryType: "category")
    }
    
    @objc func subcategoryBtnTouched(_ sender: UIButton) {
        presentCategoryPopover(cellIdx: sender.tag, categoryType: "subcategory")
    }
}


extension UIViewController {
    func findParentController<T: UIViewController>() -> T? {
        return self is T ? self as? T : self.parent?.findParentController() as T?
    }
    
    func findViewController() -> UIViewController? {
        var traveled = false
         var nextResponder = self.next
        
        while traveled == false {
            nextResponder = nextResponder?.next
            print(nextResponder.debugDescription)
            
            if nextResponder == nil { traveled = true }
        }
        
        return nil
//        if let nextResponder = self.next as? UIViewController {
//            return nextResponder
//        } else {
//            return nil
//        }
    }
}
