//
//  AddSuggestionViewController.swift
//  Tagabout
//
//  Created by Karun Pant on 03/03/18.
//  Copyright © 2018 Tagabout. All rights reserved.
//

import UIKit
import DropDown
import SkyFloatingLabelTextField
import LabelSwitch



class AddSuggestionViewController: UIViewController {
    
    enum AddSuggestionUIType : Int{
        case subCategory
        case microCategory
        case name
        case isCityLevel
        case contact
        case location
        case comments
    }
    
    fileprivate let selectedSubCategoryValue = "SubCategoryId"
    fileprivate let selectedCategoryValue = "CatId"
    fileprivate let selectedSubCategoryName = "~UIDATA~subCat"
    fileprivate let selectedMicroCategoryValue = "~UIDATA~microCat"
    fileprivate let commentValue = "comments"
    fileprivate let contactValue = "~UIDATA~contactValue"
    fileprivate let businessNameValue = "BusinessName"
    fileprivate let cityLevel = "CitiLevelBusiness"
    fileprivate let locationKey = "Location"
    
    var isForEdit: Bool = false
    var categories : [Category]?
    // fill contact details
    var selectedCategory : Category?
    var selectedSubCategory : Subcategory?
    var microCategories : [MicroCategory]?
    var viewList : [AddSuggestionUIType]{
        get{
            if let selectedCategory = selectedCategory{
                if let microcatAvailable = selectedCategory.isMicroCategoryAvailable, microcatAvailable {
                    return [.subCategory, .microCategory, .name, .isCityLevel, .contact, .location, .comments]
                }
                return [.subCategory, .name, .isCityLevel, .contact, .location, .comments]
            }
            return [AddSuggestionUIType]()
        }
    }
    fileprivate lazy var interactor = AddSuggestionInteractor()
    fileprivate lazy var locationInteractor = AddLocationInteractor()
    fileprivate var previousSelectedSection : TAISection?
    
    fileprivate var selectionData : [String : Any] = [String : Any]()
    
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var addButton: TAIAction!
    @IBOutlet weak var sectionView: UIView!
    @IBOutlet weak var section1: TAISection!
    @IBOutlet weak var section2: TAISection!
    @IBOutlet weak var section3: TAISection!
    @IBOutlet weak var scrollBarBottom: NSLayoutConstraint!
    
    @IBOutlet weak var microCat1: DropDownView!
    @IBOutlet weak var microCat1Height: NSLayoutConstraint!
    
    @IBOutlet weak var microCat2: DropDownView!
    @IBOutlet weak var microCat2Height: NSLayoutConstraint!
    
    @IBOutlet weak var isLocal: LabelSwitch!
    
    @IBOutlet weak var isAChain: LabelSwitch!
    
    @IBOutlet weak var name: TextFieldView!
    @IBOutlet weak var contact: TextFieldView!
    @IBOutlet weak var location: TextFieldView!
    
    @IBOutlet weak var details: FloatLabelTextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var lblSelectedCategory: UILabel!
    
    private var tabController : TabbarController?
    
    private var locations: [Location]? {
        didSet {
            updateDataSourceForDropDown()
        }
    }
    
    private lazy var dropDown = DropDown()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tabController = self.tabBarController as? TabbarController
        
        self.sectionView.backgroundColor = Theme.grey
        self.emptyStateLabel.text = "Loading categories..."
        self.addButton.isEnabled = false
        DropDown.startListeningToKeyboard()
        
        self.scrollView.isHidden = true
        
