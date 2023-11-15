//
//  UNNotificationServiceExtension.swift
//  PreyNotify
//
//  Created by Pato Jofre on 15-11-23.
//  Copyright © 2023 Prey, Inc. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        // Process the notification content here

        // Create a mutable copy of the original content
        let updatedContent = (request.content.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()

        // Modify the content (example: update the title)
        updatedContent.title = "New Title: \(request.content.title)"
        
        // acá invocar el location 

        // Call the contentHandler with the updated content
        contentHandler(updatedContent)
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // You may use this method to deliver a truncated version of the notification.
    }
}
