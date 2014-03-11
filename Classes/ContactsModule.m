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


-(void)collectContacts
{
    NSMutableDictionary *myAddressBook = [[NSMutableDictionary alloc] init];
    ABAddressBookRef addressBook = ABAddressBookCreate();
    CFArrayRef people  = ABAddressBookCopyArrayOfAllPeople(addressBook);
    for(int i = 0;i<ABAddressBookGetPersonCount(addressBook);i++)
    {
        ABRecordRef ref = CFArrayGetValueAtIndex(people, i);
        
        // Get First name, Last name, Prefix, Suffix, Job title
        NSString *firstName = (NSString *)ABRecordCopyValue(ref,kABPersonFirstNameProperty);
        NSString *lastName = (NSString *)ABRecordCopyValue(ref,kABPersonLastNameProperty);
        NSString *prefix = (NSString *)ABRecordCopyValue(ref,kABPersonPrefixProperty);
        NSString *suffix = (NSString *)ABRecordCopyValue(ref,kABPersonSuffixProperty);
        NSString *jobTitle = (NSString *)ABRecordCopyValue(ref,kABPersonJobTitleProperty);
        
        [myAddressBook setObject:firstName forKey:@"firstName"];
        [myAddressBook setObject:lastName forKey:@"lastName"];
        [myAddressBook setObject:prefix forKey:@"prefix"];
        [myAddressBook setObject:suffix forKey:@"suffix"];
        [myAddressBook setObject:jobTitle forKey:@"jobTitle"];
        
        NSMutableArray *arPhone = [[NSMutableArray alloc] init];
        ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
        {
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
            NSString *phoneLabel =(NSString*) ABAddressBookCopyLocalizedLabel (ABMultiValueCopyLabelAtIndex(phones, j));
            NSString *phoneNumber = (NSString *)phoneNumberRef;
            NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
            [temp setObject:phoneNumber forKey:@"phoneNumber"];
            [temp setObject:phoneLabel forKey:@"phoneNumber"];
            [arPhone addObject:temp];
            [temp release];
        }
        [myAddressBook setObject:arPhone forKey:@"Phone"];
        [arPhone release];
        
        CFStringRef address;
        CFStringRef label;
        ABMutableMultiValueRef multi = ABRecordCopyValue(ref, kABPersonAddressProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(multi); i++)
        {
            label = ABMultiValueCopyLabelAtIndex(multi, i);
            //CFStringRef readableLabel = ABAddressBookCopyLocalizedLabel(label);
            address = ABMultiValueCopyValueAtIndex(multi, i);
            CFRelease(address);
            CFRelease(label);
        }
        
        ABMultiValueRef emails = ABRecordCopyValue(ref, kABPersonEmailProperty);
        NSMutableArray *arEmail = [[NSMutableArray alloc] init];
        for(CFIndex idx = 0; idx < ABMultiValueGetCount(emails); idx++)
        {
            CFStringRef emailRef = ABMultiValueCopyValueAtIndex(emails, idx);
            NSString *strLbl = (NSString*) ABAddressBookCopyLocalizedLabel (ABMultiValueCopyLabelAtIndex (emails, idx));
            NSString *strEmail_old = (NSString*)emailRef;
            NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
            [temp setObject:strEmail_old forKey:@"strEmail_old"];
            [temp setObject:strLbl forKey:@"strLbl"];
            [arEmail addObject:temp];
            [temp release];
        }
        [myAddressBook setObject:arEmail forKey:@"Email"];
        [arEmail release];
    }
    [self createCSV:myAddressBook];
}