        tabController?.showThemedLoader(true)
        interactor.getCategories { [weak self] categories in
            guard let strongSelf = self else{ return }
            strongSelf.tabController?.showThemedLoader(false)
            strongSelf.emptyStateLabel.text = "Select a category to continue."
            if let categories = categories{
                strongSelf.categories = categories
                if categories.count >= 3{
                    strongSelf.section1.setTitle(categories[0].name?.uppercased(), for: .normal)
                    strongSelf.section2.setTitle(categories[1].name?.uppercased(), for: .normal)
                    strongSelf.section3.setTitle(categories[2].name?.uppercased(), for: .normal)
                }
            }
        }
    }
    
    
    private func clearAll(){
        self.location.textField.text = ""
        self.name.textField.text = ""
        self.microCat1.textField.text = ""
        self.microCat2.textField.text = ""
        self.contact.textField.text = ""
        self.details.text = ""
    }
    
    @IBAction func doCategorySelection(sender : TAISection){
        self.view.endEditing(true)
        clearAll()
        if let categories = categories, categories.count >= 3{
            let tag = sender.tag
            selectedCategory = categories[tag]
            guard let selectedCategory = selectedCategory,
                let subcats = selectedCategory.subCategories,
                subcats.count > 0  else{
                    self.lblSelectedCategory.text = "Suggestion"
                    if let previousSelected = self.previousSelectedSection{
                        previousSelected.isSectionSelected = false
                    }
                    sender.isSectionSelected = true
                    self.previousSelectedSection = sender
                    self.configureForm(isMicroCatAvailable: false)
                    self.scrollView.isHidden = false
                    return
            }
            
            let dropDown = DropDown()
            dropDown.dataSource = subcats.map{ $0.name ?? "" }
            dropDown.shadowRadius = 1
            dropDown.shadowOpacity = 0.2
            dropDown.bottomOffset = CGPoint(x: 0, y:(sender.bounds.size.height + 5))
            dropDown.dismissMode = .automatic
            dropDown.show()
            dropDown.anchorView = sender
            dropDown.selectionAction = {[weak self] (index: Int, item: String) in
                guard let strongSelf = self else{ return }
                strongSelf.selectionData[strongSelf.selectedSubCategoryName] = item
                let selectedSubCat = subcats[index]
                if let subCatId = selectedSubCat.subCatId {
                    strongSelf.selectionData[strongSelf.selectedSubCategoryValue] = subCatId
                }
                
                // configure
                strongSelf.lblSelectedCategory.text = "\(item)"
                if let previousSelected = strongSelf.previousSelectedSection{
                    previousSelected.isSectionSelected = false
                }
                sender.isSectionSelected = true
                strongSelf.previousSelectedSection = sender
                strongSelf.scrollView.isHidden = false
                if let isMicroCategoryAvailable = selectedCategory.isMicroCategoryAvailable, isMicroCategoryAvailable {
                    let selectedSubCat = subcats[index]
                    if let subCatId = selectedSubCat.subCatId {
                        // get micro categories for selected subcategory.
                        strongSelf.tabController?.showThemedLoader(true)
                        strongSelf.interactor.getMicroCategoriesFor(subcategoryId: subCatId, completion: { (microCategories) in
                            strongSelf.tabController?.showThemedLoader(false)
                            strongSelf.microCategories = microCategories
                            strongSelf.configureForm(isMicroCatAvailable: true)
                        })
                    }
                }else{
                    strongSelf.configureForm(isMicroCatAvailable: false)
                }
            }
            
        }
    }
    @IBAction func addLocation(_ sender: UIButton) {
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension AddSuggestionViewController{
    // drop down
    
    func openMicroCatPickerFor(_ microCategories: [MicroCategory]?, withAnchor anchor: UITextField) {
        
        guard let microCategories = microCategories, microCategories.count > 0 else { return }
        
        let dropDown = DropDown()
        
        // The view to which the drop down will appear on
        dropDown.anchorView = anchor // UIView or UIBarButtonItem
        dropDown.shadowRadius = 1
        dropDown.shadowOpacity = 0.2
        dropDown.bottomOffset = CGPoint(x: 0, y:38)
        // The list of items to display. Can be changed dynamically
        dropDown.dataSource = microCategories.map({ (microCat) in
            if let name = microCat.name {
                return name
            }
            return ""
        })
        
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let strongSelf = self else{ return }
            strongSelf.selectionData[strongSelf.selectedMicroCategoryValue] = item
        }
        
        dropDown.show()
    }
}

extension AddSuggestionViewController{
    
    func validateAllMandatoryFields() {
        let isValidForm = name.isValid() && contact.isValid() && microCat1.isValid() && (details != nil)
        self.addButton.isEnabled = true
    }
    
