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
	if(enabled && forceTouchMethod == 1) {

	} else {
		%orig;
	}
}

//In order to still being able to close the folder with the home button:
- (void)handleHomeButtonTap {
	if ([self hasOpenFolder] && enabled && forceTouchMethod == 1) {
		%orig;
		[[%c(SBIconController) sharedInstance] closeFolderAnimated:YES withCompletion:nil]; 
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
	firstIcon = [folder iconAtIndexPath:[NSIndexPath indexPathForRow:folder.getFirstAppIconIndex inSection:0]];
	if (!self.isEditing && iconView.isFolderIconView && forceTouchMethod != 0 && firstIcon && enabled) {
		switch (recognizer.state) {
			case UIGestureRecognizerStateBegan: {

				[iconView cancelLongPressTimer];
				[iconView sf_method:forceTouchMethod withForceTouch:YES];

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

		iconView.highlighted = NO;
	} else {
		%orig;
	}
}

- (void)iconTapped:(SBIconView *)iconView {
	if (!self.isEditing && iconView.isFolderIconView && enabled) {
		if(doubleTapMethod == 0) {
			[iconView sf_method:singleTapMethod withForceTouch:NO];
			iconView.highlighted = NO;
			return;
		} else {
			NSDate *nowTime = [[NSDate date] retain];
			if (iconView == tappedIcon) {
				if ([nowTime timeIntervalSinceDate:lastTappedTime] < doubleTapTime) {
					doubleTapRecognized = YES;
					[iconView sf_method:doubleTapMethod withForceTouch:NO];
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
					[iconView sf_method:singleTapMethod withForceTouch:NO];
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


%hook SBIconView

%new - (BOOL)isFolderIconView {
	return self.icon.isFolderIcon && !([self.icon respondsToSelector:@selector(isNewsstandIcon)] && self.icon.isNewsstandIcon);
}

- (void)setIcon:(SBIcon*)icon {
	
	%orig;
	
	//SBIconController* iconController = [%c(SBIconController) sharedInstance];

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

- (void)setIsEditing:(_Bool)editing animated:(_Bool)arg2 {

	%orig;

	//Maybe a check that we're only disabeling our own gesture recognizers?

	if(editing && self.isFolderIconView) {
		for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
			recognizer.enabled = NO;
		}
	} else  if (!editing && self.isFolderIconView) {
		for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
			recognizer.enabled = YES;
		}
	}

}

%new - (void)sf_shortHold:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state == UIGestureRecognizerStateBegan) {
		[self sf_method:shortHoldMethod withForceTouch:NO];
	}
}

%new - (void)sf_swipeUp:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:swipeUpMethod withForceTouch:NO];
}

%new - (void)sf_swipeDown:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:swipeDownMethod withForceTouch:NO];
}


%new - (void)sf_method:(NSInteger)method withForceTouch:(BOOL)forceTouch{
	SBFolder * folder = ((SBIconView *)self).icon.folder;
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	if(enabled && !iconController.isEditing && ![self isKindOfClass:%c(SBFolderIconView)])) {

		if([iconController respondsToSelector:@selector(presentedShortcutMenu)]) {
			if(iconController.presentedShortcutMenu) [iconController.presentedShortcutMenu removeFromSuperview];
		}
		switch (method) {
			case 1: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //Open Folder
				if(forceTouch) self.highlighted = NO;
			}break;

			case 2: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[folder openAppAtIndex:0];
			}break;

			case 3: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[folder openAppAtIndex:1];
			}break;

			case 4: {
				if([iconController respondsToSelector:@selector(presentedShortcutMenu)]) {
					firstIcon = [folder iconAtIndexPath:[NSIndexPath indexPathForRow:folder.getFirstAppIconIndex inSection:0]];

					iconController.presentedShortcutMenu = [[%c(SBApplicationShortcutMenu) alloc] initWithFrame:[UIScreen mainScreen].bounds application:firstIcon.application iconView:self interactionProgress:nil orientation:1];
					iconController.presentedShortcutMenu.applicationShortcutMenuDelegate = iconController;
					UIViewController *rootView = [[UIApplication sharedApplication].keyWindow rootViewController];
					[rootView.view addSubview:iconController.presentedShortcutMenu];
					[iconController.presentedShortcutMenu presentAnimated:YES];
					[iconController applicationShortcutMenuDidPresent:iconController.presentedShortcutMenu];
				}
			}break;

			default: 
			break;
		}
	}
}

//To disable Spotlight view from showing up, if user swipe down on the icon && beter swiping up support if it is set to open Shortcutview to prevent moving SpringBoard:
%new - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	if(!enabled) return YES;

	BOOL conflictGesture = NO;

	NSArray *targets = MSHookIvar<NSMutableArray *>(otherGestureRecognizer, "_targets");
	for(UIGestureRecognizerTarget *_target in targets) {
		id target = MSHookIvar<id>(_target, "_target");
		if(swipeDownMethod && [target isKindOfClass:%c(SBSearchScrollView)]) {
			otherGestureRecognizer.enabled = NO;
		}
		if(swipeUpMethod == 4 && [target isKindOfClass:%c(SBIconScrollView)]) {
			conflictGesture = YES;
			break;
		}
	}

	return !conflictGesture;

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

//For the stupids who want nested folder support. I should get paid for it ;(
%new - (int)getFirstAppIconIndex {
	SBIconIndexMutableList *iconList = MSHookIvar<SBIconIndexMutableList *>(self, "_lists");
	long long maxIconCountInList = MSHookIvar<long long>(self, "_maxIconCountInLists");

	int i = 0;
	while(i <= (iconList.count * maxIconCountInList)) { 
		SBIcon *icon = [self iconAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		if(![icon isKindOfClass:%c(SBFolderIcon)]){
			return i;
			break;
		}
		i++;
	}

	return i;

}

%new - (void)openAppAtIndex:(int)index {
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	if (!iconController.isEditing && !iconController.hasOpenFolder) { 
		SBIcon *icon = [self iconAtIndexPath:[NSIndexPath indexPathForRow:[self getFirstAppIconIndex]+index inSection:0]];
		[icon openApp];
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