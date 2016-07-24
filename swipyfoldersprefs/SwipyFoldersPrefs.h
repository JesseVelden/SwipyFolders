#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSTableCell.h>


@interface SwipyFoldersPrefs : PSListController
@end

@interface UITableViewLabel : UILabel 
@end

@interface NSArray(Private)
- (id)specifierForID:(id)id;
@end

@interface PSListItemsController (tableView)
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;
- (void)listItemSelected:(id)arg1;
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
@end

@interface SFListItemsController : PSListItemsController <UIAlertViewDelegate, UITextFieldDelegate> {
    UIAlertView * alert;
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
@end

