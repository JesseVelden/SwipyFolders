#include "SwipyFoldersPrefs.h"

#import "SFSwitchTableCell.h"
#import "SFSliderTableCell.h"

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

    if ([identifier isEqualToString:@"shortHoldTimeText"] || [identifier isEqualToString:@"doubleTapTimeText"] ) {
      CGFloat inset = cell.bounds.size.width * 10;
      cell.separatorInset = UIEdgeInsetsMake(0, inset, 0, 0);
      cell.indentationWidth = -inset;
      cell.indentationLevel = 1;
    }

  }
  return cell;
}

- (void)respring {
	system("killall -9 SpringBoard");
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView didSelectRowAtIndexPath:indexPath]; //Instead of %orig();

  NSInteger selectedRow = indexPath.row;
  if(selectedRow == 4) {
    alert = [[UIAlertView alloc] initWithTitle:@"SwipyFolders"
                          message:@"Enter an app's position in the folder. Example: the third app will be: 3"
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Enter"
                          , nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alert show];

    UITextField *indexPromptTextField = [alert textFieldAtIndex:0];
    [indexPromptTextField setDelegate:self];
    [indexPromptTextField resignFirstResponder];
    
    [indexPromptTextField setKeyboardType:UIKeyboardTypeNumberPad];
    indexPromptTextField.placeholder = @"e.g. 3, 5, 99";

    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    [indexPromptTextField setLeftViewMode:UITextFieldViewModeAlways];
    [indexPromptTextField setLeftView:spacerView];

  }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if(buttonIndex != [alertView cancelButtonIndex]) {
    NSString *appIndexText = [alertView textFieldAtIndex:0].text;
    NSNumber *appIndex = @([appIndexText intValue]);

    if (!appIndex || appIndex.integerValue < 1) {
      [[[UIAlertView alloc] initWithTitle:@"SwipyFolders" message:@"This index is not a valid number!" delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
      return;
    }

    preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
    [preferences setInteger:appIndex.integerValue forKey:[NSString stringWithFormat:@"%@AppIndex", self.specifier]];
    [preferences synchronize];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // notify after file write
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[self.specifier propertyForKey:@"PostNotification"], NULL, NULL, YES);
    });

  }
}
@end