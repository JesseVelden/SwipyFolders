@interface _UITapticEngine : NSObject
- (void)actuateFeedback:(NSInteger)count;
@end

@interface UIDevice (Private)
- (_UITapticEngine *)_tapticEngine;
@end


@interface UIPreviewForceInteractionProgress : UIInteractionProgress
- (id)initWithGestureRecognizer:(id)arg1;
@end

@interface SBApplication : NSObject
@property(copy, nonatomic) NSArray *dynamicShortcutItems;
@property(copy, nonatomic) NSArray *staticShortcutItems;
- (void)loadStaticShortcutItemsFromInfoDictionary:(id)arg1 bundle:(id)arg2;
- (NSString*)bundleIdentifier;
- (NSString*)displayName;
@end;

@interface SBIcon : NSObject
- (_Bool)isFolderIcon;
- (_Bool)isNewsstandIcon;
- (void)launch; 
- (void)launchFromLocation:(NSInteger)location; 
- (void)launchFromLocation:(NSInteger)location context:(id)context; 
- (SBApplication*)application;

- (void)openApp;

@end

@interface SBIconView : UIView
@property(retain, nonatomic) SBIcon *icon;
@property(assign, getter = isHighlighted) BOOL highlighted;
@property(retain, nonatomic) UIPreviewForceInteractionProgress *shortcutMenuPresentProgress; 
@property(retain, nonatomic) UILongPressGestureRecognizer *shortcutMenuPeekGesture; 
+ (id)sharedInstance;
- (void)_handleSecondHalfLongPressTimer:(id)arg1;
- (void)cancelLongPressTimer;
//New:
- (void)sf_method:(NSInteger)method;
- (void)sf_swipe:(UISwipeGestureRecognizer *)gesture;
- (void)sf_singleTap:(UITapGestureRecognizer *)gesture;
- (void)sf_doubleTap:(UITapGestureRecognizer *)gesture;
- (void)sf_shortHold:(UILongPressGestureRecognizer *)gesture;
- (BOOL)isFolderIconView;
@end

@class SBSApplicationShortcutIcon;
@interface SBSApplicationShortcutItem : NSObject
@property (nonatomic, copy) NSString *type;
- (id)icon;
- (void)setIcon:(id)arg1;
- (void)setLocalizedSubtitle:(id)arg1;
- (void)setLocalizedTitle:(id)arg1;
- (void)setType:(NSString *)arg1;
@end

@interface SBApplicationShortcutMenuItemView : UIView
@property(readonly, nonatomic) long long menuPosition; 
@property(retain, nonatomic) SBSApplicationShortcutItem *shortcutItem; 
@property(nonatomic) _Bool highlighted; 
+ (id)_imageForShortcutItem:(id)arg1 application:(id)arg2 assetManagerProvider:(id)arg3 monogrammerProvider:(id)arg4 maxHeight:(double *)arg5;
@end
@class SBApplicationShortcutMenuContentView;
@protocol SBApplicationShortcutMenuContentViewDelegate <NSObject>
- (void)menuContentView:(SBApplicationShortcutMenuContentView *)arg1 activateShortcutItem:(SBSApplicationShortcutItem *)arg2 index:(long long)arg3;
- (_Bool)menuContentView:(SBApplicationShortcutMenuContentView *)arg1 canActivateShortcutItem:(SBSApplicationShortcutItem *)arg2;
@end
@interface SBApplicationShortcutMenuContentView : UIView <SBApplicationShortcutMenuContentViewDelegate>
@property(assign,nonatomic) id <SBApplicationShortcutMenuContentViewDelegate> delegate;
- (id)initWithInitialFrame:(struct CGRect)arg1 containerBounds:(struct CGRect)arg2 orientation:(long long)arg3 shortcutItems:(id)arg4 application:(id)arg5;
- (void)_handlePress:(id)arg1;
- (double)_rowHeight;
- (void)_populateRowsWithShortcutItems:(id)arg1 application:(id)arg2;
@end
@class SBApplicationShortcutMenu;
@protocol SBApplicationShortcutMenuDelegate <NSObject>
- (void)applicationShortcutMenu:(SBApplicationShortcutMenu *)arg1 launchApplicationWithIconView:(SBIconView *)arg2;
- (void)applicationShortcutMenu:(SBApplicationShortcutMenu *)arg1 startEditingForIconView:(SBIconView *)arg2;
- (void)applicationShortcutMenu:(SBApplicationShortcutMenu *)arg1 activateShortcutItem:(SBSApplicationShortcutItem *)arg2 index:(long long)arg3;

