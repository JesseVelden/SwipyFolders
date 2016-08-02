#include "SwipyFoldersPrefs.h"

#import "SFSwitchTableCell.h"
#import "SFSliderTableCell.h"
#import "SFFolderListController.h"


static NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];

@implementation SwipyFoldersPrefs

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SwipyFoldersPrefs" target:self] retain];

		Class DisplayController = %c(PSUIDisplayController); // Appears to be iOS 9+.
		if (!DisplayController) { // iOS 8.
			DisplayController = %c(DisplayController);
		}
	}
	
	return _specifiers;
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	// Oh god the hacks. Remove the separator between the slider cell and the cell before it.
	// This hack is from http://stackoverflow.com/a/32818943.
	if ([cell isKindOfClass:%c(PSTableCell)]) {
		PSSpecifier *specifier = ((PSTableCell *) cell).specifier;
		NSString *identifier = specifier.identifier;

		if ([identifier isEqualToString:@"doubleTapTimeText"] ) {
			CGFloat inset = cell.bounds.size.width * 10;
			cell.separatorInset = UIEdgeInsetsMake(0, inset, 0, 0);
			cell.indentationWidth = -inset;
			cell.indentationLevel = 1;
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2lf", [preferences doubleForKey:@"doubleTapTime"]];
		} else if ([identifier isEqualToString:@"singleTapMethod"] || [identifier isEqualToString:@"swipeUpMethod"] || [identifier isEqualToString:@"swipeDownMethod"] || [identifier isEqualToString:@"doubleTapMethod"] || [identifier isEqualToString:@"shortHoldMethod"] || [identifier isEqualToString:@"forceTouchMethod"]) {
			
			int method  = [preferences integerForKey:identifier];
			if(method == 5) {
				int customAppIndex  = [preferences integerForKey:[NSString stringWithFormat:@"%@CustomAppIndex", identifier]];
				cell.detailTextLabel.text = [customAppText setTextForIndex:customAppIndex]; 
			}
		} 

	}
	return cell;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	UITableView *tableView = MSHookIvar<UITableView*>(self, "_table");
	[tableView reloadData];

	CPDistributedMessagingCenter *messagingCenter;
	messagingCenter = [CPDistributedMessagingCenter centerNamed:@"nl.jessevandervelden.swipyfolders.center"];

	NSDictionary *foldersRepresentation;
	foldersRepresentation = [messagingCenter sendMessageAndReceiveReplyName:@"foldersRepresentation" userInfo:nil];
	//NSLog(@"YOOOOOOOOOOOOOOOO********************* Dictionary: %@", foldersRepresentation);

}

-(void)sliderMoved:(UISlider *)slider {
	UITableViewCell *doubleTapTextCell = (UITableViewCell *)[self cachedCellForSpecifierID:@"doubleTapTimeText"];
	doubleTapTextCell.detailTextLabel.text = [NSString stringWithFormat:@"%.2lf", slider.value];

}

- (void)respring {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
	system("killall -9 SpringBoard");
#pragma GCC diagnostic pop
}

- (void)github {
	NSURL *githubURL = [NSURL URLWithString:@"https://github.com/megacookie/SwipyFolders"];
	[[UIApplication sharedApplication] openURL:githubURL];
}

- (void)contact {
	NSURL *url = [NSURL URLWithString:@"mailto:mail@jessevandervelden.nl?subject=SwipyFolders"];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)paypal {
	NSURL *url = [NSURL URLWithString:@"https://paypal.me/JessevanderVelden"];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)twitter {
	NSURL *url = [NSURL URLWithString:@"https://twitter.com/JesseVelden"];
	[[UIApplication sharedApplication] openURL:url];
}


@end

@implementation SFListItemsController


- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if(indexPath.row == 4) {
		int customAppIndex  = [preferences integerForKey:[NSString stringWithFormat:@"%@CustomAppIndex", self.specifier.identifier]];
		cell.textLabel.text = [customAppText setTextForIndex:customAppIndex];
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath]; //Instead of %orig();
	
	NSInteger selectedRow = indexPath.row;
	if(selectedRow == 4) {

		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"SwipyFolders"
			message:@"Enter an app's position in the folder. Example: the third app will be: 3"
			preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *cancelAction = [UIAlertAction 
			actionWithTitle:@"Cancel"
			style:UIAlertActionStyleCancel
			handler:nil];

		UIAlertAction *okAction = [UIAlertAction 
			actionWithTitle:@"Enter"
			style:UIAlertActionStyleDefault
			handler:^(UIAlertAction *action) {

				NSString *appIndexText = alertController.textFields.firstObject.text;
				NSNumber *appIndex = @([appIndexText intValue]);
				if (!appIndex || appIndex.integerValue < 1) {
					UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"SwipyFolders" message:@"Please enter a valid number" preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
					[alert addAction:dismissAction];
					[self presentViewController:alert animated:YES completion:nil];
					return;
				}

				NSIndexPath *ip = [NSIndexPath indexPathForRow:4 inSection:0];
				UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];

				cell.textLabel.text = [customAppText setTextForIndex:[appIndex intValue]];

				[preferences setInteger:appIndex.integerValue forKey:[NSString stringWithFormat:@"%@CustomAppIndex", self.specifier.identifier]];
				[preferences synchronize];


				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
						// notify after file write to update
						CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[self.specifier propertyForKey:@"PostNotification"], NULL, NULL, YES);
				});

				

			}];

		[alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
			textField.placeholder = @"e.g. 3, 5, 99";
			[textField resignFirstResponder];
			[textField setKeyboardType:UIKeyboardTypeNumberPad];
			UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
			[textField setLeftViewMode:UITextFieldViewModeAlways];
			[textField setLeftView:spacerView];
		}];

		[alertController addAction:cancelAction];
		[alertController addAction:okAction];
		[self presentViewController:alertController animated:YES completion:nil];

	}
	
}
@end

@implementation customAppText

+(NSString *) setTextForIndex: (int) number {
	return [NSString stringWithFormat:@"Custom: open %@ app", [self addSuffixToNumber: number]]; 
}

+(NSString *) addSuffixToNumber:(int) number {
    NSString *suffix;
    int ones = number % 10;
    int tens = (number/10) % 10;

    if (tens == 1) {
        suffix = @"th";
    } else {
    	switch (ones) {
            case 1:
                suffix = @"st";
                break;
            case 2:
                suffix = @"nd";
                break;
            case 3:
                suffix = @"rd";
                break;
            default:
                suffix = @"th";
                break;
        }
    }

    return [NSString stringWithFormat:@"%d%@", number, suffix];
}

@end


@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier roleIdentifier:(NSString *)roleIdentifier format:(int)format scale:(CGFloat)scale;
@end

//Interface is imported
@implementation SFFolderListController
- (NSArray *)specifiers {
	
	if (!_specifiers) {

		CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"nl.jessevandervelden.swipyfolders.center"];
		NSDictionary *foldersDictionary = [messagingCenter sendMessageAndReceiveReplyName:@"foldersRepresentation" userInfo:nil];

		NSMutableArray *specs = [[[NSMutableArray alloc] init] retain];

		PSSpecifier *header = [PSSpecifier emptyGroupSpecifier];
		[header setProperty:@"Foldersss" forKey:@"footerText"];
		[specs addObject:header];

		for(int i=0; i<[foldersDictionary count]; i++) {
			NSDictionary *currentFolder = foldersDictionary[[NSString stringWithFormat:@"%d", i]];
			PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:currentFolder[@"displayName"] target:self set:NULL get:NULL detail:%c(SFCustomFolderSettingsController) cell:PSLinkCell edit:nil];
			//UIImage *folderIcon = nil;
			if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {

			}
			NSArray *applicationBundleIDs = currentFolder[@"applicationBundleIDs"];

			[spec setProperty:[self createFolderIconImageWithIdentifiers:applicationBundleIDs] forKey:@"iconImage"];
			//[spec setProperty:[UIImage imageWithContentsOfFile:@"/var/mobile/swipyfolders/swipyfoldersprefs/Resources/paypal.png"] forKey:@"iconImage"];
			[specs addObject:spec];

		}

		_specifiers = [[specs copy] retain];

		Class DisplayController = %c(PSUIDisplayController); // Appears to be iOS 9+.
		if (!DisplayController) { // iOS 8.
			DisplayController = %c(DisplayController);
		}
	}
	
	return _specifiers;
}

