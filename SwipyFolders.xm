#import "SwipyFolders.h"

static NSUserDefaults *preferences;
static bool enabled;
static bool enableFolderPreview;
static bool hideGreyFolderBackground;
static bool closeFolderOnOpen;
static NSInteger singleTapMethod;
static NSInteger swipeUpMethod;
static NSInteger swipeDownMethod;
static NSInteger doubleTapMethod;
static NSInteger shortHoldMethod;
static CGFloat shortHoldTime;
static CGFloat doubleTapTime;
static NSInteger forceTouchMethod;

static UISwipeGestureRecognizer *swipeUp;
static UISwipeGestureRecognizer *swipeDown;
static UILongPressGestureRecognizer *shortHold;


static void loadPreferences() {
	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];

	[preferences registerDefaults:@{
		@"enabled": @YES,
		@"enableFolderPreview": @YES,
		@"hideGreyFolderBackground": @NO,
		@"closeFolderOnOpen": @YES,
		@"singleTapMethod": [NSNumber numberWithInteger:2],
		@"swipeUpMethod": 	[NSNumber numberWithInteger:1],
		@"swipeDownMethod": [NSNumber numberWithInteger:0],
		@"doubleTapMethod": [NSNumber numberWithInteger:0],
		@"doubleTapTime": [NSNumber numberWithFloat:0.2],
		@"shortHoldMethod": [NSNumber numberWithInteger:0],
		@"shortHoldTime": 	[NSNumber numberWithFloat:0.325],
		@"forceTouchMethod": [NSNumber numberWithInteger:4],
	}];
	
	enabled 		= [preferences boolForKey:@"enabled"];
	enableFolderPreview	= [preferences boolForKey:@"enableFolderPreview"];
	hideGreyFolderBackground = [preferences boolForKey:@"hideGreyFolderBackground"];
	closeFolderOnOpen	= [preferences boolForKey:@"closeFolderOnOpen"];
	singleTapMethod 	= [preferences integerForKey:@"singleTapMethod"];
	swipeUpMethod 		= [preferences integerForKey:@"swipeUpMethod"];
	swipeDownMethod		= [preferences integerForKey:@"swipeDownMethod"];
	doubleTapMethod 	= [preferences integerForKey:@"doubleTapMethod"];
	doubleTapTime	 	= [preferences floatForKey:@"doubleTapTime"];
	shortHoldMethod 	= [preferences integerForKey:@"shortHoldMethod"];
	shortHoldTime 		= [preferences floatForKey:@"shortHoldTime"];
	forceTouchMethod 	= [preferences integerForKey:@"forceTouchMethod"];

	[preferences release];
	if(enabled) {
		swipeUp.enabled 	= (swipeUpMethod != 0) ? YES : NO;
		swipeDown.enabled 	= (swipeDownMethod != 0) ? YES : NO;
		shortHold.enabled 	= (shortHoldMethod != 0) ? YES : NO;
	}
}

static void respring() {
	/* For iOS 10 when old alertview will be deprecated:
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
	*/
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Respring - SwipyFolders" 
						  message:@"In order to change the folder preview, a respring is required. Want to respring now?" 
						  delegate:[%c(SBIconController) sharedInstance]
						  cancelButtonTitle:@"Nope" 
						  otherButtonTitles:@"YUP RESPRING", nil];

	[alert show];
}


%hook SBIconGridImage
+ (struct CGRect)rectAtIndex:(NSUInteger)index maxCount:(NSUInteger)count{
	if (enableFolderPreview && enabled) {
		
		CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54; 
		//Full size is 60.
		if(hideGreyFolderBackground) {
			iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 60 : 69; //TEST ON IPAD!!!
		}
		if (index == 0) {
			return CGRectMake(0, 0, iconSize, iconSize);
		} else {
			return CGRectMake(iconSize / 2, iconSize, 1, 1);
		}
	}
	return %orig;
}
+ (struct CGSize)cellSize{
	//NSLog(@"SwipyFolders: %@", NSStringFromCGSize(%orig)); See log files with 'onDeviceConsole'
	if(hideGreyFolderBackground && enabled) {
		return CGSizeMake(18, 18);
	}
	return %orig;

}
/*+ (struct CGSize)cellSpacing {
	//NSLog(@"SwipyFolders: %@", NSStringFromCGSize(%orig));  //3x3
	return %orig;
}*/
%end

