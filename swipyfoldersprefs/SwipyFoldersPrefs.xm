#include "SwipyFoldersPrefs.h"

#import "SFSwitchTableCell.h"

@implementation SwipyFoldersPrefs

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SwipyFoldersPrefs" target:self] retain];
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

-(void)respring {
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


@end
