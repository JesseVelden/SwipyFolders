#import "SFSliderTableCell.h"

@implementation SFSliderTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier*)specifier {
	self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];
    if (self) {
        UISlider *slider = (UISlider *)[self control];
        [slider addTarget:specifier.target action:@selector(sliderMoved:) forControlEvents:UIControlEventAllTouchEvents];

    }
    return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
  [super refreshCellContentsWithSpecifier:specifier];

}

@end