- (UIImage *)createFolderIconImageWithIdentifiers:(NSArray*)bundleIdentifiers {
	double totalSize = 44.5; // Normal = 60
	double iconSize = 10.5; //Normal = 13 --> 13/(60/44.5) = 9.64, but I like bigger icons :P
	UIColor *backgroundColor = [UIColor colorWithRed:171.0/255.0 green:188.0/255.0 blue:216.0/255.0 alpha:1];

	UIGraphicsBeginImageContextWithOptions(CGSizeMake(totalSize, totalSize), false, 0.0);
	UIBezierPath *backgroundPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0, totalSize, totalSize) cornerRadius:10];
	[backgroundColor setFill];
	[backgroundPath fill];

	double margin = (totalSize-iconSize*3)/4; //You got 4 margins! <--m--APP--m--APP--m--APP--m-->
	double width = margin;
	double height = margin;
	for(int i=0; i<[bundleIdentifiers count] && i<9; i++) {
		if(i%3 == 0 && i!=0) {
			width = margin;
			height += iconSize+margin;
		}

		UIImage *appImage = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifiers[i] format:0 scale:[UIScreen mainScreen].scale];
		[appImage drawInRect:CGRectMake(width, height, iconSize, iconSize)];
		width += iconSize+margin;

	}

	UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return finalImage;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

@end


/*
@interface SFBetterFoldersListController: PSViewController <UITableViewDataSource, UITableViewDelegate>
@end

#define RowHeight 65.0f

@implementation SFBetterFoldersListController
NSDictionary *foldersDictionary;

- (void)loadView {
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.rowHeight = RowHeight;
	self.view = tableView;
	[tableView release];
	NSLog(@"HOIHOIHOIHOIHOI************");
	CPDistributedMessagingCenter *messagingCenter;
	messagingCenter = [CPDistributedMessagingCenter centerNamed:@"nl.jessevandervelden.swipyfolders.center"];
	foldersDictionary = [messagingCenter sendMessageAndReceiveReplyName:@"foldersRepresentation" userInfo:nil];
	NSLog(@"YOOO%@", foldersDictionary);
}

- (void)setSpecifier:(PSSpecifier *)specifier {
	[super setSpecifier:specifier];
	self.navigationItem.title = @"SUPER COOL FOLDERS";
	if ([self isViewLoaded]) {


		[(UITableView *)self.view setRowHeight:RowHeight];
		//[(UITableView *)self.view reloadData];


	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
	return 1;
}

//TOP
- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section {
	return @"Folders";
}

//FOOTER
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == [self numberOfSectionsInTableView:tableView]-1) {
		UIView *footer2 = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 90)] autorelease];
		footer2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		footer2.backgroundColor = UIColor.clearColor;

		UILabel *lbl2 = [[UILabel alloc] initWithFrame:footer2.frame];
		lbl2.backgroundColor = [UIColor clearColor];
		lbl2.text = @"Want to have folder specific settings in your tweak? Checkout MegaCookie/libFolders";
		lbl2.textColor = [UIColor grayColor];
		lbl2.font = [UIFont systemFontOfSize:14.0f];
		lbl2.textAlignment = NSTextAlignmentCenter;
		lbl2.lineBreakMode = NSLineBreakByWordWrapping;
		lbl2.numberOfLines = 2;
		lbl2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[footer2 addSubview:lbl2];
		[lbl2 release];
    	return footer2;
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return section == [self numberOfSectionsInTableView:tableView]-1 ? 100 : 0;
}
//END FOOTER

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	NSLog(@"numberOfRowsInSection");
	return [foldersDictionary count]; //Folder count
}

- (UIImage *)createFolderIconImageWithIdentifiers:(NSArray*)bundleIdentifiers {
	//Do shit

	return nil;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"info"] ?: [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"info"] autorelease];
	cell.textLabel.textAlignment = NSTextAlignmentLeft;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; //Add the right arrow

	NSDictionary *currentFolder = foldersDictionary[[NSString stringWithFormat:@"%ld", (long)indexPath.row]];

	cell.textLabel.text = currentFolder[@"displayName"]; //HIER DE FOLDER NAAM
	cell.imageView.image = [self createFolderIconImageWithIdentifiers:currentFolder[@"applicationBundleIDs"]];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSInteger section = indexPath.section;
	NSInteger value = indexPath.row;

	//Push a new settings view
}


- (id)table {
	return nil;
}

@end
*/

