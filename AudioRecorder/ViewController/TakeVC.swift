//
//  TakeVC.swift
//  AudioRecorder
//
//  Created by Wolf on 04.09.20.
//  Copyright © 2020 Wolf. All rights reserved.
//

/**
 
 */
import Foundation
import UIKit

/**
 Take details
 
 # Notes: #
 Rename take needs an overhaul
 
 - ToDo: rename take needs an overhaul
 */
class TakeVC: UIViewController, UIPopoverPresentationControllerDelegate,  CategoryPopoverDelegate  {
  
    
    @IBOutlet weak var collectionView: UICollectionView!
    var takeMO:TakeMO?
    var take = Take()
    
    var categoryDict = [String: [String]]()
    var categorys = [String]()
    
    var modified = false
    var newTakeName = false
    
    var selectedItemWithTextField: IndexPath?
    
    var imagePicker: ImagePicker!
    var imageCell: MDataImageCellController?
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(UINib.init(nibName: "MDataStaticCell", bundle: nil), forCellWithReuseIdentifier: "MDataStaticCell")
        collectionView.register(UINib.init(nibName: "MDataEditCell", bundle: nil), forCellWithReuseIdentifier: "MDataEditCell")
        collectionView.register(UINib.init(nibName: "MDataActiveDoubleCell", bundle: nil), forCellWithReuseIdentifier: "MDataActiveDoubleCell")
        collectionView.register(UINib.init(nibName: "MDataTextEditCell", bundle: nil), forCellWithReuseIdentifier: "MDataTextEditCell")
        collectionView.register(UINib.init(nibName: "MDataImageCell", bundle: nil), forCellWithReuseIdentifier: "MDataImageCell")
        collectionView.register(UINib.init(nibName: "MDataAudioCell", bundle: nil), forCellWithReuseIdentifier: "MDataAudioCell")
        
