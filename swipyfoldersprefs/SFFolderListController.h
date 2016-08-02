#import "PreferenceHeaders/PSListController.h"


@interface SFFolderListController : PSListController
- (NSArray *)specifiers;
- (UIImage *)createFolderIconImageWithIdentifiers:(NSArray*)bundleIdentifiers;
@end
