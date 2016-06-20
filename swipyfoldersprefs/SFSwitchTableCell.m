#import "SFSwitchTableCell.h"

static UIColor * UIColorFromRGB(int rgb) {
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0F
                         green:((rgb >> 8) & 0xFF) / 255.0F
                          blue:(rgb & 0xFF) / 255.0F
                         alpha:1];
}


@implementation SFSwitchTableCell


- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier {
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
  if (self) {
    UIColor *tintColor = UIColorFromRGB(0xFF9000);
    [((UISwitch *)[self control]) setOnTintColor:tintColor];

    _hidesSeparators = NO;
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
}

- (UITableViewCellSeparatorStyle)wantedSeparatorStyle {
  return (_hidesSeparators) ? UITableViewCellSeparatorStyleNone :
      UITableViewCellSeparatorStyleSingleLine;
}

- (void)setHidesSeparators:(BOOL)hides {
  if (hides != _hidesSeparators) {
    _hidesSeparators = hides;
    self.separatorStyle = [self wantedSeparatorStyle];
  }
}

- (void)setSeparatorStyle:(UITableViewCellSeparatorStyle)style {
  [super setSeparatorStyle:[self wantedSeparatorStyle]];
}

@end