        collectionView.register(UINib.init(nibName: "MDataSectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "MDataSectionHeader")
        
        if (takeMO != nil) {
            print(takeMO!.name!)
            take = Take(withTakeMO: takeMO!)
        }
        
        collectionView.contentInset = .zero
        collectionView.backgroundColor = Colors.Base.background_item.toUIColor()
        
        let estimatedItemWidth = UIScreen.main.bounds.size.width
        print("estimatedItemWidth: \(estimatedItemWidth)")
        //widthConstraint.constant = screenWidth - (2 * 8)
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            //flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.estimatedItemSize = CGSize(width: estimatedItemWidth, height: 80)
            flowLayout.headerReferenceSize = CGSize(width: self.view.frame.width, height: 60)
            
        }
        
        collectionView.layoutIfNeeded()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive
        collectionView.endEditing(true)
        
        // categories
        categoryDict = CategoryParser().parseCategories()
        categorys = Array(categoryDict.keys)
        categorys.sort()
        
        // register keyboard change notifications
        let notifictationCenter = NotificationCenter.default
        notifictationCenter.addObserver(self, selector: #selector(adjustForKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil )
        notifictationCenter.addObserver(self, selector: #selector(adjustForKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil )
//        notifictationCenter.addObserver(self, selector: #selector(adjustForKeyboarDidHide), name: UIResponder.keyboardDidHideNotification, object: nil )
        
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
        
        //self.findViewController()
        
        if isMovingToParent {
            print("isMovingToParent")
        }
        
        modified = false
        
        // new take name then reload TakeVC table data
        if self.newTakeName == true {
            if let viewControllers = self.navigationController?.viewControllers {
                if (viewControllers.count >= 1) {
                    let previousViewController = viewControllers[viewControllers.count - 1] as! TakesVC
                        previousViewController.reloadTakes()
                }
            }
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
        
        //self.removeObserver(self, forKeyPath: <#T##String#>)
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
            let currentCategoryName = take.getItemForID(id: "category", section: .METADATASECTION)?.value
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
    
    func presentMetadataAddPopover(typ: String) {
        
        let popoverContentController = MetadataAddPopoverVC(nibName: "MetadataAddPopoverView", bundle: nil)
        if #available(iOS 13.0, *) {
            popoverContentController.take = take
            popoverContentController.modalPresentationStyle = .automatic
            
            popoverContentController.presentationController?.delegate = self
        } else {
            if #available(iOS 10.3, *) {
                popoverContentController.take = take
                //popoverContentController.delegate = self
                popoverContentController.modalPresentationStyle = .popover
                
                if let popoverPresentationController = popoverContentController.popoverPresentationController {
                    popoverPresentationController.sourceView = self.view
                    //popoverPresentationController.sourceRect = (navigationController?.view.bounds)!
                    popoverPresentationController.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 20)
                    popoverPresentationController.delegate = self
                }
            }
        }
        
        
        
//        popoverContentController.presentationController?.containerView?.frame.size.height = 200
//        popoverContentController.presentationController?.delegate = self
        
//        popoverContentController.popoverPresentationController?.delegate = self
//        popoverContentController.popoverPresentationController?.sourceView = view
//        popoverContentController.popoverPresentationController?.sourceRect = CGRect(x: view.frame.minX,
//                                                                                    y: view.frame.midY,
//                                                                                    width: view.frame.size.width,
//                                                                                    height: view.frame.size.height - 50)
//        popoverContentController.popoverPresentationController?.containerView?.frame.size.height = view.frame.size.height / 2
        
        self.present(popoverContentController, animated: true) {
            print("MetadataAddPopover didAppear")
        }
    }
    
    
    func presentMetadataAudioPopover() {
        let popoverContentController = MDataAudioPopoverVC(nibName: "MDataAudioPopover", bundle: nil)
        popoverContentController.take = take
        popoverContentController.recordingType = .NOTE
        
        self.present(popoverContentController, animated: true) {
            
        }
    }
    
    func preseentAudioPlayerPopover(audioURL: URL) {
        let popoverContentController = self.storyboard?.instantiateViewController(withIdentifier: "ModalAudioPlayerView") as? ModalAudioPlayerVC
        
        popoverContentController?.modalPresentationStyle = .popover
        popoverContentController?.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 320)
        popoverContentController?.view.backgroundColor = Colors.AVModal.background.toUIColor()
        
        if let popoverPresentationController = popoverContentController?.popoverPresentationController {
            popoverPresentationController.delegate = self
            // no arrow on popover
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popoverPresentationController.backgroundColor = Colors.Base.background.toUIColor()
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: 10, y: self.view.bounds.height / 2 + 120, width: self.view.frame.size.width, height: 240)
            
            if let popoverController = popoverContentController {
                present(popoverController, animated: true, completion: nil)
                
                popoverContentController?.takeURL = audioURL
            }
        }
    }
    
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        print("dismiss")
    }
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: Keyboard change notifications
    
    @objc func adjustForKeyboardWillShow(notification: Notification) {
        print("TakeVC: keyboardWillShow")
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            print("keyboard height: \(keyboardSize.height)")
//            let userInfo = notification.userInfo!
//            let animationDuration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
//            let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
//            collectionView.contentInset = contentInset
//            collectionView.isScrollEnabled = true
//            collectionView.scrollIndicatorInsets = contentInset
            if selectedItemWithTextField != nil {
                collectionView.scrollToItem(at: selectedItemWithTextField!, at: .top, animated: true)
            }
            //collectionView.scrollToItem(at: IndexPath(row: 1, section: 1), at: .top, animated: true)
            //collectionView.setNeedsLayout()
           
            //collectionView.setContentOffset(<#T##contentOffset: CGPoint##CGPoint#>, animated: <#T##Bool#>)
//            UIView.animate(
//            withDuration: animationDuration) {
////                               self.collectionView.layoutIfNeeded()
////                                self.view.layoutIfNeeded()
//            }
        }
    }
    
    @objc func adjustForKeyboardWillHide(notifiction: Notification) {
        print("keyboardWillHide")
        
        selectedItemWithTextField = nil
        collectionView.contentInset = .zero
        collectionView.scrollIndicatorInsets = .zero
        
        //collectionView.setNeedsLayout()
        //collectionView.layoutIfNeeded()
    }
    
    
    @objc func adjustForKeyboarDidHide(notification: Notification) {
        print("keyboardDidHide")
        
        selectedItemWithTextField = nil
        //collectionView.contentInset = .zero
        //collectionView.scrollIndicatorInsets = .zero
        
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
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
        //collectionView.reloadSections(IndexSet(integer: sectionIndex!))
        modified = true
        
        collectionView.reloadData()
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
            
            cell.contentView.backgroundColor = Colors.Base.background_item.toUIColor()
            cell.nameLabel.text = takeItem.name
            cell.nameLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.descriptionLabel.text = takeItem.description
            cell.descriptionLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.valueTextField.text = takeItem.value as! String?
            cell.valueTextField.textColor = Colors.Base.text_01.toUIColor()
            cell.originalValue = cell.valueTextField.text!
            cell.maxWidth = collectionView.bounds.width - 16
            cell.takeVC = self
            
            cell.updateValue = { value, id in
                // validate new file name
                let checkResult = Takes().checkFileName(newTakeName: value, takeName: takeItem.value as! String, fileExtension: self.take.takeType ?? "wav")
                
                print("validationResult: \(checkResult)")
                switch checkResult {
                case "noChanges":
                    // do nothing
                    print("do nothing")
                    
                case "notUnique":
                    print("show alert")
                    let al = self.alertFileName(name: value, completion:  { _ in
                        print("alert dismiss")
                    })
                    self.present(al, animated: true)
                    
                default:
                    let takeNameWithExtension = self.take.takeName! + "." + (self.take.takeType ?? "wav")
                    if Takes().renameTake(takeName: takeNameWithExtension, newTakeName: value) {
                        self.take.renameTakeNote(oldName: takeNameWithExtension, newName: value)
                        self.take.getItemForID(id: id, section: MetaDataSections.RECORDINGDATA)?.value = value
                        self.take.updateMetaDataForTake(takeNameWithExtension: takeNameWithExtension)
                        //self.take.takeName = value
                        self.modified = true
                        self.newTakeName = true
                    }
                }
                
            }
            
            cell.id = itemId
            return cell
            
        case "category":
            // category item can have two items, category and subcategory
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataActiveDoubleCell", for: indexPath) as! MDataActiveDoubleCellController
            let takeItem = take.items[indexPath.section][indexPath.row]
            
            cell.contentView.backgroundColor = Colors.Base.background_item.toUIColor()
            cell.nameLabel.text = takeItem.name
            cell.nameLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.descriptionLabel.text = takeItem.description
            cell.descriptionLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.valueLabel.text = takeItem.value as! String?
            cell.valueLabel.textColor = Colors.Base.text_01.toUIColor()

            //cell.contentView.isUserInteractionEnabled = false
            // use btn.tak to identify the cell later
            cell.valueBtn.tintColor = Colors.Base.baseGreen.toUIColor()
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
                        cell.subValueLabel.textColor = Colors.Base.text_01.toUIColor()
                        cell.subValueBtn.isEnabled = true
                        cell.subValueBtn.tintColor = Colors.Base.baseGreen.toUIColor()
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

        case "description":
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataTextEditCell", for: indexPath) as! MDataTextEditCellController
            let takeItem = take.items[indexPath.section][indexPath.row]

            cell.nameLabel.text = takeItem.name
            cell.nameLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.descriptionLabel.text = takeItem.description
            cell.descriptionLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.valueTextView.text = takeItem.value as! String?
            cell.originalValue = cell.valueTextView.text
            cell.maxWidth = collectionView.bounds.width - 16
            cell.takeVC = self
            
            cell.updateValue = { value, id in
                self.take.getItemForID(id: id, section: MetaDataSections.METADATASECTION)?.value = value
                self.modified = true
            }
            
            cell.id = itemId
            return cell
        
        case "image" :
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataImageCell", for: indexPath) as! MDataImageCellController
            let takeItem = take.items[indexPath.section][indexPath.row]
            
            cell.nameLabel.text = takeItem.name
            cell.nameLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.descriptionLabel.text = takeItem.description
            cell.descriptionLabel.textColor = Colors.Base.text_01.toUIColor()
            
           // cell.contentView.isUserInteractionEnabled = false
            cell.imageView.isUserInteractionEnabled = true
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageCellTouched( _:) ))
            cell.imageView.addGestureRecognizer(tapGestureRecognizer)
            imageCell = cell
            
            cell.maxWidth = collectionView.bounds.width - 16
            
            cell.setImage(urlString: takeItem.value as! String)
            
            return cell
        
        case "audio" :
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataAudioCell", for: indexPath) as! MDataAudioCellController
            let takeItem = take.items[indexPath.section][indexPath.row]
            
            cell.nameLabel.text = takeItem.name
            cell.nameLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.descriptionLabel.text = takeItem.description
            cell.descriptionLabel.textColor = Colors.Base.text_01.toUIColor()
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recordAudioCellBtnTouched(_:)))
            cell.audioRecordBtn.addGestureRecognizer(tapGestureRecognizer)
            
            cell.maxWidth = collectionView.bounds.width - 16
            
            if let noteURL = take.getNoteForTake() {
                print("note for take exist!!!")
                cell.audioPlayBtn.isEnabled = true
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(recordAudioCellPlayBtntTouched(_:) ))
                cell.audioPlayBtn.addGestureRecognizer(gestureRecognizer)
                cell.audioPlayBtn.tag = indexPath.row
                cell.audioURL = noteURL
            } else {
                cell.audioPlayBtn.isEnabled = false
            }
            
            return cell
            
        case "keyboard" :
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataEditCell", for: indexPath) as! MDataEditCellController
            let takeItem = take.items[indexPath.section][indexPath.row]
            
            cell.nameLabel.text = takeItem.name
            cell.descriptionLabel.text = takeItem.description
            cell.valueTextField.text = takeItem.value as! String?
            cell.originalValue = cell.valueTextField.text!
            
            cell.maxWidth = collectionView.bounds.width - 16
            
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MDataStaticCell", for: indexPath) as! MDataStaticCellController
            
            let takeItem = take.items[indexPath.section][indexPath.row]
            cell.nameLabel.text = takeItem.name
            cell.nameLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.descriptionLabel.text = takeItem.description
            cell.descriptionLabel.textColor = Colors.Base.text_01.toUIColor()
            cell.ValueLabel.text = takeItem.value as! String?
            cell.ValueLabel.textColor = Colors.Base.text_01.toUIColor()
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
        
        let sectionID = take.getHeaderIDForSection(sectionIndex: indexPath.section)
        if sectionID != nil {
            view.contentView.backgroundColor = Colors.Base.background.toUIColor()
            view.headerBtn.tintColor = Colors.Base.baseGreen.toUIColor()
            
            if sectionID != MetaDataSections.METADATASECTION {
                view.headerBtn.isHidden = true
            } else {
                view.headerBtn.isHidden = false
                view.headerBtn.addTarget(self, action: #selector(metadataAddBtnTouched(_:)), for: .touchUpInside)
            }
            
            view.headerName.textColor = Colors.Base.text_02.toUIColor()
            view.headerName.text = sectionID?.rawValue
        }
        //view.headerName.text = take.getHeaderForSection(sectionIndex: indexPath.section)
        
        return view
    }
    
    
