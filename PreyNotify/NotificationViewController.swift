//
//  NotificationViewController.swift
//  PreyNotify
//
//  Created by Javier Cala Uribe on 12/8/19.
//  Copyright © 2019 Prey, Inc. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    @IBOutlet var alertTitle: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
        self.preferredContentSize = CGSize(width: self.view.frame.width, height: 200.0)
    }

    func didReceive(_ notification: UNNotification) {
        // Handle the modified content received from the service extension
        let modifiedContent = notification.request.content

        // self.label?.text = notification.request.content.body
        
        // solo para probar, acá le pasamos el content nuevo desde la clase NotificationService
        self.label?.text = modifiedContent.body
        self.alertTitle?.text = "IMPORTANT ALERT".localized
    }
}
