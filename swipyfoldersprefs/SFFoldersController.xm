#import "SFFoldersController.h"

#define RowHeight 65.0f

/*static int integerValueForKey(CFStringRef key, int defaultValue) {
	CFPreferencesAppSynchronize(SB);
	Boolean valid;
	CFIndex value = CFPreferencesGetAppIntegerValue(key, SB, &valid);
	return valid ? value : defaultValue;
}*/

@implementation SFFoldersController

- (void)loadView {
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.rowHeight = RowHeight;
	self.view = tableView;
	[tableView release];
	NSLog(@"HOIHOIHOIHOIHOI************");
}

NSDictionary *foldersDictionary;
- (void)setSpecifier:(PSSpecifier *)specifier {
	[super setSpecifier:specifier];
	/*self.navigationItem.title = [specifier name];
	badgeBorderSize = integerValueForKey(BorderWidth, 3);
	badgeBorderColorMode = integerValueForKey(BorderColor, 2);*/
	if ([self isViewLoaded]) {
		CPDistributedMessagingCenter *messagingCenter;
		messagingCenter = [CPDistributedMessagingCenter centerNamed:@"nl.jessevandervelden.swipyfolders.center"];
		foldersDictionary = [messagingCenter sendMessageAndReceiveReplyName:@"foldersRepresentation" userInfo:nil];

		[(UITableView *)self.view setRowHeight:RowHeight];
		[(UITableView *)self.view reloadData];


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
		lbl2.textColor = UIColor.systemGrayColor;
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
*/
NSDictionary *foldersDictionary;
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {

	CPDistributedMessagingCenter *messagingCenter;
	messagingCenter = [CPDistributedMessagingCenter centerNamed:@"nl.jessevandervelden.swipyfolders.center"];
	foldersDictionary = [messagingCenter sendMessageAndReceiveReplyName:@"foldersRepresentation" userInfo:nil];
	NSLog(@"YOOOO");
	return [foldersDictionary count]; //Folder count
}

- (UIImage *)createFolderIconImageWithIdentifiers:(NSArray)bundleIdentifiers {
	//Do shit

	return nil;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"info"] ?: [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"info"] autorelease];
	cell.textLabel.textAlignment = NSTextAlignmentLeft;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; //Add the right arrow

	NSDictionary *currentFolder = foldersDictionary[[NSString stringWithFormat:@"%d", indexPath.row]];

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


@end