//    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//        print("shouldSelectItemAt")
//        return true
//    }
    
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: collectionView.frame.size.width, height: 60)
//    }
    
    // MARK: Item button events
    
    @objc func categoryBtnTouched(_ sender: UIButton) {
        // open category overlay
        print("categoryBtnTouched")
        let cellIdx = take.getItemIndexInSection(id: "category", section: .METADATASECTION)!
        presentCategoryPopover(cellIdx: cellIdx, categoryType: "category")
    }
    
    @objc func subcategoryBtnTouched(_ sender: UIButton) {
        let cellIdx = take.getItemIndexInSection(id: "category", section: .METADATASECTION)!
        presentCategoryPopover(cellIdx: cellIdx, categoryType: "subcategory")
    }
    
    @objc func metadataAddBtnTouched(_ sender: UIButton) {
        print("metadataAddBtnTouched")
        presentMetadataAddPopover(typ: "metadata")
    }
    
    @objc func imageCellTouched(_ sender: AnyObject) {
        print("imageCellTouched")
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        imagePicker.present(from: self.view)
    }
    
    @objc func recordAudioCellBtnTouched(_ sender: UIButton) {
        presentMetadataAudioPopover()
    }
    
    @objc func recordAudioCellPlayBtntTouched(_ sender: UIButton) {
        guard let audioURL = take.getNoteForTake() else { return  }
        preseentAudioPlayerPopover(audioURL: audioURL)
    }
}

extension TakeVC: ImagePickerDelegate {
    func didSelect(image: UIImage) {
        imageCell?.imageView.image = image
    }
    
    func didSelect(image: UIImage, imageURL: NSURL) {
        imageCell?.imageView.image = image
        
        imageCell?.imageURL = imageURL
        
        let result = take.updateItem(id: "image", value: imageURL.absoluteString!, section: .METADATASECTION)
        if result {
            take.updateTake()
        }
    }
}


// MARK: PresentationControllerDelegate

extension TakeVC: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("Presented view did dismiss")
        
        if take.takeModified {
            collectionView.reloadData()
        }
    }
}
//extension UIViewController {
//    func findParentController<T: UIViewController>() -> T? {
//        return self is T ? self as? T : self.parent?.findParentController() as T?
//    }
//
//    func findViewController() -> UIViewController? {
//        var traveled = false
//         var nextResponder = self.next
//
//        while traveled == false {
//            nextResponder = nextResponder?.next
//            print(nextResponder.debugDescription)
//
//            if nextResponder == nil { traveled = true }
//        }
//
//        return nil
////        if let nextResponder = self.next as? UIViewController {
////            return nextResponder
////        } else {
////            return nil
////        }
//    }
//}
