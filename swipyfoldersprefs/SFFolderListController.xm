#import "SFFolderListController.h"

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