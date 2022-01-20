//
//  SettingsVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Prey, Inc. All rights reserved.
//

import UIKit
import WebKit
import LocalAuthentication

// Settings TableView Items
enum PreferencesViewSection : String {
    case information, settings, about, darkmode, numberSections
}

// SectionInformation Items
enum SectionInformation : Int {
    case currentLocation=0, upgradeToPro, numberSectionInformation
}

// SectionSettings Items
enum SectionSettings : Int {
    case detachDevice=0, camouflageMode, touchIdEnabled, numberSectionSettings
}

// SectionDarkMode Items
enum SectionDarkMode : Int {
    case darkMode=0, systemMode, numberSectionDarkMode
}

// SectionAbout Items
enum SectionAbout : Int {
    case version=0, help, termService, privacyPolice, numberSectionAbout
}

class SettingsVC: UIViewController, UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource, WKUIDelegate, WKNavigationDelegate {

    
    // MARK: Properties

    var currentCamouflageMode       = PreyConfig.sharedInstance.isCamouflageMode
    var viewSection                 = [String:Int]()
    
    let kTagDarkMode    = 123
    let kTagSystemMode  = 567
    
    // Color Text
    var colorTxtLbl          = UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: 1.0)
    var colorDetailLbl       = UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: 0.3)
        
    var actInd                      : UIActivityIndicatorView!
    var detachModule                : Detach!
    
    @IBOutlet var tableView    : UITableView!
    @IBOutlet var iPadView     : UIView!
    
    // MARK: Init
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if #available(iOS 13.0, *) {
            if PreyConfig.sharedInstance.isSystemDarkMode {
                return
            }
            self.overrideUserInterfaceStyle = PreyConfig.sharedInstance.isDarkMode ? .dark : .light
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            viewSection = [
                PreferencesViewSection.information.rawValue     : 0,
                PreferencesViewSection.settings.rawValue        : 1,
                PreferencesViewSection.darkmode.rawValue        : 2,
                PreferencesViewSection.about.rawValue           : 3,
                PreferencesViewSection.numberSections.rawValue  : 4]
        } else {
            viewSection = [
                PreferencesViewSection.information.rawValue     : 0,
                PreferencesViewSection.settings.rawValue        : 1,
                PreferencesViewSection.about.rawValue           : 2,
                PreferencesViewSection.numberSections.rawValue  : 3]
        }
        
        // View title for GAnalytics
        //self.screenName = "Preferences"
        
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

        tableView.backgroundColor = getTableBackgroundColor()
        tableView.separatorColor  = getTableSeparatorColor()
        colorTxtLbl = getTextLblColor(1.0)
        colorDetailLbl = getTextLblColor(0.3)
        
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
        return viewSection[PreferencesViewSection.numberSections.rawValue]!
    }
    
    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numberRows = 0
        
        switch section {
            
            // Information
        case viewSection[PreferencesViewSection.information.rawValue] :
            
            numberRows = SectionInformation.numberSectionInformation.rawValue
            if PreyConfig.sharedInstance.isPro {
                numberRows -= 1
            }
            
            // Settings
        case viewSection[PreferencesViewSection.settings.rawValue] :
            if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                numberRows = SectionSettings.numberSectionSettings.rawValue
            } else {
                numberRows = SectionSettings.numberSectionSettings.rawValue - 1
            }

            // Dark Mode
        case viewSection[PreferencesViewSection.darkmode.rawValue] :
            numberRows = SectionDarkMode.numberSectionDarkMode.rawValue

            // About
        case viewSection[PreferencesViewSection.about.rawValue] :
            numberRows = SectionAbout.numberSectionAbout.rawValue
            
        default : break
        }
        
        return numberRows
    }
    
    // Title for Header in Section
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var titleSection = ""
        
        switch section {
        case viewSection[PreferencesViewSection.information.rawValue] :
            titleSection = "Information".localized
            
        case viewSection[PreferencesViewSection.settings.rawValue] :
            titleSection = "Settings".localized

        case viewSection[PreferencesViewSection.darkmode.rawValue] :
            titleSection = "Dark Mode".localized
            
        case viewSection[PreferencesViewSection.about.rawValue] :
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
        
        let sizeFont:CGFloat            = (IS_IPAD) ? 16 : 14
        cell                            = UITableViewCell(style:UITableViewCell.CellStyle.value1, reuseIdentifier:cellIdentifier)
        cell.selectionStyle             = UITableViewCell.SelectionStyle.none
        cell.backgroundColor            = getTableCellColor()
        cell.textLabel?.font            = UIFont(name:fontTitilliumRegular, size:sizeFont)
        cell.detailTextLabel?.font      = UIFont(name:fontTitilliumRegular, size:sizeFont)
        cell.textLabel?.textColor       = colorTxtLbl
        cell.detailTextLabel?.textColor = colorDetailLbl

        // Set cell info
        switch (indexPath as NSIndexPath).section {

        case viewSection[PreferencesViewSection.information.rawValue] :
            configCellForInformationSection((indexPath as NSIndexPath).row, withCell:cell)
            
        case viewSection[PreferencesViewSection.settings.rawValue] :
            configCellForSettingsSection((indexPath as NSIndexPath).row, withCell:cell)

        case viewSection[PreferencesViewSection.darkmode.rawValue] :
            configCellForDarkModeSection((indexPath as NSIndexPath).row, withCell:cell)
            
        case viewSection[PreferencesViewSection.about.rawValue] :
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
            
        case SectionInformation.currentLocation.rawValue :
            cell.textLabel?.text    = "Current Location".localized
            
        case SectionInformation.upgradeToPro.rawValue :
            cell.textLabel?.text    = "Upgrade to Pro".localized
            
        default : break
        }
    }
    
    // Config SettingsSection
    func configCellForSettingsSection(_ index:Int, withCell cell:UITableViewCell) {
        
        switch index {
            
        case SectionSettings.detachDevice.rawValue :
            cell.accessoryType      = UITableViewCell.AccessoryType.none
            cell.selectionStyle     = UITableViewCell.SelectionStyle.blue
            cell.accessoryView      = nil
            cell.textLabel?.text    = "Detach device".localized
            
        case SectionSettings.camouflageMode.rawValue :
            let camouflageMode      = UISwitch()
            camouflageMode.addTarget(self, action:#selector(camouflageModeState), for:UIControl.Event.valueChanged)
            camouflageMode.setOn(PreyConfig.sharedInstance.isCamouflageMode, animated:false)
            cell.accessoryView      = camouflageMode
            cell.textLabel?.text    = "Camouflage mode".localized

        case SectionSettings.touchIdEnabled.rawValue :
            let touchIDEnabled      = UISwitch()
            touchIDEnabled.addTarget(self, action:#selector(touchIDEnabledState), for:UIControl.Event.valueChanged)
            touchIDEnabled.setOn(PreyConfig.sharedInstance.isTouchIDEnabled, animated:false)
            cell.accessoryView      = touchIDEnabled
            cell.textLabel?.text    = "Use " + biometricAuth
            
        default : break
        }
    }
    
    // Config DarkModeSection
    func configCellForDarkModeSection(_ index:Int, withCell cell:UITableViewCell) {
        
        switch index {
            
        case SectionDarkMode.darkMode.rawValue :
            let darkMode      = UISwitch()
            darkMode.addTarget(self, action:#selector(darkModeState), for:UIControl.Event.valueChanged)
            darkMode.setOn(PreyConfig.sharedInstance.isDarkMode, animated:false)
            darkMode.tag            = kTagDarkMode
            cell.accessoryView      = darkMode
            cell.textLabel?.text    = "Dark mode".localized

        case SectionDarkMode.systemMode.rawValue :
            let systemDarkMode      = UISwitch()
            systemDarkMode.addTarget(self, action:#selector(systemDarkModeState), for:UIControl.Event.valueChanged)
            systemDarkMode.setOn(PreyConfig.sharedInstance.isSystemDarkMode, animated:false)
            systemDarkMode.tag      = kTagSystemMode
            cell.accessoryView      = systemDarkMode
            cell.textLabel?.text    = "Use device settings".localized
            
        default : break
        }
    }
    
    // Config AboutSection
    func configCellForAboutSection(_ index:Int, withCell cell:UITableViewCell) {
        
        cell.accessoryType          = UITableViewCell.AccessoryType.disclosureIndicator
        cell.selectionStyle         = UITableViewCell.SelectionStyle.blue
        cell.detailTextLabel?.text  = ""
        
        switch index {
            
        case SectionAbout.version.rawValue :
            cell.accessoryType          = UITableViewCell.AccessoryType.none
            cell.selectionStyle         = UITableViewCell.SelectionStyle.none
            cell.detailTextLabel?.text  = appVersion
            cell.textLabel?.text        = "Version".localized

        case SectionAbout.help.rawValue :
            cell.textLabel?.text        = "Help".localized
            
        case SectionAbout.termService.rawValue :
            cell.textLabel?.text        = "Terms of Service".localized

        case SectionAbout.privacyPolice.rawValue :
            cell.textLabel?.text        = "Privacy Policy".localized
            
        default : break
        }
    }
    
    
    // MARK: UITableViewDelegate
    
    // Height for header
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == viewSection[PreferencesViewSection.information.rawValue] ? 1 : 35
    }
    
    // Height for footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
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
        case viewSection[PreferencesViewSection.information.rawValue] :
            
            switch (indexPath as NSIndexPath).row {
                
                // Current Location
            case SectionInformation.currentLocation.rawValue:
                showViewControllerWithId(StoryboardIdVC.currentLocation.rawValue)
                
                // Upgrade to Pro
            case SectionInformation.upgradeToPro.rawValue:
                showViewControllerWithId(StoryboardIdVC.purchases.rawValue)
                
            default : break
            }

        // === SETTINGS ===
        case viewSection[PreferencesViewSection.settings.rawValue] :

            // Detach Device
            if (indexPath as NSIndexPath).row == SectionSettings.detachDevice.rawValue {
                showDetachDeviceAction()
            }
            
        // === ABOUT ===
        case viewSection[PreferencesViewSection.about.rawValue] :
            
            switch (indexPath as NSIndexPath).row {
            
                // Help
            case SectionAbout.help.rawValue :
                showWebController(URLHelpPrey, withTitle:"Help".localized)
                
                // Term of Service
            case SectionAbout.termService.rawValue :
                showWebController(URLTermsPrey, withTitle:"Terms of Service".localized)
                
                // Privacy Policy
            case SectionAbout.privacyPolice.rawValue :
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
            DispatchQueue.main.async {
                let webView             = UIWebView(frame:CGRect.zero)
                webView.scalesPageToFit = true
                webView.delegate        = self
                webView.loadRequest(request)
                
                controller.view         = webView
            }
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

    // TouchID State
    @objc func touchIDEnabledState(_ object:UISwitch) {
        PreyConfig.sharedInstance.isTouchIDEnabled = object.isOn
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
        
        if (parent == nil), PreyConfig.sharedInstance.isRegistered {
            guard let appWindow = UIApplication.shared.delegate?.window else {
                PreyLogger("error with sharedApplication")
                return
            }
            let navigationController:UINavigationController = appWindow!.rootViewController as! UINavigationController
            if let homeWebVC:HomeWebVC = navigationController.topViewController as? HomeWebVC {
                homeWebVC.loadViewOnWebView("index")
                homeWebVC.webView.reload()
            }
        }
    }
    
    // DarkMode State
    @objc func darkModeState(_ object:UISwitch) {

        if let switchSystemMode = self.view.viewWithTag(kTagSystemMode) as? UISwitch {
            switchSystemMode.setOn(false, animated: true)
            PreyConfig.sharedInstance.isSystemDarkMode = false
        }
        
        PreyConfig.sharedInstance.isDarkMode = object.isOn
        PreyConfig.sharedInstance.saveValues()
        
        reloadViewController()
    }

    // SystemDarkMode State
    @objc func systemDarkModeState(_ object:UISwitch) {

        if let switchDarkMode = self.view.viewWithTag(kTagDarkMode) as? UISwitch {
            switchDarkMode.setOn(false, animated: true)
            PreyConfig.sharedInstance.isDarkMode = false
        }

        PreyConfig.sharedInstance.isSystemDarkMode = object.isOn
        PreyConfig.sharedInstance.saveValues()
        
        reloadViewController()
    }

    // Reload tableView
    func reloadViewController() {
        tableView.backgroundColor = getTableBackgroundColor()
        tableView.separatorColor  = getTableSeparatorColor()
        colorTxtLbl = getTextLblColor(1.0)
        colorDetailLbl = getTextLblColor(0.3)
        tableView.reloadData()
        PreyConfig.sharedInstance.configNavigationBar()
        configNavigationBar()
    }
    
    // Config UINavigationBar
    func configNavigationBar() {
        let navBar               = self.navigationController!.navigationBar
        let colorTitle           = PreyConfig.sharedInstance.getNavBarTitleColor()
        let colorItem            = PreyConfig.sharedInstance.getNavBarItemColor()
        
        let itemFontSize:CGFloat    = IS_IPAD ? 18 : 12
        let titleFontSize:CGFloat   = IS_IPAD ? 20 : 13
        
        let fontItem                = UIFont(name:fontTitilliumBold, size:itemFontSize)
        let fontTitle               = UIFont(name:fontTitilliumRegular, size:titleFontSize)
        
        navBar.titleTextAttributes    = [NSAttributedString.Key.font:fontTitle!,NSAttributedString.Key.foregroundColor:colorTitle]
    UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font:fontItem!,NSAttributedString.Key.foregroundColor:colorItem],for:.normal)
        
        navBar.barTintColor           = PreyConfig.sharedInstance.getNavBarTintColor()
        navBar.tintColor              = colorItem
    }
    
    // MARK: Dark Mode colors

    func getTableBackgroundColor() -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor.white
        }
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return UIColor(named: "TableBackground")!
        }
        return PreyConfig.sharedInstance.isDarkMode ? UIColor(red: 40/255, green: 54/255, blue: 74/255, alpha: 1.0) : UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1.0)
    }

    func getTableSeparatorColor() -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor.white
        }
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return UIColor(named: "TableSeparator")!
        }
        return PreyConfig.sharedInstance.isDarkMode ? UIColor(red: 40/255, green: 54/255, blue: 74/255, alpha: 1.0) : UIColor.white
    }

    func getTextLblColor(_ alpha: CGFloat) -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: alpha)
        }
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return alpha == 1.0 ? UIColor(named: "TxtLbl")! : UIColor(named: "DetailLbl")!
        }
        return PreyConfig.sharedInstance.isDarkMode ? UIColor(red: 214/255, green: 231/255, blue: 255/255, alpha: alpha) : UIColor(red: 35/255, green: 68/255, blue: 87/255, alpha: alpha)
    }

    func getTableCellColor() -> UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor.white
        }
        if PreyConfig.sharedInstance.isSystemDarkMode {
            return UIColor(named: "TableCell")!
        }
        return PreyConfig.sharedInstance.isDarkMode ? UIColor(red: 40/255, green: 54/255, blue: 74/255, alpha: 1.0) : UIColor.white
    }
    
    
    
    // MARK: WKUIDelegate, WKNavigationDelegate
    
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

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        PreyLogger("Should load request WKWebView")
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PreyLogger("Finish load WKWebView")
        
        // Hide ActivityIndicator
        DispatchQueue.main.async { self.actInd.stopAnimating() }
    }

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
