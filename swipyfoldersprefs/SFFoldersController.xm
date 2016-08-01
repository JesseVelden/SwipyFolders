#import "SFFoldersController.h"

/*static UIColor * UIColorFromRGB(int rgb) {
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0F
                         green:((rgb >> 8) & 0xFF) / 255.0F
                          blue:(rgb & 0xFF) / 255.0F
                         alpha:1];
}*/

@implementation SFFoldersController


- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier {
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];

  return self;
}


- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
  [super refreshCellContentsWithSpecifier:specifier];
}

/*
- (id)specifiers { //SEE ALSO POOMSMART'S SHIT
	CPDistributedMessagingCenter *messagingCenter;
	messagingCenter = [CPDistributedMessagingCenter centerNamed:@"unique.name.for.messaging.center"];
}
*/

@end
