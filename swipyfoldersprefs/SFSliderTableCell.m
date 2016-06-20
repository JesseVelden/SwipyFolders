#import "SFSliderTableCell.h"

@implementation SFSliderTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(id)specifier {
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
  return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
  [super refreshCellContentsWithSpecifier:specifier];
  NSString *rightImageR = [specifier propertyForKey:@"rightImageR"];
  if (rightImageR) {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:rightImageR]];
    self.accessoryView = imageView;
    [imageView release];

  }
}

@end
