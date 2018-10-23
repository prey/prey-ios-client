//
//  SettingsVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit
import WebKit

// Settings TableView Items
enum PreferencesViewSection {
    case information, settings, about, numberPreferencesViewSection
}

// SectionInformation Items
enum SectionInformation {
    case currentLocation, upgradeToPro, numberSectionInformation
}

// SectionSettings Items
enum SectionSettings {
    case camouflageMode, detachDevice, numberSectionSettings
}

// SectionAbout Items
enum SectionAbout {
    case version, help, termService, privacyPolice, numberSectionAbout
}

class SettingsVC: GAITrackedViewController, UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource, WKUIDelegate, WKNavigationDelegate {

    
    // MARK: Properties

    var currentCamouflageMode       = PreyConfig.sharedInstance.isCamouflageMode
    
    // Color Text
    let colorTxtLbl          = UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: 1.0)
    let colorDetailLbl       = UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: 0.3)
        
    var actInd                      : UIActivityIndicatorView!
    var detachModule                : Detach!
    
    @IBOutlet var tableView    : UITableView!
    @IBOutlet var iPadView     : UIView!
    
    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title for GAnalytics
        self.screenName = "Preferences"
        
        // Set title
        self.title = UIDevice.current.name
        
        // Set iPadView
        if IS_IPAD {
            showViewControllerWithId(StoryboardIdVC.currentLocation.rawValue)
        }
        
        // Set camouflageModeState
        currentCamouflageMode       = PreyConfig.sharedInstance.isCamouflageMode
        
        // Init PreyStoreManager
        if !PreyConfig.sharedInstance.isPro {
            PreyStoreManager.sharedInstance.requestProductData()
        }
        
        tableView.backgroundColor = UIColor.white
        tableView.separatorColor  = UIColor.white
        if #available(iOS 11.0, *) {
            tableView.contentInset = UIEdgeInsets.init(top: 35.0, left: 0.0, bottom: 0.0, right: 0.0);
        }
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigationBar when appear this ViewController
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    // MARK: UITableViewDataSource
    
    // Number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return PreferencesViewSection.numberPreferencesViewSection.hashValue
    }
    
    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numberRows = 0
        
        switch section {
            
            // Information
        case PreferencesViewSection.information.hashValue :
            
            numberRows = SectionInformation.numberSectionInformation.hashValue
            if PreyConfig.sharedInstance.isPro {
                numberRows -= 1
            }
            
            // Settings
        case PreferencesViewSection.settings.hashValue :
            numberRows = SectionSettings.numberSectionSettings.hashValue
            
            // About
        case PreferencesViewSection.about.hashValue :
            numberRows = SectionAbout.numberSectionAbout.hashValue
            
        default : break
        }
        
        return numberRows
    }
    
    // Title for Header in Section
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var titleSection = ""
        
        switch section {
        case PreferencesViewSection.information.hashValue :
            titleSection = "Information".localized
            
        case PreferencesViewSection.settings.hashValue :
            titleSection = "Settings".localized
            
        case PreferencesViewSection.about.hashValue :
            titleSection = "About".localized
            
        default: break
        }
        
        return titleSection
    }
    
    // Cell for row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Config cell
        var cell :UITableViewCell!
        let cellIdentifier  = "Cell"
        cell                = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil  {
            let sizeFont:CGFloat            = (IS_IPAD) ? 16 : 14
            cell                            = UITableViewCell(style:UITableViewCell.CellStyle.value1, reuseIdentifier:cellIdentifier)
            cell.selectionStyle             = UITableViewCell.SelectionStyle.none
            cell.backgroundColor            = UIColor.white
            cell.textLabel?.font            = UIFont(name:fontTitilliumRegular, size:sizeFont)
            cell.detailTextLabel?.font      = UIFont(name:fontTitilliumRegular, size:sizeFont)
            cell.textLabel?.textColor       = colorTxtLbl
            cell.detailTextLabel?.textColor = colorDetailLbl
        }
        
        // Set cell info
        switch (indexPath as NSIndexPath).section {

        case PreferencesViewSection.information.hashValue :
            configCellForInformationSection((indexPath as NSIndexPath).row, withCell:cell)
            
        case PreferencesViewSection.settings.hashValue :
            configCellForSettingsSection((indexPath as NSIndexPath).row, withCell:cell)
            
        case PreferencesViewSection.about.hashValue :
            configCellForAboutSection((indexPath as NSIndexPath).row, withCell:cell)
            
        default : break
        }
        
        return cell
    }
    
    // Config InformationSection
    func configCellForInformationSection(_ index:Int, withCell cell:UITableViewCell) {

        cell.selectionStyle = UITableViewCell.SelectionStyle.blue
        cell.accessoryType  = UITableViewCell.AccessoryType.disclosureIndicator
        
        switch index {
            
        case SectionInformation.currentLocation.hashValue :
            cell.textLabel?.text    = "Current Location".localized
            
        case SectionInformation.upgradeToPro.hashValue :
            cell.textLabel?.text    = "Upgrade to Pro".localized
            
        default : break
        }
    }
    
    // Config SettingsSection
    func configCellForSettingsSection(_ index:Int, withCell cell:UITableViewCell) {
        
        switch index {
            
        case SectionSettings.camouflageMode.hashValue :
            let camouflageMode      = UISwitch()
            camouflageMode.addTarget(self, action:#selector(camouflageModeState), for:UIControl.Event.valueChanged)
            camouflageMode.setOn(PreyConfig.sharedInstance.isCamouflageMode, animated:false)
            cell.accessoryView      = camouflageMode
            cell.textLabel?.text    = "Camouflage mode".localized
            
        case SectionSettings.detachDevice.hashValue :
            cell.accessoryType      = UITableViewCell.AccessoryType.none
            cell.selectionStyle     = UITableViewCell.SelectionStyle.blue
            cell.accessoryView      = nil
            cell.textLabel?.text    = "Detach device".localized
            
        default : break
        }
    }
    
    // Config AboutSection
    func configCellForAboutSection(_ index:Int, withCell cell:UITableViewCell) {
        
        cell.accessoryType          = UITableViewCell.AccessoryType.disclosureIndicator
        cell.selectionStyle         = UITableViewCell.SelectionStyle.blue
        cell.detailTextLabel?.text  = ""
        
        switch index {
            
        case SectionAbout.version.hashValue :
            cell.accessoryType          = UITableViewCell.AccessoryType.none
            cell.selectionStyle         = UITableViewCell.SelectionStyle.none
            cell.detailTextLabel?.text  = appVersion
            cell.textLabel?.text        = "Version".localized

        case SectionAbout.help.hashValue :
            cell.textLabel?.text        = "Help".localized
            
        case SectionAbout.termService.hashValue :
            cell.textLabel?.text        = "Terms of Service".localized

        case SectionAbout.privacyPolice.hashValue :
            cell.textLabel?.text        = "Privacy Policy".localized
            
        default : break
        }
    }
    
    
    // MARK: UITableViewDelegate
    
    // Height for header
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == PreferencesViewSection.about.hashValue ? 35 : 1
    }
    
    // Height for footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == PreferencesViewSection.information.hashValue ? 35 : 1
    }
    
    // DisplayHeaderView
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header                  = view as! UITableViewHeaderFooterView
        let sizeFont:CGFloat        = (IS_IPAD) ? 14 : 12
        header.textLabel?.font      = UIFont(name:fontTitilliumBold, size:sizeFont)
        header.textLabel?.textColor = colorDetailLbl
    }
    
    // Row selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Set cell info
        switch (indexPath as NSIndexPath).section {
            
        // === INFORMATION ===
        case PreferencesViewSection.information.hashValue :
            
            switch (indexPath as NSIndexPath).row {
                
                // Current Location
            case SectionInformation.currentLocation.hashValue:
                showViewControllerWithId(StoryboardIdVC.currentLocation.rawValue)
                
                // Upgrade to Pro
            case SectionInformation.upgradeToPro.hashValue:
                showViewControllerWithId(StoryboardIdVC.purchases.rawValue)
                
            default : break
            }

        // === SETTINGS ===
        case PreferencesViewSection.settings.hashValue :

            // Detach Device
            if (indexPath as NSIndexPath).row == SectionSettings.detachDevice.hashValue {
                showDetachDeviceAction()
            }
            
        // === ABOUT ===
        case PreferencesViewSection.about.hashValue :
            
            switch (indexPath as NSIndexPath).row {
            
                // Help
            case SectionAbout.help.hashValue :
                showWebController(URLHelpPrey, withTitle:"Help".localized)
                
                // Term of Service
            case SectionAbout.termService.hashValue :
                showWebController(URLTermsPrey, withTitle:"Terms of Service".localized)
                
                // Privacy Policy
            case SectionAbout.privacyPolice.hashValue :
                showWebController(URLPrivacyPrey, withTitle:"Privacy Policy".localized)
                
            default : break
            }
            
        default : break
        }
    }
    
    
    // MARK: Methods
    
    
    // Show ViewController
    func showViewControllerWithId(_ controllerId:String) {
        let controller:UIViewController = self.storyboard!.instantiateViewController(withIdentifier: controllerId)
        if IS_IPAD {
            showViewControllerOniPad(controller)
        } else {
            self.navigationController?.pushViewController(controller, animated:true)
        }
    }
    
    // Show ViewController for iPad
    func showViewControllerOniPad(_ controller:UIViewController) {

        // RemovePreviewViewController
        removePreviewViewControler()
        
        // Config container viewController
        let rect                = CGRect(x: 0, y: 0, width: iPadView.frame.width, height: iPadView.frame.height)
        controller.view.frame   = rect
        
        iPadView.addSubview(controller.view)
        
        self.addChild(controller)
        controller.didMove(toParent: self)
    }
    
    // Remove PreviewViewController
    func removePreviewViewControler() {
        if let lastVC = self.children.last {
            lastVC.willMove(toParent: nil)
            lastVC.view.removeFromSuperview()
            lastVC.removeFromParent()
        }
    }
    
    // DetachDeviceAction
    func showDetachDeviceAction() {
        detachModule = Detach(withTarget:kAction.detach, withCommand:kCommand.start, withOptions:nil)
        detachModule.showDetachDeviceAction(self.view)
    }
    
    // WebController
    func showWebController(_ url:String, withTitle title:String) {

        guard let urlString = URL(string:url) else {
            return
        }
        let controller          = UIViewController()
        var request             = URLRequest(url:urlString)
        request.timeoutInterval = timeoutIntervalRequest

        if #available(iOS 10.0, *) {
            let webConfiguration            = WKWebViewConfiguration()
            let webKitView                  = WKWebView(frame:CGRect.zero, configuration:webConfiguration)
            webKitView.uiDelegate           = self
            webKitView.navigationDelegate   = self
            webKitView.load(request)
            
            controller.view                 = webKitView
        } else {
            // For iOS 7, 8 and 9
            let webView             = UIWebView(frame:CGRect.zero)
            webView.scalesPageToFit = true
            webView.delegate        = self
            webView.loadRequest(request)
            
            controller.view         = webView
        }

        controller.title = title
        
        if IS_IPAD {
            showViewControllerOniPad(controller)
        } else {
            self.navigationController?.pushViewController(controller, animated:true)
        }
    }
    
    // CamouflageMode State
    @objc func camouflageModeState(_ object:UISwitch) {
        PreyConfig.sharedInstance.isCamouflageMode = object.isOn
        PreyConfig.sharedInstance.saveValues()
    }
    
    // Check changes on camouflageMode
    override func didMove(toParent parent: UIViewController?) {

        if (parent == nil) && (currentCamouflageMode != PreyConfig.sharedInstance.isCamouflageMode) {
            // Add camouflage action
            let command:kCommand = PreyConfig.sharedInstance.isCamouflageMode ? .start : .stop
            let alertAction:Camouflage = Camouflage(withTarget:kAction.camouflage, withCommand:command, withOptions:nil)
            PreyModule.sharedInstance.actionArray.append(alertAction)
            PreyModule.sharedInstance.runAction()
        }
    }
    
    // MARK: WKUIDelegate, WKNavigationDelegate
    
    @available(iOS 8.0, *)
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        PreyLogger("Start load WKWebView")
        
        DispatchQueue.main.async {
            // Show ActivityIndicator
            if self.actInd == nil {
                self.actInd          = UIActivityIndicatorView(initInView: webView, withText:"Please wait".localized)
                webView.addSubview(self.actInd)
                self.actInd.startAnimating()
            }
        }
    }
    @available(iOS 8.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        PreyLogger("Should load request WKWebView")
        decisionHandler(.allow)
    }
    @available(iOS 8.0, *)
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PreyLogger("Finish load WKWebView")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
    }
    @available(iOS 8.0, *)
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PreyLogger("Error loading WKWebView")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }

    
    // MARK: UIWebViewDelegate
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        PreyLogger("Start load web")
        
        DispatchQueue.main.async {
            // Show ActivityIndicator
            if self.actInd == nil {
                self.actInd          = UIActivityIndicatorView(initInView: webView, withText:"Please wait".localized)
                webView.addSubview(self.actInd)
                self.actInd.startAnimating()
            }
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        PreyLogger("Should load request")
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        PreyLogger("Finish load web")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        PreyLogger("Error loading web")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
        
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}
