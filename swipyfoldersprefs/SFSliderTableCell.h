#import "PreferenceHeaders/PSSliderTableCell.h"
#import "PreferenceHeaders/PSControlTableCell.h"
#import "PreferenceHeaders/PSSpecifier.h"

@interface SFSliderTableCell : PSSliderTableCell
@end

@interface UISpecifierSlider : UISlider {
    id userData;
}

@property (nonatomic, readwrite, retain) id userData;

@end
