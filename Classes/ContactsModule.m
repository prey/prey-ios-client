//
//  ContactsModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 20/10/2010.
//  Copyright 2010 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "ContactsModule.h"
#import "AddressBook/AddressBook.h"

@implementation ContactsModule

- (void)start
{
    // Request authorization to Address Book
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                 NSLog(@"Yes");
                //[self _addContactToAddressBook];
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
         NSLog(@"Yes");
        //[self _addContactToAddressBook];
    }
    else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
    }
    
    NSMutableArray* contactsArray = [NSMutableArray new];
    
    // open the default address book.
    ABAddressBookRef m_addressbook = ABAddressBookCreate();
    
    if (!m_addressbook)
    {
        NSLog(@"opening address book");
    }
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(m_addressbook);
    CFIndex nPeople = ABAddressBookGetPersonCount(m_addressbook);
    for (int i=0;i < nPeople;i++)
    {
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople,i);
        
        // Initialize a mutable dictionary and give it initial values.
        NSMutableDictionary *tempContactDic = [[NSMutableDictionary alloc]
                                                initWithObjects:@[@"", @"", @"", @"", @"", @"", @"", @"", @""]
                                                forKeys:@[@"firstName", @"lastName", @"mobileNumber", @"homeNumber", @"homeEmail", @"workEmail", @"address", @"zipCode", @"city"]];
        
        // Use a general Core Foundation object.
        CFTypeRef generalCFObject = ABRecordCopyValue(person, kABPersonFirstNameProperty);
        
        // Get the first name.
        if (generalCFObject) {
            [tempContactDic setObject:(__bridge NSString *)generalCFObject forKey:@"firstName"];
            CFRelease(generalCFObject);
        }
        
        // Get the last name.
        generalCFObject = ABRecordCopyValue(person, kABPersonLastNameProperty);
        if (generalCFObject) {
            [tempContactDic setObject:(__bridge NSString *)generalCFObject forKey:@"lastName"];
            CFRelease(generalCFObject);
        }
        
        // Get the phone numbers as a multi-value property.
        ABMultiValueRef phonesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (int i=0; i<ABMultiValueGetCount(phonesRef); i++) {
            CFStringRef currentPhoneLabel = ABMultiValueCopyLabelAtIndex(phonesRef, i);
            CFStringRef currentPhoneValue = ABMultiValueCopyValueAtIndex(phonesRef, i);
            
            if (CFStringCompare(currentPhoneLabel, kABPersonPhoneMobileLabel, 0) == kCFCompareEqualTo) {
                [tempContactDic setObject:(__bridge NSString *)currentPhoneValue forKey:@"mobileNumber"];
            }
            
            if (CFStringCompare(currentPhoneLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
                [tempContactDic setObject:(__bridge NSString *)currentPhoneValue forKey:@"homeNumber"];
            }
            
            CFRelease(currentPhoneLabel);
            CFRelease(currentPhoneValue);
        }
        CFRelease(phonesRef);
        
        
        // Get the e-mail addresses as a multi-value property.
        ABMultiValueRef emailsRef = ABRecordCopyValue(person, kABPersonEmailProperty);
        for (int i=0; i<ABMultiValueGetCount(emailsRef); i++) {
            CFStringRef currentEmailLabel = ABMultiValueCopyLabelAtIndex(emailsRef, i);
            CFStringRef currentEmailValue = ABMultiValueCopyValueAtIndex(emailsRef, i);
            
            if (CFStringCompare(currentEmailLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
                [tempContactDic setObject:(__bridge NSString *)currentEmailValue forKey:@"homeEmail"];
            }
            
            if (CFStringCompare(currentEmailLabel, kABWorkLabel, 0) == kCFCompareEqualTo) {
                [tempContactDic setObject:(__bridge NSString *)currentEmailValue forKey:@"workEmail"];
            }
            
            CFRelease(currentEmailLabel);
            CFRelease(currentEmailValue);
        }
        CFRelease(emailsRef);
        
        
        // Get the first street address among all addresses of the selected contact.
        ABMultiValueRef addressRef = ABRecordCopyValue(person, kABPersonAddressProperty);
        if (ABMultiValueGetCount(addressRef) > 0) {
            NSDictionary *addressDict = (__bridge NSDictionary *)ABMultiValueCopyValueAtIndex(addressRef, 0);
            
            [tempContactDic setObject:[addressDict objectForKey:(NSString *)kABPersonAddressStreetKey] forKey:@"address"];
            [tempContactDic setObject:[addressDict objectForKey:(NSString *)kABPersonAddressZIPKey] forKey:@"zipCode"];
            [tempContactDic setObject:[addressDict objectForKey:(NSString *)kABPersonAddressCityKey] forKey:@"city"];
        }
        CFRelease(addressRef);
        
        
        // If the contact has an image then get it too.
        if (ABPersonHasImageData(person)) {
            NSData *contactImageData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
            
            [tempContactDic setObject:contactImageData forKey:@"image"];
        }
        
        
        [contactsArray addObject:tempContactDic];
    }
    
    NSLog(@"Contacts:%@",[contactsArray description]);
}

- (NSString *) getName {
	return @"contacts_backup";
}


@end