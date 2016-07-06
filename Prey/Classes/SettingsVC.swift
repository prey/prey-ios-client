//
//  SettingsVC.swift
//  Prey
//
//  Created by Javier Cala Uribe on 27/11/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit

// Settings TableView Items
enum PreferencesViewSection {
    case Information, Settings, About, NumberPreferencesViewSection
}

// SectionInformation Items
enum SectionInformation {
    case CurrentLocation, Geofence, UpgradeToPro, NumberSectionInformation
}

// SectionSettings Items
enum SectionSettings {
    case CamouflageMode, DetachDevice, NumberSectionSettings
}

// SectionAbout Items
enum SectionAbout {
    case Version, Help, TermService, PrivacyPolice, NumberSectionAbout
}

class SettingsVC: UIViewController, UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource {

    
    // MARK: Properties

    // Color Text
    let colorTxtLbl          = UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: 1.0)
    let colorDetailLbl       = UIColor(red: 72/255, green: 84/255, blue: 102/255, alpha: 0.3)
    
    // Font 
    let fontTitilliumBold    =  "TitilliumWeb-Bold"
    let fontTitilliumRegular =  "TitilliumWeb-Regular"
    
    var actInd                      : UIActivityIndicatorView!
    
    @IBOutlet weak var tableView    : UITableView!
    
    
    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.whiteColor()
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigationBar when appear this ViewController
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    // MARK: UITableViewDataSource
    
    // Number of sections
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return PreferencesViewSection.NumberPreferencesViewSection.hashValue
    }
    
    // Number of rows in section
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numberRows = 0
        
        switch section {
            
            // Information
        case PreferencesViewSection.Information.hashValue :
            
            numberRows = SectionInformation.NumberSectionInformation.hashValue
            if PreyConfig.sharedInstance.isPro {
                numberRows -= 1
            }
            
            // Settings
        case PreferencesViewSection.Settings.hashValue :
            numberRows = SectionSettings.NumberSectionSettings.hashValue
            
            // About
        case PreferencesViewSection.About.hashValue :
            numberRows = SectionAbout.NumberSectionAbout.hashValue
            
        default : break
        }
        
        return numberRows
    }
    
    // Title for Header in Section
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var titleSection = ""
        
        switch section {
        case PreferencesViewSection.Information.hashValue :
            titleSection = "Information".localized
            
        case PreferencesViewSection.Settings.hashValue :
            titleSection = "Settings".localized
            
        case PreferencesViewSection.About.hashValue :
            titleSection = "About".localized
            
        default: break
        }
        
        return titleSection
    }
    
    // Cell for row
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Config cell
        var cell :UITableViewCell!
        let cellIdentifier  = "Cell"
        cell                = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        if cell == nil  {
            let sizeFont:CGFloat            = (IS_IPAD) ? 16 : 14
            cell                            = UITableViewCell(style:UITableViewCellStyle.Value1, reuseIdentifier:cellIdentifier)
            cell.selectionStyle             = UITableViewCellSelectionStyle.None
            cell.backgroundColor            = UIColor.whiteColor()
            cell.textLabel?.font            = UIFont(name:fontTitilliumRegular, size:sizeFont)
            cell.detailTextLabel?.font      = UIFont(name:fontTitilliumRegular, size:sizeFont)
            cell.textLabel?.textColor       = colorTxtLbl
            cell.detailTextLabel?.textColor = colorDetailLbl
        }
        
        // Set cell info
        switch indexPath.section {

        case PreferencesViewSection.Information.hashValue :
            configCellForInformationSection(indexPath.row, withCell:cell)
            
        case PreferencesViewSection.Settings.hashValue :
            configCellForSettingsSection(indexPath.row, withCell:cell)
            
        case PreferencesViewSection.About.hashValue :
            configCellForAboutSection(indexPath.row, withCell:cell)
            
        default : break
        }
        
        return cell
    }
    
    // Config InformationSection
    func configCellForInformationSection(index:Int, withCell cell:UITableViewCell) {

        cell.selectionStyle = UITableViewCellSelectionStyle.Blue
        cell.accessoryType  = UITableViewCellAccessoryType.DisclosureIndicator
        
        switch index {
            
        case SectionInformation.CurrentLocation.hashValue :
            cell.textLabel?.text    = "Current Location".localized
            
        case SectionInformation.Geofence.hashValue :
            cell.textLabel?.text    = "Your Geofences".localized
            
        case SectionInformation.UpgradeToPro.hashValue :
            cell.textLabel?.text    = "Upgrade to Pro".localized
            
        default : break
        }
    }
    
    // Config SettingsSection
    func configCellForSettingsSection(index:Int, withCell cell:UITableViewCell) {
        
        switch index {
            
        case SectionSettings.CamouflageMode.hashValue :
            let camouflageMode      = UISwitch()
            camouflageMode.addTarget(self, action:#selector(camouflageModeState), forControlEvents:UIControlEvents.ValueChanged)
            camouflageMode.setOn(PreyConfig.sharedInstance.isCamouflageMode, animated:false)
            cell.accessoryView      = camouflageMode
            cell.textLabel?.text    = "Camouflage mode".localized
            
        case SectionSettings.DetachDevice.hashValue :
            cell.accessoryType      = UITableViewCellAccessoryType.None
            cell.selectionStyle     = UITableViewCellSelectionStyle.Blue
            cell.accessoryView      = nil
            cell.textLabel?.text    = "Detach device".localized
            
        default : break
        }
    }
    
    // Config AboutSection
    func configCellForAboutSection(index:Int, withCell cell:UITableViewCell) {
        
        cell.accessoryType          = UITableViewCellAccessoryType.DisclosureIndicator
        cell.selectionStyle         = UITableViewCellSelectionStyle.Blue

        switch index {
            
        case SectionAbout.Version.hashValue :
            cell.accessoryType          = UITableViewCellAccessoryType.None
            cell.selectionStyle         = UITableViewCellSelectionStyle.None
            cell.detailTextLabel?.text  = appVersion
            cell.textLabel?.text        = "Version".localized

        case SectionAbout.Help.hashValue :
            cell.textLabel?.text        = "Help".localized
            
        case SectionAbout.TermService.hashValue :
            cell.textLabel?.text        = "Terms of Service".localized

        case SectionAbout.PrivacyPolice.hashValue :
            cell.textLabel?.text        = "Privacy Policy".localized
            
        default : break
        }
    }
    
    
    // MARK: UITableViewDelegate
    
    // Height for header
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == PreferencesViewSection.About.hashValue ? 35 : 1
    }
    
    // Height for footer
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == PreferencesViewSection.Information.hashValue ? 35 : 1
    }
    
    // DisplayHeaderView
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header                  = view as! UITableViewHeaderFooterView
        let sizeFont:CGFloat        = (IS_IPAD) ? 14 : 12
        header.textLabel?.font      = UIFont(name:fontTitilliumBold, size:sizeFont)
        header.textLabel?.textColor = colorDetailLbl
    }
    
    // Row selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Set cell info
        switch indexPath.section {
            
        // === INFORMATION ===
        case PreferencesViewSection.Information.hashValue :
            
            switch indexPath.row {
                
                // Current Location
            case SectionInformation.CurrentLocation.hashValue:
                showLocationMapVC()
                
                // Geofence
            case SectionInformation.Geofence.hashValue:
                showGeofenceMapVC()
                
                // Upgrade to Pro
            case SectionInformation.UpgradeToPro.hashValue:
                showUpgradeToProVC()
                
            default : break
            }

        // === SETTINGS ===
        case PreferencesViewSection.Settings.hashValue :

            // Detach Device
            if indexPath.row == SectionSettings.DetachDevice.hashValue {
                showDetachDeviceAction()
            }
            
        // === ABOUT ===
        case PreferencesViewSection.About.hashValue :
            
            switch indexPath.row {
            
                // Help
            case SectionAbout.Help.hashValue :
                showWebController(URLHelpPrey, withTitle:"Help".localized)
                
                // Term of Service
            case SectionAbout.TermService.hashValue :
                showWebController(URLTermsPrey, withTitle:"Terms of Service".localized)
                
                // Privacy Policy
            case SectionAbout.PrivacyPolice.hashValue :
                showWebController(URLPrivacyPrey, withTitle:"Privacy Policy".localized)
                
            default : break
            }
            
        default : break
        }
    }
    
    
    // MARK: Methods
    
    // LocationMapVC
    func showLocationMapVC() {
        
    }
    
    // GeofenceMapVC
    func showGeofenceMapVC() {
        
    }
    
    // UpgradeToProVC
    func showUpgradeToProVC() {
        
    }
    
    // DetachDeviceAction
    func showDetachDeviceAction() {
        
    }
    
    // WebController
    func showWebController(url:String, withTitle title:String) {
        
        let controller          = UIViewController()
        let webView             = UIWebView(frame:CGRectZero)
        let request             = NSURLRequest(URL:NSURL(string:url)!)
        
        controller.view         = webView
        controller.title        = title
        
        webView.scalesPageToFit = true
        webView.delegate        = self
        webView.loadRequest(request)
        
        self.navigationController?.pushViewController(controller, animated:true)        
    }
    
    // CamouflageMode State
    func camouflageModeState(object:UISwitch) {
        PreyConfig.sharedInstance.isCamouflageMode = object.on
        PreyConfig.sharedInstance.saveValues()
    }
    
    // MARK: UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView) {
        print("Start load web")
        
        // Show ActivityIndicator
        if actInd == nil {
            actInd          = UIActivityIndicatorView(initInView: self.view, withText:"Please wait".localized)
            webView.addSubview(actInd)
            actInd.startAnimating()
        }
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        print("Should load request")
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print("Finish load web")
        
        // Hide ActivityIndicator
        actInd.stopAnimating()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("Error loading web")
        
        // Hide ActivityIndicator
        actInd.stopAnimating()
        
        displayErrorAlert("Error loading web, please try again.".localized,
                          titleMessage:"We have a situation!".localized)
    }
}
