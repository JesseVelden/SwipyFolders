#include "SwipyFoldersPrefs.h"

#import "SFSwitchTableCell.h"
#import "SFSliderTableCell.h"
#import "SFFolderListController.h"


static NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
static int customAppMethod = 5;

static NSString * addSuffixToNumber(int number) {
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

static NSString * setCustomAppIndexTextForIndex(int number) {
    return [NSString stringWithFormat:@"Custom: open %@ app", addSuffixToNumber(number)];
}



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

        if ([identifier isEqualToString:@"doubleTapTimeText"]) {
            NSLog(@"SwipyFolders: %lf", [preferences doubleForKey:@"doubleTapTime"]);
            double doubleTapTime = ([preferences doubleForKey:@"doubleTapTime"] == 0)? 0.2 : [preferences doubleForKey:@"doubleTapTime"];
            CGFloat inset = cell.bounds.size.width * 10;
            cell.separatorInset = UIEdgeInsetsMake(0, inset, 0, 0);
            cell.indentationWidth = -inset;
            cell.indentationLevel = 1;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2lf", doubleTapTime];

        } else if ([identifier isEqualToString:@"longHoldTimeText"]) {
            double longHoldTime = ([preferences doubleForKey:@"longHoldTime"] == 0)? 0.2 : [preferences doubleForKey:@"longHoldTime"];
            CGFloat inset = cell.bounds.size.width * 10;
            cell.separatorInset = UIEdgeInsetsMake(0, inset, 0, 0);
            cell.indentationWidth = -inset;
            cell.indentationLevel = 1;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2lf", longHoldTime];

        } else if ([identifier isEqualToString:@"singleTapMethod"] || [identifier isEqualToString:@"swipeUpMethod"] || [identifier isEqualToString:@"swipeDownMethod"] || [identifier isEqualToString:@"doubleTapMethod"] || [identifier isEqualToString:@"shortHoldMethod"] || [identifier isEqualToString:@"longHoldMethod"] || [identifier isEqualToString:@"forceTouchMethod"]) {

            int method  = [preferences integerForKey:identifier];
            if(method == 5) {
                int customAppIndex  = [preferences integerForKey:[NSString stringWithFormat:@"%@CustomAppIndex", identifier]];
                cell.detailTextLabel.text = setCustomAppIndexTextForIndex(customAppIndex);
            }
        }

    }
    return cell;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UITableView *tableView = MSHookIvar<UITableView*>(self, "_table");
    [tableView reloadData];
}

-(void)sliderMoved:(UISlider *)slider {
    UITableView *tableView = MSHookIvar<UITableView*>(self, "_table");

    CGPoint oiginInTableView = [slider convertPoint:CGPointZero toView:tableView];
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:oiginInTableView];
    PSTableCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    PSSpecifier *specifier = cell.specifier;

    NSString *specifierId = [NSString stringWithFormat:@"%@Text", specifier.identifier];

    UITableViewCell *textCell = (UITableViewCell *)[self cachedCellForSpecifierID:specifierId];
    textCell.detailTextLabel.text = [NSString stringWithFormat:@"%.2lf", slider.value];

}

- (void)respring {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
    CFSTR("nl.jessevandervelden.swipyfoldersprefs/respring"),
    nil,
    nil,
    true);
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

- (void)cydia {
    NSURL *url = [NSURL URLWithString:@"cydia://url/https://cydia.saurik.com/api/share#?source=http://megacookie.github.io/"];
    [[UIApplication sharedApplication] openURL:url];
}


@end

@implementation SFListItemsController


- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PSTableCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    PSSpecifier *specifier = cell.specifier;

    NSInteger method = [specifier.values[0] intValue];


    if(method == customAppMethod) {
        int customAppIndex  = [preferences integerForKey:[NSString stringWithFormat:@"%@CustomAppIndex", self.specifier.identifier]];
        cell.textLabel.text = setCustomAppIndexTextForIndex(customAppIndex);
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath]; //Instead of %orig();
    PSTableCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    PSSpecifier *specifier = cell.specifier;

    NSInteger method = [specifier.values[0] intValue];

    //NSInteger selectedRow = indexPath.row;
    if(method == customAppMethod) {

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

            UITextField *text_field = alertController.textFields.firstObject;
            NSString *appIndexText = text_field.text;
            NSNumber *appIndex = @([appIndexText intValue]);
            if (!appIndex || appIndex.integerValue < 1) {
                UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"SwipyFolders" message:@"Please enter a valid number" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:dismissAction];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }

            NSIndexPath *ip = [NSIndexPath indexPathForRow:customAppMethod inSection:0];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:ip];

            cell.textLabel.text = setCustomAppIndexTextForIndex([appIndex intValue]);

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


//Interface is imported
@implementation SFFolderListController

- (NSArray *)specifiers {

    if (!_specifiers) {

        CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"nl.jessevandervelden.swipyfolders.center"];
        NSDictionary *foldersDictionary = [messagingCenter sendMessageAndReceiveReplyName:@"foldersRepresentation" userInfo:nil];

        NSMutableArray *specs = [[[NSMutableArray alloc] init] retain];

        PSSpecifier *header = [PSSpecifier emptyGroupSpecifier];
        [header setProperty:@"Folders" forKey:@"label"];
        header.name = @"Folders";
        //[header setProperty:@"Coming soon: megacookie/libFolders for other developers" forKey:@"footerText"];
        [specs insertObject:header atIndex:0];

        NSArray * sortedFolderKeys = [[foldersDictionary allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];

        //for(int i=0; i<[foldersDictionary count]; i++) {
        for (id key in sortedFolderKeys) {
            NSDictionary *currentFolder = [foldersDictionary objectForKey:key];

            //NSDictionary *currentFolder = foldersDictionary[[NSString stringWithFormat:@"%d", i]];
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:currentFolder[@"displayName"] target:self set:NULL get:NULL detail:%c(SFCustomFolderSettingsController) cell:PSLinkCell edit:nil];
            if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) {
                NSArray *applicationBundleIDs = currentFolder[@"applicationBundleIDs"];
                [spec setProperty:[self createFolderIconImageWithIdentifiers:applicationBundleIDs] forKey:@"iconImage"];
            }


            [spec setProperty:@"1" forKey:@"isController"];
            [spec setProperty:currentFolder[@"folderID"] forKey:@"folderID"];
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
        if(i%3 == 0 && i!=0) { //Unfortunately 0%3 == also 0, so double checking fot that!
            width = margin;
            height += iconSize+margin;
        }
        if(![bundleIdentifiers[i] isEqualToString:@"com.broganminer.anchor"] && ![bundleIdentifiers[i] isEqualToString:@""]) {
            UIImage *appImage = [UIImage _applicationIconImageForBundleIdentifier:bundleIdentifiers[i] format:0 scale:[UIScreen mainScreen].scale];
            [appImage drawInRect:CGRectMake(width, height, iconSize, iconSize)];
        }
        width += iconSize+margin;

    }

    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return finalImage;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.table reloadData];
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    PSSpecifier *specifier = ((PSTableCell *) cell).specifier;

    NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
    NSDictionary *customFolderSettings = [preferences dictionaryForKey:@"customFolderSettings"];

    NSString *folderID = [specifier propertyForKey:@"folderID"];
    NSDictionary *folderSettings = customFolderSettings[folderID]; // >> Dit moet later een ID worden!

    if([folderSettings[@"customFolderFunctionallity"] intValue] == 1 || [folderSettings[@"customFolderAppearance"] intValue] == 1) {
        cell.detailTextLabel.text = @"Enabled";
    } else {
        cell.detailTextLabel.text = @"Not enabled";
    }
    return cell;
}

@end
