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


static void setSetting(id value, NSString * folderName, NSString * specifierID) {
	NSMutableDictionary *mutableFolderSettings = [folderSettings mutableCopy];
	NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	if(!mutableFolderSettings) mutableFolderSettings = [NSMutableDictionary new];
	if(!mutableCustomFolderSettings) mutableCustomFolderSettings = [NSMutableDictionary new];

	[mutableFolderSettings setObject:value forKey:specifierID];
	[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:folderName];

	[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
	[preferences synchronize];

	CFStringRef toPost = (CFStringRef)@"nl.jessevandervelden.swipyfoldersprefs/prefsChanged"; //(CFStringRef)specifier.properties[@"PostNotification"];
	if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);

	NSLog(@"mutableFolderSettings: %@", mutableCustomFolderSettings);
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
	
	/*for(int i=0; i<[_specifiers count]; i++) {
		PSSpecifier *specifier = _specifiers[i];
		[specifier setProperty:[self.specifier name] forKey:@"folderName"];
	}*/
	
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self getCustomFolderSettings];
	self.navigationItem.title = folderName;

	UITableView *tableView = self.table;
	[tableView reloadData];
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	PSSpecifier *specifier = ((PSTableCell *) cell).specifier;

	NSLog(@"Settings: %@",folderSettings);

	if(![specifier.identifier isEqualToString:@"customFolderEnabled"]) {
		int method  = [folderSettings[specifier.identifier] intValue];
		if(method == 5) {
			//NSString *customAppIndexString = [NSString stringWithFormat:@"%@CustomAppIndex", specifier.identifier];

			int customAppIndex  = [folderSettings[[NSString stringWithFormat:@"%@CustomAppIndex", specifier.identifier]] intValue];
			cell.detailTextLabel.text = setCustomAppIndexTextForIndex(customAppIndex); 
		}
	}

	return cell;
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
	return folderSettings[specifier.identifier];
}

-(void)setValuePreference:(id)value forSpecifier:(PSSpecifier*)specifier {
	setSetting(value, [self.specifier name], specifier.identifier); //>> LATER EEN ID
}

@end


@interface SFCustomFolderSettingsListItemsController : PSListItemsController
@end

@implementation SFCustomFolderSettingsListItemsController



- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = (PSTableCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	if(indexPath.row == 4) {
		int customAppIndex  = [folderSettings[[NSString stringWithFormat:@"%@CustomAppIndex", [self.specifier identifier]]] intValue];
		cell.textLabel.text = setCustomAppIndexTextForIndex(customAppIndex);
	}

		
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	
	if(indexPath.row == 4) { 

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

				//Set settings isn't working :(
				NSString *specifierID = [NSString stringWithFormat:@"%@CustomAppIndex", [self.specifier identifier]];

				NSMutableDictionary *mutableFolderSettings = [folderSettings mutableCopy];
				NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];

				[mutableFolderSettings setObject:appIndexText forKey:specifierID];
				[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:folderName];

				[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
				[preferences synchronize];

				setSetting(@"5", folderName, [self.specifier identifier]); //This works :P


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