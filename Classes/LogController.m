//
//  LogController.m
//  Prey
//
//  Created by Carlos Yaconi on 28/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//

#import "LogController.h"


@implementation LogController

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[PreyLogger getLogArray] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	cell.textLabel.text = [logArray objectAtIndex:[logArray count] - indexPath.row - 1];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 0;
	cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:10.0];
    
    return cell;
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
    NSString *cellText = [logArray objectAtIndex:[logArray count] - indexPath.row - 1];
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:10.0];
    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
    CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
    
    return labelSize.height + 5;
    //return 11;
}

- (void) reloadLogTable {
    [logArray release];
    logArray = [[PreyLogger getLogArray] retain];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *deleteLog = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"recycle-full.png"] style:UIBarButtonItemStylePlain target:self action:@selector(buttonPressed:)];
    deleteLog.tag = DELETE_LOG_BUTTON;
    
    UIBarButtonItem *sendLog = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"email.png"] style:UIBarButtonItemStylePlain target:self action:@selector(buttonPressed:)];
    sendLog.tag = SEND_LOG_BUTTON;

    UIBarButtonItem *refreshLog = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reload.png"] style:UIBarButtonItemStylePlain target:self action:@selector(buttonPressed:)];
    refreshLog.tag = REFRESH_LOG_BUTTON;
    
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [NSArray arrayWithObjects: refreshLog, flexItem, deleteLog, flexItem, sendLog, nil];
    
    //release buttons
    [deleteLog release];
    [sendLog release];
    [refreshLog release];
    [flexItem release];

    
    //add array of buttons to toolbar
    [self.navigationController setToolbarHidden:NO animated:NO];
    [self setToolbarItems:items];

}
- (void) buttonPressed:(id)sender{
    
    NSString *label = nil;
	NSString *button = nil;
	UIActionSheet *actionSheet = nil;
    
    
    switch ([(UIBarButtonItem*)sender tag]) {
		case DELETE_LOG_BUTTON:
            label = NSLocalizedString(@"Log records will be deleted.\n\nAre you sure?",nil);
            button = NSLocalizedString(@"Delete log",nil);
            actionSheet = [[UIActionSheet alloc] initWithTitle:label
                                                                     delegate:self 
                                                            cancelButtonTitle:button
                                                       destructiveButtonTitle:@"Cancel" otherButtonTitles:nil];
            [actionSheet setTag:DELETE_LOG_BUTTON];
            [actionSheet showFromBarButtonItem:sender animated:YES];
            
			break;
        case SEND_LOG_BUTTON:
            label = NSLocalizedString(@"Log records will be sent to developers. You'll be able to check the email body before proceed.",nil);
            button = NSLocalizedString(@"Send log",nil);
            actionSheet = [[UIActionSheet alloc] initWithTitle:label
                                                                     delegate:self 
                                                            cancelButtonTitle:button
                                                       destructiveButtonTitle:@"Cancel" otherButtonTitles:nil];
            [actionSheet setTag:SEND_LOG_BUTTON];
            [actionSheet showFromBarButtonItem:sender animated:YES];
            break;
        case REFRESH_LOG_BUTTON:
            [self reloadLogTable];
            break;
    }
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (actionSheet.tag == DELETE_LOG_BUTTON){
		if (buttonIndex == 1){
            [PreyLogger clearLogFile];
            [self reloadLogTable];
        }
    }
	else if (actionSheet.tag == SEND_LOG_BUTTON)
        if (buttonIndex == 1){
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
                mailViewController.mailComposeDelegate = self;
                [mailViewController setSubject:@"Prey iOS Log"];
                [mailViewController setMessageBody:[PreyLogger logAsText] isHTML:NO];
                [mailViewController setToRecipients:[NSArray arrayWithObject:@"prey-ios-devs@usefork.com"]];
                [self presentModalViewController:mailViewController animated:YES];
                [mailViewController release];
            }
            else
            {
                PreyLogMessageAndFile(@"LogController",0,@"Device is unable to send email in its current state.");
                [self reloadLogTable];
            }
        }
}

#pragma mark -
#pragma mark MFMailComposeViewController delegate
-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];  
    logArray = [[PreyLogger getLogArray] retain];
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
     [super viewDidDisappear:animated];
 }
*/
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {

    [super dealloc];
    [logArray release];
}



@end
