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

- (void)get {
	// AddressBook
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
		
		// Muestro por la consola los datos
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
	
}

- (NSString *) getName {
	return @"contacts";
}


@end
