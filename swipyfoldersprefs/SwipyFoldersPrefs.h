#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface SwipyFoldersPrefs : PSListController
@end

@interface UITableViewLabel : UILabel 
@end

@interface NSArray(Private)
- (id)specifierForID:(id)id;
@end