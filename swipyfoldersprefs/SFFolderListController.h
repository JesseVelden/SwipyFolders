#import "PreferenceHeaders/PSListController.h"

@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier roleIdentifier:(NSString *)roleIdentifier format:(int)format scale:(CGFloat)scale;
@end


@interface SFFolderListController : PSListController
- (NSArray *)specifiers;
- (UIImage *)createFolderIconImageWithIdentifiers:(NSArray*)bundleIdentifiers;
@end
