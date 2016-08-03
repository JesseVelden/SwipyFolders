#import "PreferenceHeaders/PSListController.h"
#import "PreferenceHeaders/PSSpecifier.h"
#import "PreferenceHeaders/PSListItemsController.h"
#import "PreferenceHeaders/PSTableCell.h"
#import "PreferenceHeaders/PSSwitchTableCell.h"


@interface SFCustomFolderSettingsController : PSListController
@end

static NSUserDefaults *preferences;

static NSDictionary *customFolderSettings; //root
static NSDictionary *folderSettings;
static NSString *folderName;

/*
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
*/


static UIColor * UIColorFromRGB(int rgb) {
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0F
                         green:((rgb >> 8) & 0xFF) / 255.0F
                          blue:(rgb & 0xFF) / 255.0F
                         alpha:1];
}

static void setSetting(id value, NSString * folderName, NSString * specifierID) {
	NSMutableDictionary *mutableFolderSettings = [folderSettings mutableCopy];
	NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	if(!mutableFolderSettings) mutableFolderSettings = [NSMutableDictionary new];
	if(!mutableCustomFolderSettings) mutableCustomFolderSettings = [NSMutableDictionary new];

	[mutableFolderSettings setObject:value forKey:specifierID];
	[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:folderName];

	[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
	[preferences synchronize];
}

@implementation SFCustomFolderSettingsController

- (void)getCustomFolderSettings {
	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
	customFolderSettings = [[preferences dictionaryForKey:@"customFolderSettings"] retain];
	folderSettings = customFolderSettings[[self.specifier name]]; // >> Dit moet later een ID worden!
	folderName = [self.specifier name];
}


- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"CustomFolderSettings" target:self] retain];
	}
	for(int i=0; i<[_specifiers count]; i++) {
		PSSpecifier *specifier = _specifiers[i];
		[specifier setProperty:[self.specifier name] forKey:@"folderName"];
	}
	
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.title = [self.specifier name];

	[self getCustomFolderSettings];
	UITableView *tableView = self.table;
	[tableView reloadData];
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	PSSpecifier *specifier = ((PSTableCell *) cell).specifier;

	if([specifier.identifier isEqualToString:@"customFolderEnabled"]) {

	} else {
		
		NSDictionary *titleValues = specifier.titleDictionary;
		NSString *customSetting = folderSettings[specifier.identifier]; //Yes, the integer is stored as a NSString

		//Also check for if the method is 5 >> customAppIndexText
		cell.detailTextLabel.text = [titleValues objectForKey:customSetting]; 
	}


	return cell;
}

@end

@interface SFCustomFolderSettingsSwitchController : PSSwitchTableCell 
@end

@implementation SFCustomFolderSettingsSwitchController

- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier {
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
  if (self) {
    UIColor *tintColor = UIColorFromRGB(0xFF9000);
    [((UISwitch *)[self control]) setOnTintColor:tintColor];

  }
  return self;
}


- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
  [super refreshCellContentsWithSpecifier:specifier];
  NSString *sublabel = [specifier propertyForKey:@"sublabel"];

  if (sublabel) {
    self.detailTextLabel.text = [sublabel description];
    self.detailTextLabel.textColor = [UIColor grayColor];
  }

  NSString *enabled = folderSettings[[self.specifier identifier]];
  if([enabled intValue] == 1) {
  	[((UISwitch *)[self control]) setOn:YES animated:NO];
  } else {
  	[((UISwitch *)[self control]) setOn:NO animated:NO];
  }
}

- (void)setValue:(id)valueSetting {
	setSetting(valueSetting, [self.specifier propertyForKey:@"folderName"], [self.specifier identifier]);
}


@end

@interface SFCustomFolderSettingsListItemsController : PSListItemsController
@end

@implementation SFCustomFolderSettingsListItemsController


- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = (PSTableCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	int selectedRow = [self.specifier.values indexOfObject:folderSettings[[self.specifier identifier]]];

	if(indexPath.row == selectedRow) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	/*
	if(indexPath.row == 4) {
		int customAppIndex  = [preferences integerForKey:[NSString stringWithFormat:@"%@CustomAppIndex", self.specifier.identifier]];
		cell.textLabel.text = setCustomAppIndexTextForIndex(customAppIndex);
	}*/

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];

	
	//UITableViewCell *cell = (PSTableCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
	//PSSpecifier *specifier = ((PSTableCell *) cell).specifier;
	
	NSInteger selectedRow = indexPath.row;

	NSString *value = [self.specifier.values objectAtIndex:selectedRow];
	setSetting(value, [self.specifier propertyForKey:@"folderName"], [self.specifier identifier]);
	

	/*if(selectedRow == 4) { FFKES GEEN ZIN IN :P

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

	}*/
	
}
@end