@optional
- (void)applicationShortcutMenuDidPresent:(SBApplicationShortcutMenu *)arg1;
- (void)applicationShortcutMenuDidDismiss:(SBApplicationShortcutMenu *)arg1;
@end
@interface SBApplicationShortcutMenu : UIView
@property(retain, nonatomic) SBApplication *application; 
@property(retain ,nonatomic) id <SBApplicationShortcutMenuDelegate> applicationShortcutMenuDelegate; 
- (id)initWithFrame:(CGRect)arg1 application:(id)arg2 iconView:(id)arg3 interactionProgress:(id)arg4 orientation:(long long)arg5;
- (void)presentAnimated:(_Bool)arg1;
- (void)menuContentView:(id)arg1 activateShortcutItem:(id)arg2 index:(long long)arg3;
- (void)updateFromPressGestureRecognizer:(id)arg1;
@end


@interface SBIconController : UIViewController <SBApplicationShortcutMenuDelegate>
@property(retain, nonatomic) SBApplicationShortcutMenu *presentedShortcutMenu;
+ (id)sharedInstance;
- (void)_revealMenuForIconView:(id)arg1 presentImmediately:(BOOL)arg2;
- (BOOL)_canRevealShortcutMenu;
- (BOOL)isEditing;
- (void)iconHandleLongPress:(id)arg1;
- (void)setIsEditing:(_Bool)arg1;
- (void)_handleShortcutMenuPeek:(UILongPressGestureRecognizer *)recognizer ;
- (void)iconTapped:(SBIconView *)iconView;
- (_Bool)hasOpenFolder;
- (void)scrollToIconListContainingIcon:(SBIcon *)icon animate:(_Bool)arg2;
-(void)openFolder:(id)folder animated:(BOOL)animated;

- (BOOL)isFolderIconView:(SBIconView *)view;
- (void)launchFirstApp:(SBIconView *)iconView;
@end


@interface SBFolder : NSObject
- (SBIcon *)iconAtIndexPath:(NSIndexPath *)indexPath;
- (void)openFirstApp;
- (void)openSecondApp; 
@end

@interface SBFolderIcon : SBIcon
- (SBFolder *)folder;
@end

@interface SBFolderIconView : SBIconView
- (SBFolderIcon*)folderIcon;
@end


@interface SBIconViewMap
+ (id)homescreenMap;
- (SBIconView *)mappedIconViewForIcon:(SBIcon *)icon;
- (SBIconView *)iconViewForIcon:(SBIcon *)icon;
- (SBIconView *)_iconViewForIcon:(SBIcon *)icon;
@end

@interface SBApplicationShortcutStoreManager : NSObject
+ (id)sharedManager;
- (void)saveSynchronously;
- (void)setShortcutItems:(id)arg1 forBundleIdentifier:(id)arg2;
- (id)shortcutItemsForBundleIdentifier:(id)arg1;
- (id)init;
@end


@interface UIApplication (Private)
-(BOOL)launchApplicationWithIdentifier:(NSString*)identifier suspended:(BOOL)suspended;
@end

@interface SBIconGridImage
+ (struct CGRect)rectAtIndex:(NSUInteger)index maxCount:(NSUInteger)count;
@end



static NSUserDefaults *preferences;
static bool enabled;
static bool enableFolderPreview;
static NSInteger singleTapMethod;
static NSInteger swipeUpMethod;
static NSInteger doubleTapMethod;
static NSInteger shortHoldMethod;
static CGFloat shortHoldTime;
static NSInteger forceTouchMethod;