    func configureForm(isMicroCatAvailable: Bool){
        guard let category = selectedCategory, let subCats = category.subCategories, subCats.count > 0 else { return }
        
        microCat1.ownerHeightConstraint = microCat1Height
        microCat2.ownerHeightConstraint = microCat2Height
        microCat2.isOtherNeeded = true
        if let microCategories = self.microCategories, isMicroCatAvailable{
            microCat1.hide(true)
            microCat1.textField.tag = 1001
            microCat2.hide(false)
            microCat2.textDelegate = self
            microCat2.textField.tag = 1001
            microCat1.textField.isEnabled = false
            microCat2.hookDropdown(placeHolder: "Subcategory *", dataSource: microCategories.map({ (microCategory) -> String in
                if let name = microCategory.name{
                    return name.replacingOccurrences(of: " © ", with: "~")
                }
                return ""
            }), selectionCompletion: {[weak self] (index, item) in
                guard let strongSelf = self else { return }
                strongSelf.microCat1.hide(false)
                strongSelf.microCat2.textDelegate = self
                let microCatComponents = item.components(separatedBy: "~")
                if let microCatPart1 = microCatComponents.first{
                    strongSelf.microCat1.textField.text = microCatPart1
                }
                if microCatComponents.count > 1 {
                    let microCatPart2 = microCatComponents[1]
                    strongSelf.microCat2.textField.text = microCatPart2
                }
            })
        }else{
            microCat1.hide(true)
            microCat1.hookDropdown(placeHolder: "", dataSource: nil, selectionCompletion: nil)
            microCat2.hookDropdown(placeHolder: "", dataSource: nil, selectionCompletion: nil)
            microCat2.hide(true)
            
        }
        name.placeholder = "Name (Individual or Company) *"
        name.isMandatory = true
        name.textField.delegate = self
        contact.placeholder = "Contact number"
        contact.textField.delegate = self
        details.layer.cornerRadius = 4
        details.layer.borderColor = Theme.blue.cgColor
        details.layer.borderWidth = 0.9
        details.delegate = self
        details.contentInset = UIEdgeInsets.init(top: 5, left: 8, bottom: 5, right: 8)
        details.titleFont = Theme.avenirTitle!
        location.placeholder = "Location (Mumbai only) *"
        location.isMandatory = true
        location.textField.delegate = self
        
    }
}


extension AddSuggestionViewController : UITextFieldDelegate, DropDownViewTextDelegate, UITextViewDelegate{
    func dropDownSearchPrefix(_ textField : UITextField) -> String {
        if textField.tag == 1001 {
            return microCat1.textField.text ?? ""
        }
        return ""
    }
    
    func dropDownTextFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 251, 0)
        if textField.tag == 1001 {
            scrollView.scrollToView(view: contact, animated: true)
        }
    }
    
    func dropDownTextFieldDidEndEditing(_ textField: UITextField) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 251, 0)
        if textField == location.textField{
            setDropDownForSelectedTextField()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let query = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        
        if query.trimmingCharacters(in: .whitespaces) != ""{
            locationInteractor.fetchLocationFromQuery(query) { [weak self] (locations) in
                guard let strongSelf = self else{ return }
                strongSelf.locations = locations
            }
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        var tag = textField.tag
        tag += 1
        
        if tag < 7 {
            if let view = view.viewWithTag(tag) as? UITextField {
                view.becomeFirstResponder()
            }
        } else if tag == 7 {
            if let view = view.viewWithTag(tag) as? UITextView {
                view.becomeFirstResponder()
            }
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    // TextView
    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 251, 0)
        scrollView.scrollToView(view: contact, animated: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
}

extension AddSuggestionViewController: AddLocationProtocol {
    func updateLocation(_ location: String) {
        print(location)
    }
}
extension AddSuggestionViewController {
    
    func setDropDownForSelectedTextField() {
        
        // The view to which the drop down will appear ondropDown = DropDown()
        dropDown.anchorView = location
        dropDown.shadowRadius = 1
        dropDown.shadowOpacity = 0.2
        dropDown.bottomOffset = CGPoint(x: 0, y:60)
        dropDown.dismissMode = .automatic
        dropDown.direction = .bottom
    }
    
    func updateDataSourceForDropDown() {
        
        // The list of items to display. Can be changed dynamically
        guard let locations = locations else { return }
        if location.textField.text?.trimmingCharacters(in: .whitespaces) != ""{
            dropDown.dataSource = locations.map({ (location) in
                if let name = location.locSuburb {
                    return name
                }
                return ""
            })
        }else{
            dropDown.dataSource = []
        }
        
        dropDown.selectionAction = {[weak self] (index: Int, item: String) in
            guard let strongSelf = self else{
                return
            }
            let selectedLocation = locations[index]
            strongSelf.location.textField.text = selectedLocation.locSuburb
        }
        
        dropDown.show()
    }
    
}
