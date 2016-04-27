#import "SwipyFolders.h"

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
	
	enabled 		= [preferences boolForKey:@"enabled"];
	enableFolderPreview	= [preferences boolForKey:@"enableFolderPreview"];
	singleTapMethod 	= [preferences integerForKey:@"singleTapMethod"];
	swipeUpMethod 		= [preferences integerForKey:@"swipeUpMethod"];
	doubleTapMethod 	= [preferences integerForKey:@"doubleTapMethod"];
	shortHoldMethod 	= [preferences integerForKey:@"shortHoldMethod"];
	shortHoldTime 		= [preferences floatForKey:@"shortHoldTime"];
	forceTouchMethod 	= [preferences integerForKey:@"forceTouchMethod"];

	[preferences release];

}

static void respring() {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Respring - SwipyFolders"
						message:@"In order to change the folder preview, a respring is required. Want to respring now?"
						preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancelAction = [UIAlertAction 
					actionWithTitle:@"Nope"
					style:UIAlertActionStyleCancel
					handler:nil];

	UIAlertAction *okAction = [UIAlertAction 
					actionWithTitle:@"YUP RESPRING"
					style:UIAlertActionStyleDefault
					handler:^(UIAlertAction *action)
					{
						system("killall -9 SpringBoard");
					}];

	[alertController addAction:cancelAction];
	[alertController addAction:okAction];
	[[%c(SBIconController) sharedInstance] presentViewController:alertController animated:YES completion:nil];
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

// Okay, this may look crazy, but without preventing closeFolderAnimated, a 3D touch will close the folder
- (void)closeFolderAnimated:(_Bool)arg1 {
	
}

//In order to still being able to close the folder with the home button:
- (void)handleHomeButtonTap {
	if ([self hasOpenFolder]) {
		SBFolder* folder = [self openFolder];
		[[%c(SBIconController) sharedInstance] _closeFolderController:folder animated:YES withCompletion:nil]; 
	} else {
		%orig;
	}
}

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

- (void)setIcon:(SBIcon*)icon {
	
	%orig;
	
	if (self.isFolderIconView && enabled) { 

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

	SBFolder * folder = ((SBIconView *)self).icon.folder;

	//Check if it is called with an open 3D touch shortcut menu , which has an class of a 'plain' SBIconView
	if(![self isKindOfClass:%c(SBFolderIconView)]) {
		SBApplicationShortcutMenu *shortcutView = [[%c(SBIconController) sharedInstance] presentedShortcutMenu];
		[shortcutView removeFromSuperview];
		[folder openFirstApp]; //TODO: fix weird bug. Now we need to open the app once tapped even if the singleTapMethod is set to open the folder in order to prevent 'lock' springboard
		return;
	}

	switch (method) {
		case 1: {
			[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //open folder
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


%ctor{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)loadPreferences,
		CFSTR("nl.jessevandervelden.swipyfoldersprefs/prefsChanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
	loadPreferences();

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)respring,
		CFSTR("nl.jessevandervelden.swipyfoldersprefs/respring"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
}