static void loadPreferences() {
    preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];

    [preferences registerDefaults:@{
        @"enabled": @YES,
        @"enableFolderPreview": @YES,
        @"singleTapMethod": [NSNumber numberWithInteger:2],
        @"swipeUpMethod": 	[NSNumber numberWithInteger:1],
        @"doubleTapMethod": [NSNumber numberWithInteger:0],
        @"shortHoldMethod": [NSNumber numberWithInteger:0],
        @"shortHoldTime": 	[NSNumber numberWithFloat:0.325],
        @"forceTouchMethod": [NSNumber numberWithInteger:4],
    }];
    
    enabled 			= [preferences boolForKey:@"enabled"];
    enableFolderPreview	= [preferences boolForKey:@"enableFolderPreview"];
    singleTapMethod 	= [preferences integerForKey:@"singleTapMethod"];
    swipeUpMethod 		= [preferences integerForKey:@"swipeUpMethod"];
    doubleTapMethod 	= [preferences integerForKey:@"doubleTapMethod"];
    shortHoldMethod 	= [preferences integerForKey:@"shortHoldMethod"];
    shortHoldTime 		= [preferences floatForKey:@"shortHoldTime"];
  	forceTouchMethod 	= [preferences integerForKey:@"forceTouchMethod"];

    [preferences release];

}


%hook SBIconGridImage
+ (struct CGRect)rectAtIndex:(NSUInteger)index maxCount:(NSUInteger)count{
	if (enableFolderPreview && enabled) {
		CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54;
	    CGFloat iconMargin = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 3 : 6;
	    if (index == 0) {
	        return CGRectMake(0, 0, iconSize, iconSize);
	    } else {
	        return CGRectMake(iconSize / 2, iconSize + iconMargin, 0, 0);
	    }
	}
	return %orig;
}
%end


static SBIcon *firstIcon;


%hook SBIconController
- (void)_handleShortcutMenuPeek:(UILongPressGestureRecognizer *)recognizer {
	SBIconView *iconView = (SBIconView*)recognizer.view;
	firstIcon = nil;
	if (iconView.isFolderIconView && enabled) {
		SBFolder* folder = ((SBFolderIconView *)iconView).folderIcon.folder;
		firstIcon = [folder iconAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		switch (recognizer.state) {
			case UIGestureRecognizerStateBegan: {

				[iconView cancelLongPressTimer];
				switch (forceTouchMethod) {
					case 1: {
						[[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
						[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //Open Folder
					}break;

					case 2: {
						[[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
						[((SBFolderIconView *)iconView).folderIcon.folder openFirstApp];
					}break;

					case 3: {
						[[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
						[((SBFolderIconView *)iconView).folderIcon.folder openSecondApp];
					}break;

					case 4: {
						self.presentedShortcutMenu = [[%c(SBApplicationShortcutMenu) alloc] initWithFrame:[UIScreen mainScreen].bounds application:firstIcon.application iconView:recognizer.view interactionProgress:nil orientation:1];
						self.presentedShortcutMenu.applicationShortcutMenuDelegate = self;
						UIViewController *rootView = [[UIApplication sharedApplication].keyWindow rootViewController];
						[rootView.view addSubview:self.presentedShortcutMenu];
						[self.presentedShortcutMenu presentAnimated:YES];
						[self applicationShortcutMenuDidPresent:self.presentedShortcutMenu];
					}break;

					default: 
					break;

				}

			}break;

			case UIGestureRecognizerStateChanged: {
				if (forceTouchMethod == 4) {
					[self.presentedShortcutMenu updateFromPressGestureRecognizer:recognizer];
				}
				iconView.highlighted = NO;
			}break;

			case UIGestureRecognizerStateEnded: {
				if (forceTouchMethod == 4) {
					SBApplicationShortcutMenuContentView *contentView = MSHookIvar<id>(self.presentedShortcutMenu,"_contentView");
					NSMutableArray *itemViews = MSHookIvar<NSMutableArray *>(contentView,"_itemViews");
					for(SBApplicationShortcutMenuItemView *item in itemViews) {
						if (item.highlighted == YES) {
							[self.presentedShortcutMenu menuContentView:contentView activateShortcutItem:item.shortcutItem index:item.menuPosition];
							break;
						}
					}
				}
				iconView.highlighted = NO;

			}break;
			default:
			break;

		}
	} else {
		%orig;
	}
	
}
%end



%hook SBApplicationShortcutMenu
- (id)_shortcutItemsToDisplay {
	
	//If it is a folder:
	if (self.application == nil && forceTouchMethod == 4 && enabled) {
		NSMutableArray *objects = [NSMutableArray new];
		[objects addObjectsFromArray:firstIcon.application.staticShortcutItems];
		[objects addObjectsFromArray:[[%c(SBApplicationShortcutStoreManager) sharedManager] shortcutItemsForBundleIdentifier:firstIcon.application.staticShortcutItems]];
		return objects;
	} 

	return %orig;	

}

%end


%hook SBIconView

%new - (BOOL)isFolderIconView {
    return self.icon.isFolderIcon && !([self.icon respondsToSelector:@selector(isNewsstandIcon)] && self.icon.isNewsstandIcon);
}

UISwipeGestureRecognizer *swipeUp;
UITapGestureRecognizer *singleTap;
UITapGestureRecognizer *doubleTap;
UILongPressGestureRecognizer *shortHold;

- (void)setLocation:(id)arg1 {
	if (self.isFolderIconView && enabled) {
	    [self removeGestureRecognizer:swipeUp];
	    [self removeGestureRecognizer:singleTap];
	    [self removeGestureRecognizer:doubleTap];
	    [self removeGestureRecognizer:shortHold];

	    if (swipeUpMethod != 0) {
		    swipeUp = [[%c(UISwipeGestureRecognizer) alloc] initWithTarget:self action:@selector(sf_swipe:)];
		    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
		    swipeUp.delegate = (id <UIGestureRecognizerDelegate>)self;
		    [self addGestureRecognizer:swipeUp];
		    [swipeUp release];
		}

		if (singleTapMethod != 0) {
			singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sf_singleTap:)];
			singleTap.numberOfTapsRequired = 1; 
        	[self addGestureRecognizer:singleTap];
        	[singleTap release];
		}

		if (doubleTapMethod != 0) {
			doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sf_doubleTap:)];
            doubleTap.numberOfTapsRequired = 2;
            [self addGestureRecognizer:doubleTap];
			[singleTap requireGestureRecognizerToFail:doubleTap];
            [doubleTap release];

		}

		if (shortHoldMethod != 0) {
            shortHold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sf_shortHold:)];
            shortHold.minimumPressDuration = shortHoldTime;
            [self addGestureRecognizer:shortHold];

		}
	    
	}
    %orig;
}


%new - (void)sf_singleTap:(UITapGestureRecognizer *)gesture {
	[self sf_method:singleTapMethod];
}

%new - (void)sf_doubleTap:(UITapGestureRecognizer *)gesture {
	[self sf_method:doubleTapMethod];
}

%new - (void)sf_shortHold:(UILongPressGestureRecognizer *)gesture {
	[self sf_method:shortHoldMethod];
}

%new - (void)sf_swipe:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:swipeUpMethod];
}