%hook SBFolderIconView

- (void)setIcon:(SBIcon *)icon {
	%orig;
	if(hideGreyFolderBackground && enabled) {
		MSHookIvar<UIView *>([self _folderIconImageView], "_backgroundView").hidden = YES;
	}
}

%end

static SBIcon *firstIcon;
static SBIconView *tappedIcon;
static NSDate *lastTappedTime;
static BOOL doubleTapRecognized;

%hook SBIconController

%new - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView firstOtherButtonIndex]) {
		system("killall -9 SpringBoard");
	}
}

// Okay, this may look crazy, but without preventing closeFolderAnimated, a 3D touch will close the folder
- (void)closeFolderAnimated:(_Bool)arg1 {
	
}

//In order to still being able to close the folder with the home button:
- (void)handleHomeButtonTap {
	if ([self hasOpenFolder]) {
		[[%c(SBIconController) sharedInstance] closeFolderAnimated:YES withCompletion:nil]; 
		//iconView.highlighted = NO;
	} else {
		%orig;
	}
}

- (void)_handleShortcutMenuPeek:(UILongPressGestureRecognizer *)recognizer {
	SBIconView *iconView = (SBIconView*)recognizer.view;
	firstIcon = nil;
	if(!iconView.isFolderIconView) {
		%orig;
		return;
	}

	SBFolder* folder = ((SBFolderIconView *)iconView).folderIcon.folder;
	firstIcon = [folder iconAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	if (iconView.isFolderIconView && firstIcon && enabled) {
		switch (recognizer.state) {
			case UIGestureRecognizerStateBegan: {
				[iconView cancelLongPressTimer];
				if(forceTouchMethod != 0) {
					if(forceTouchMethod != 0)
					switch (forceTouchMethod) {
						case 1: {
							[[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
							[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //Open Folder
							iconView.highlighted = NO;
						}break;

						case 2: {
							[[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
							[folder openFirstApp];
						}break;

						case 3: {
							[[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
							[folder openSecondApp];
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

				return; //Prevent twice times the folder opening animation

			}break;
			default:
			break;

		}

		iconView.highlighted = NO;
	} else {
		%orig;
	}
}

- (void)iconTapped:(SBIconView *)iconView {
	if (!self.isEditing && !self.hasOpenFolder && iconView.isFolderIconView && enabled) {
		if(doubleTapMethod == 0) {
			[iconView sf_method:singleTapMethod];
			iconView.highlighted = NO;
			return;
		} else {
			NSDate *nowTime = [[NSDate date] retain];
			if (iconView == tappedIcon) {
				if ([nowTime timeIntervalSinceDate:lastTappedTime] < doubleTapTime) {
					doubleTapRecognized = YES;
					[iconView sf_method:doubleTapMethod];
					lastTappedTime = 0;
					iconView.highlighted = NO;
					return;
				}
			}
			tappedIcon = iconView;
			lastTappedTime = nowTime;
			doubleTapRecognized = NO;
			iconView.highlighted = NO;

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(doubleTapTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
				if (!doubleTapRecognized && iconView == tappedIcon) {
					[iconView sf_method:singleTapMethod];
				}
			});	
			return;		
		}
	} else {
		if(self.hasOpenFolder && !iconView.isFolderIconView && closeFolderOnOpen && enabled) {
			[iconView.icon openApp];
			[self closeFolderAnimated:NO withCompletion:nil]; 
		}
		%orig;
	}
}

%end

%hook SBApplicationShortcutMenu
- (id)_shortcutItemsToDisplay {
	
	//If it is a folder:
	if (self.application == nil && enabled && forceTouchMethod != 0) { //&& (forceTouchMethod == 4 || swipeUpMethod == 4 || singleTapMethod == 4 || doubleTapMethod == 4 ||shortHoldMethod == 4)
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

- (void)setIcon:(SBIcon*)icon {
	
	%orig;
	
	if (self.isFolderIconView) {
		
		swipeUp = [[%c(UISwipeGestureRecognizer) alloc] initWithTarget:self action:@selector(sf_swipeUp:)];
		swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
		swipeUp.delegate = (id <UIGestureRecognizerDelegate>)self;
		[self addGestureRecognizer:swipeUp];
		
		swipeDown = [[%c(UISwipeGestureRecognizer) alloc] initWithTarget:self action:@selector(sf_swipeDown:)];
		swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
		swipeDown.delegate = (id <UIGestureRecognizerDelegate>)self;
		[self addGestureRecognizer:swipeDown];
		
		shortHold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sf_shortHold:)];
		shortHold.minimumPressDuration = shortHoldTime;
		[self addGestureRecognizer:shortHold];
	}
}

%new - (void)sf_shortHold:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state == UIGestureRecognizerStateBegan) {
		[self sf_method:shortHoldMethod];
	}
}

%new - (void)sf_swipeUp:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:swipeUpMethod];
}

%new - (void)sf_swipeDown:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:swipeDownMethod];
}


%new - (void)sf_method:(NSInteger)method {

	SBFolder * folder = ((SBIconView *)self).icon.folder;
	SBIconController* iconController = [%c(SBIconController) sharedInstance];

	//Check if it is called with an open 3D touch shortcut menu , which has an class of a 'plain' SBIconView
	if(![self isKindOfClass:%c(SBFolderIconView)]) {
		SBApplicationShortcutMenu *shortcutView = iconController.presentedShortcutMenu;
		[shortcutView removeFromSuperview];
		[folder openFirstApp]; //TODO: fix weird bug. Now we need to open the app once tapped even if the singleTapMethod is set to open the folder in order to prevent 'lock' springboard
		return;
	}

	if(enabled) {
		if(!iconController.isEditing && !iconController.hasOpenFolder) {
			switch (method) {
				case 1: {
					[iconController openFolder:folder animated:YES]; //open folder
				}break;
				case 2: {
					[folder openFirstApp];
				}break;

				case 3: {
					[folder openSecondApp];
				}break;

				case 4: {
					firstIcon = [folder iconAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
					SBApplicationShortcutMenu *shortcutView = iconController.presentedShortcutMenu;
					[shortcutView release];
					[shortcutView removeFromSuperview];

					iconController.presentedShortcutMenu = [[%c(SBApplicationShortcutMenu) alloc] initWithFrame:[UIScreen mainScreen].bounds application:firstIcon.application iconView:self interactionProgress:nil orientation:1];
					iconController.presentedShortcutMenu.applicationShortcutMenuDelegate = iconController;
					UIViewController *rootView = [[UIApplication sharedApplication].keyWindow rootViewController];
					[rootView.view addSubview:iconController.presentedShortcutMenu];
					[iconController.presentedShortcutMenu presentAnimated:YES];
					[iconController applicationShortcutMenuDidPresent:iconController.presentedShortcutMenu];

				}

				default:
				break;
			}
		} else {
			//[iconController openFolder:folder animated:YES]; //open folder
		}
	}		
}

//To disable Spotlight view from showing up, if user swipe down on the icon:
%new - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIScrollViewPanGestureRecognizer *)otherGestureRecognizer {
	
	if([otherGestureRecognizer isKindOfClass:%c(UIScrollViewPanGestureRecognizer)] && swipeDownMethod != 0 && enabled) {
		NSMutableArray *targets = [otherGestureRecognizer valueForKeyPath:@"_targets"];
		id targetContainer = targets[0];
		id targetOfOtherGestureRecognizer = [targetContainer valueForKeyPath:@"_target"];

		if([targetOfOtherGestureRecognizer isKindOfClass:%c(SBSearchScrollView)]) {
			otherGestureRecognizer.enabled = NO;
		}
	}

	return YES; 
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

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)respring,
		CFSTR("nl.jessevandervelden.swipyfoldersprefs/respring"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);

	loadPreferences();
}