-(void) createCSV :(NSMutableDictionary*)arAddressData
{
    NSMutableString *stringToWrite = [[NSMutableString alloc] init];
    [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[arAddressData valueForKey:@"firstName"]]];
    [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[arAddressData valueForKey:@"lastName"]]];
    [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[arAddressData valueForKey:@"jobTitle"]]];
    
    NSMutableArray *arPhone = (NSMutableArray*) [arAddressData valueForKey:@"Phone"];
    for(int i = 0 ;i<[arPhone count];i++)
    {
        NSMutableDictionary *temp = (NSMutableDictionary*) [arPhone objectAtIndex:i];
        [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[temp valueForKey:@"phoneNumber"]]];
        [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[temp valueForKey:@"phoneNumber"]]];
        [temp release];
    }
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentDirectory=[paths objectAtIndex:0];
    NSString *strBackupFileLocation = [NSString stringWithFormat:@"%@/%@", documentDirectory,@"ContactList.csv"];
    [stringToWrite writeToFile:strBackupFileLocation atomically:YES encoding:NSUTF8StringEncoding error:nil];
}



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
        NSMutableDictionary* tempContactDic = [NSMutableDictionary new];
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople,i);
        
        CFStringRef firstName, lastName;
        firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        NSString *name = [NSString stringWithFormat:@"%@ %@", firstName , lastName];
        [tempContactDic setValue:name forKey:@"name"];
        
        NSString *strEmail;
        ABMultiValueRef email = ABRecordCopyValue(ref, kABPersonEmailProperty);
        CFStringRef tempEmailref = ABMultiValueCopyValueAtIndex(email, 0);
        strEmail = (__bridge  NSString *)tempEmailref;
        [tempContactDic setValue:strEmail forKey:@"email"];

        
        
        
        
        [contactsArray addObject:tempContactDic];
        
    }
    
    
    /*
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
    
    for ( int i = 0; i < nPeople; i++ )
    {
        ABRecordRef ref = CFArrayGetValueAtIndex( allPeople, i );
        NSLog(@"inside");
        
    }
    
    
    
	ABAddressBookRef ab;
	ab = ABAddressBookCreate();
	int len = (int) ABAddressBookGetPersonCount(ab);
	int i;
	for(i = 1; i < (len + 1); i++)
	{
		ABRecordRef person = ABAddressBookGetPersonWithRecordID(ab,(ABRecordID) i);
		CFStringRef firstName, lastName;
		char *lastNameString, *firstNameString;
		firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
		lastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
		
		static char* fallback = "";
		int fbLength = strlen(fallback);
		
		int firstNameLength = fbLength;
		bool firstNameFallback = true;
		int lastNameLength = fbLength;
		bool lastNameFallback = true;
		
		if (firstName != NULL)
		{
			firstNameLength = (int) CFStringGetLength(firstName);
			firstNameFallback = false;
		}
		if (lastName != NULL)
		{
			lastNameLength = (int) CFStringGetLength(lastName);
			lastNameFallback = false;
		}
		
		if (firstNameLength == 0) 
		{
			firstNameLength = fbLength;
			firstNameFallback = true;
		}
		if (lastNameLength == 0)
		{
			lastNameLength = fbLength;
			lastNameFallback = true;
		}
		
		firstNameString = malloc(sizeof(char)*(firstNameLength+1));
		lastNameString = malloc(sizeof(char)*(lastNameLength+1));
		
		if (firstNameFallback == true) 
		{
			strcpy(firstNameString, fallback);
		}
		else
		{
			CFStringGetCString(firstName, firstNameString, 10*CFStringGetLength(firstName), kCFStringEncodingASCII);
		}
		
		if (lastNameFallback == true) 
		{
			strcpy(lastNameString, fallback);
		} 
		else
		{
			CFStringGetCString(lastName, lastNameString, 10*CFStringGetLength(lastName), kCFStringEncodingASCII);
		}
		
		printf("%d.\t%s %s\n", i, firstNameString, lastNameString);
		
		
		if (firstName != NULL)
		{
			CFRelease(firstName);
		}
		if (lastName != NULL) 
		{
			CFRelease(lastName);
		}
		free(firstNameString);
		free(lastNameString);
	}
    */
}

- (NSString *) getName {
	return @"contacts_backup";
}


@end