%new - (void)sf_method:(NSInteger)method {
	
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	if (!iconController.isEditing && !iconController.hasOpenFolder) { 
		[self cancelLongPressTimer];

		if ([self respondsToSelector:@selector(setHighlighted:)]) {
        	self.highlighted = NO;
		}
		SBFolder* folder = ((SBFolderIconView *)self).folderIcon.folder;

		switch (method) {
			case 1: {
				[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES];
			}break;

			case 2: {
				[folder openFirstApp];
			}break;

			case 3: {
				[folder openSecondApp];
			}break;

			default:
			break;
		}
		
	}
}

%end

%hook SBIcon
%new - (void)openApp {
	if([self respondsToSelector:@selector(launchFromLocation:context:)]) {
	    [self launchFromLocation:0 context:nil];
    } else if ([self respondsToSelector:@selector(launchFromLocation:)]) {
        [self launchFromLocation:0];
    } else if ([self respondsToSelector:@selector(launch)]) {
        [self launch];
    }
}

%end

%hook SBFolder

%new - (void)openFirstApp {
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	if (!iconController.isEditing && !iconController.hasOpenFolder) { 
		SBIcon *firstIcon = [self iconAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	    [firstIcon openApp];
	}
}

%new - (void)openSecondApp {
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	if (!iconController.isEditing && !iconController.hasOpenFolder) { 
		SBIcon *secondIcon = [self iconAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	    [secondIcon openApp];
	}
}
%end
 //Springboardhooks


%ctor{
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPreferences,
                                CFSTR("nl.jessevandervelden.swipyfoldersprefs/prefsChanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPreferences();
}
