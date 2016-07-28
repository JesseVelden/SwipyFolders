#import "SwipyFolders.h"

static NSUserDefaults *preferences;
static bool enabled;
static bool enableFolderPreview;
static bool hideGreyFolderBackground;
static bool closeFolderOnOpen;
static bool longHoldInvokesEditMode;
static NSInteger singleTapMethod;
static NSInteger swipeUpMethod;
static NSInteger swipeDownMethod;
static NSInteger doubleTapMethod;
static NSInteger shortHoldMethod;
static CGFloat shortHoldTime;
static CGFloat doubleTapTime;
static NSInteger forceTouchMethod;

static NSInteger singleTapMethodCustomAppIndex;
static NSInteger swipeUpMethodCustomAppIndex;
static NSInteger swipeDownMethodCustomAppIndex;
static NSInteger doubleTapMethodCustomAppIndex;
static NSInteger shortHoldMethodCustomAppIndex;
static NSInteger forceTouchMethodCustomAppIndex;


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
		@"longHoldInvokesEditMode": @NO,
		@"singleTapMethod": [NSNumber numberWithInteger:2],
		@"swipeUpMethod": 	[NSNumber numberWithInteger:1],
		@"swipeDownMethod": [NSNumber numberWithInteger:0],
		@"doubleTapMethod": [NSNumber numberWithInteger:0],
		@"doubleTapTime": [NSNumber numberWithFloat:0.2],
		@"shortHoldMethod": [NSNumber numberWithInteger:0],
		@"shortHoldTime": 	[NSNumber numberWithFloat:0.2],
		@"forceTouchMethod": [NSNumber numberWithInteger:4],

		@"singleTapMethodCustomAppIndex": [NSNumber numberWithInteger:3],
		@"swipeUpMethodCustomAppIndex":   [NSNumber numberWithInteger:3],
		@"swipeDownMethodCustomAppIndex": [NSNumber numberWithInteger:3],
		@"doubleTapMethodCustomAppIndex": [NSNumber numberWithInteger:3],
		@"shortHoldMethodCustomAppIndex": [NSNumber numberWithInteger:3],
		@"forceTouchMethodCustomAppIndex": [NSNumber numberWithInteger:3],
	}];
	
	enabled 				= [preferences boolForKey:@"enabled"];
	enableFolderPreview		= [preferences boolForKey:@"enableFolderPreview"];
	hideGreyFolderBackground = [preferences boolForKey:@"hideGreyFolderBackground"];
	closeFolderOnOpen		= [preferences boolForKey:@"closeFolderOnOpen"];
	longHoldInvokesEditMode	= [preferences boolForKey:@"longHoldInvokesEditMode"];
	singleTapMethod 		= [preferences integerForKey:@"singleTapMethod"];
	swipeUpMethod 			= [preferences integerForKey:@"swipeUpMethod"];
	swipeDownMethod			= [preferences integerForKey:@"swipeDownMethod"];
	doubleTapMethod 		= [preferences integerForKey:@"doubleTapMethod"];
	doubleTapTime	 		= [preferences floatForKey:@"doubleTapTime"];
	shortHoldMethod 		= [preferences integerForKey:@"shortHoldMethod"];
	shortHoldTime 			= [preferences floatForKey:@"shortHoldTime"];
	forceTouchMethod 		= [preferences integerForKey:@"forceTouchMethod"];

	singleTapMethodCustomAppIndex 	= [preferences integerForKey:@"singleTapMethodCustomAppIndex"];
	swipeUpMethodCustomAppIndex 	= 	[preferences integerForKey:@"swipeUpMethodCustomAppIndex"];
	swipeDownMethodCustomAppIndex 	= [preferences integerForKey:@"swipeDownMethodCustomAppIndex"];
	doubleTapMethodCustomAppIndex 	= [preferences integerForKey:@"doubleTapMethodCustomAppIndex"];
	shortHoldMethodCustomAppIndex 	= [preferences integerForKey:@"shortHoldMethodCustomAppIndex"];
	forceTouchMethodCustomAppIndex 	= [preferences integerForKey:@"forceTouchMethodCustomAppIndex"];

	[preferences release];
	if(enabled) {
		swipeUp.enabled 	= (swipeUpMethod != 0) ? YES : NO;
		swipeDown.enabled 	= (swipeDownMethod != 0) ? YES : NO;
		shortHold.enabled 	= (shortHoldMethod != 0 && !longHoldInvokesEditMode) ? YES : NO;
	}
}
/*
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
	/*
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Respring - SwipyFolders" 
						  message:@"In order to change the folder preview, a respring is required. Want to respring now?" 
						  delegate:[%c(SBIconController) sharedInstance]
						  cancelButtonTitle:@"Nope" 
						  otherButtonTitles:@"YUP RESPRING", nil];

	[alert show];
}
*/

%hook SBIconGridImage
+ (struct CGRect)rectAtIndex:(NSUInteger)index maxCount:(NSUInteger)count{
	if (enableFolderPreview && enabled) {

		CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54; 
		//Full size is 60.
		return CGRectMake(iconSize / 2, iconSize, 1, 1); //Basically hide it
	}
	return %orig;
}
/*
+ (struct CGSize)cellSize{
	//NSLog(@"SwipyFolders: %@", NSStringFromCGSize(%orig)); See log files with 'onDeviceConsole'
	if(hideGreyFolderBackground && enabled) {
		return CGSizeMake(18, 18);
	}
	return %orig;

}
*/
%end

%hook SBFolderIconView
static UIImageView *customImageView;


- (UIView *)initWithFrame:(struct CGRect)frame{
    UIView *view = %orig;
    
    CGSize size = [%c(SBIconView) defaultIconImageSize];
    CGRect iconFrame = CGRectMake(-1, -1, size.width, size.height);
    if(!hideGreyFolderBackground) {
    	iconFrame = CGRectMake(7.5, 7.5, 45, 45); //Full size is 60
    }
    self.customImageView = [[UIImageView alloc] initWithFrame:iconFrame];
    self.customImageView.backgroundColor = [UIColor clearColor];
    view.backgroundColor = [UIColor clearColor];

    [view insertSubview:self.customImageView atIndex:0];
    
    return view;
}

- (void)dealloc{
    [self.customImageView release];
    %orig;
}

- (void)setIcon:(SBIcon *)icon {
	%orig;

	if(enabled && enableFolderPreview) [self setCustomFolderIcon];
}

- (void)_applyEditingStateAnimated:(_Bool)arg1 { //Update folder icon when done editing
	%orig;
	if(enabled && enableFolderPreview) [self setCustomFolderIcon];
}

%new - (void)setCustomFolderIcon {
	SBFolder *folder = self.icon.folder;
	SBIcon *firstIcon = [folder iconAtIndexPath:[folder getFolderIndexPathForIndex:[folder getFirstAppIconIndex]]];

	self.customImageView.image = [firstIcon getIconImage:2];
	[self bringSubviewToFront:self.customImageView];

	if(hideGreyFolderBackground) MSHookIvar<UIView *>([self _folderIconImageView], "_backgroundView").hidden = YES;
}



%new(@@:) - (UIImageView *)customImageView {
    return objc_getAssociatedObject(self, &customImageView);
}

%new(v@:@) - (void)setCustomImageView:(UIImageView *)imageView {
    objc_setAssociatedObject(self, &customImageView, imageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


%end

static SBIcon *firstIcon;
static SBIconView *tappedIcon;
static NSDate *lastTouchedTime;
static NSDate *lastTappedTime;
static BOOL doubleTapRecognized;
static BOOL forceTouchRecognized;
static BOOL shortcutMenuOpen = NO;


%hook SBLockScreenManager

- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
		//[[%c(SBAppStatusBarManager) sharedInstance] showStatusBar];
		SBApplication *frontApp = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
		if(!frontApp){
			if([[%c(SBAppStatusBarManager) sharedInstance] respondsToSelector:@selector(showStatusBar)]) {
				[[%c(SBAppStatusBarManager) sharedInstance] showStatusBar];
			}
		}

	});	
	 %orig;
}
	

%end


%hook SBIconController

/*
%new - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView firstOtherButtonIndex]) {
		system("killall -9 SpringBoard");
	}
}
*/

//- (void)folderControllerShouldClose:(id)arg1; //9.3 not needed
// Okay, this may look crazy, but without preventing closeFolderAnimated, a 3D touch will close the folder
- (void)closeFolderAnimated:(_Bool)arg1 {
	if(enabled && forceTouchMethod == 1) {

	} else {
		%orig;
	}
}

//Set the status bar back when switching back to the home screen, because it was magically removed by some higher power :P //9.0-9.1
- (void)unscatterAnimated:(_Bool)arg1 afterDelay:(double)arg2 withCompletion:(id)arg3 {
	%orig;
	if([[%c(SBAppStatusBarManager) sharedInstance] respondsToSelector:@selector(showStatusBar)]) {
		[[%c(SBAppStatusBarManager) sharedInstance] showStatusBar];
	}
}

-(void)_lockScreenUIWillLock:(id)arg1{
	%orig;
	if([[%c(SBAppStatusBarManager) sharedInstance] respondsToSelector:@selector(showStatusBar)]) {
		[[%c(SBAppStatusBarManager) sharedInstance] showStatusBar];
	}
}

//In order to still being able to close the folder with the home button:
- (void)handleHomeButtonTap {
	%orig;
	if ([self hasOpenFolder] && enabled && forceTouchMethod == 1) { //9.0/9.1
		if([[%c(SBIconController) sharedInstance] respondsToSelector:@selector(closeFolderAnimated:withCompletion:)]) {
			[[%c(SBIconController) sharedInstance] closeFolderAnimated:YES withCompletion:nil]; 
		}
	}
	if([[%c(SBAppStatusBarManager) sharedInstance] respondsToSelector:@selector(showStatusBar)]) {
		[[%c(SBAppStatusBarManager) sharedInstance] showStatusBar];
	}
}

//Finally the real deal:
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
				[iconView sf_method:forceTouchMethod withForceTouch:YES customAppIndex:forceTouchMethodCustomAppIndex];
				forceTouchRecognized = YES;

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

- (void) iconHandleLongPress:(SBIconView *)iconView {
	lastTouchedTime = nil;
	%orig;
}

- (void) iconTouchBegan:(SBIconView *)iconView {
	lastTouchedTime = [[NSDate date] retain];
	%orig;
}

- (void)iconTapped:(SBIconView *)iconView {
	if (!self.isEditing && iconView.isFolderIconView && !forceTouchRecognized && enabled) {
			NSDate *nowTime = [[NSDate date] retain];
			if (!forceTouchRecognized && shortHoldMethod != 0 && longHoldInvokesEditMode && lastTouchedTime && [nowTime timeIntervalSinceDate:lastTouchedTime] >= shortHoldTime) {
				[iconView sf_method:shortHoldMethod withForceTouch:NO customAppIndex:shortHoldMethodCustomAppIndex];
				lastTouchedTime = nil;
				
				return;
			} else if(!forceTouchRecognized && doubleTapMethod != 0) {
				if (iconView == tappedIcon) {
					if (doubleTapMethod != 0 && [nowTime timeIntervalSinceDate:lastTappedTime] < doubleTapTime) {
						doubleTapRecognized = YES;
						[iconView sf_method:doubleTapMethod withForceTouch:NO customAppIndex:doubleTapMethodCustomAppIndex];
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
						[iconView sf_method:singleTapMethod withForceTouch:NO customAppIndex:singleTapMethodCustomAppIndex];
					}
				});	
			} else {
				[iconView sf_method:singleTapMethod withForceTouch:NO customAppIndex:singleTapMethodCustomAppIndex];
				iconView.highlighted = NO;
				return;
			}
	} else {
		if(self.hasOpenFolder && !iconView.isFolderIconView && closeFolderOnOpen && enabled) {
			[iconView.icon openApp];
			[self closeFolderAnimated:NO withCompletion:nil]; 
		}
		
		%orig;
	}
	forceTouchRecognized = NO;
}

- (void)applicationShortcutMenuDidDismiss:(id)arg1{
	shortcutMenuOpen = NO;
	%orig;
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
		
		if(!longHoldInvokesEditMode) {
			shortHold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sf_shortHold:)];
			shortHold.minimumPressDuration = shortHoldTime;
			shortHold.enabled = NO;
			[self addGestureRecognizer:shortHold];
		}

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
		[self sf_method:shortHoldMethod withForceTouch:NO customAppIndex:shortHoldMethodCustomAppIndex];
	}
}

%new - (void)sf_swipeUp:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:swipeUpMethod withForceTouch:NO customAppIndex:swipeUpMethodCustomAppIndex];
}

%new - (void)sf_swipeDown:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:swipeDownMethod withForceTouch:NO customAppIndex:swipeDownMethodCustomAppIndex];
}


%new - (void)sf_method:(NSInteger)method withForceTouch:(BOOL)forceTouch customAppIndex:(NSInteger)customAppIndex{
	SBFolder * folder = ((SBIconView *)self).icon.folder;
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	if(enabled && !iconController.isEditing) {

		if([iconController respondsToSelector:@selector(presentedShortcutMenu)]) {
			if(iconController.presentedShortcutMenu) [iconController.presentedShortcutMenu removeFromSuperview];
		}
		switch (method) {
			case 1: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];

				SBFolderIconView *folderIconView = (SBFolderIconView*)self;
				[folderIconView sendSubviewToBack:folderIconView.customImageView];

				[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //Open Folder

				if(forceTouch) self.highlighted = NO;

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
					[folderIconView bringSubviewToFront:folderIconView.customImageView];
				});	

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
					if(!shortcutMenuOpen) {
						firstIcon = [folder iconAtIndexPath:[NSIndexPath indexPathForRow:folder.getFirstAppIconIndex inSection:0]];
						iconController.presentedShortcutMenu = [[%c(SBApplicationShortcutMenu) alloc] initWithFrame:[UIScreen mainScreen].bounds application:firstIcon.application iconView:self interactionProgress:nil orientation:1];
						iconController.presentedShortcutMenu.applicationShortcutMenuDelegate = iconController;

						UIViewController *rootView = [[UIApplication sharedApplication].keyWindow rootViewController];
						[rootView.view addSubview:iconController.presentedShortcutMenu];
						[iconController.presentedShortcutMenu presentAnimated:YES];
						[iconController applicationShortcutMenuDidPresent:iconController.presentedShortcutMenu];
						if([[%c(SBAppStatusBarManager) sharedInstance] respondsToSelector:@selector(showStatusBar)]) {
							[[%c(SBAppStatusBarManager) sharedInstance] showStatusBar];
						}
						shortcutMenuOpen = YES;
					} else {
						shortcutMenuOpen = NO;
						[iconController _dismissShortcutMenuAnimated:YES completionHandler:nil];
					}

	
				}
			}break;

			case 5: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[folder openAppAtIndex: customAppIndex-1];
			}break;

			case 6: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[folder openLastApp];
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
			otherGestureRecognizer.enabled = NO;
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

	if([[%c(SBAppStatusBarManager) sharedInstance] respondsToSelector:@selector(showStatusBar)]) {
		[[%c(SBAppStatusBarManager) sharedInstance] showStatusBar];
	}
	
}

%end

%hook SBFolder

%new - (NSIndexPath*)getFolderIndexPathForIndex:(int)index { //The beauty of long method names :P
	long long maxIconCountInList = MSHookIvar<long long>(self, "_maxIconCountInLists");
	int indexInList = index % maxIconCountInList;
	int section = floor(index/maxIconCountInList);
	return [NSIndexPath indexPathForRow:indexInList inSection:section];
}

//For the stupids who want nested folder support. I should get paid for it ;(
%new - (int)getFirstAppIconIndex {
	SBIconIndexMutableList *iconList = MSHookIvar<SBIconIndexMutableList *>(self, "_lists");
	long long maxIconCountInList = MSHookIvar<long long>(self, "_maxIconCountInLists"); //9

	int i = 0;
	while(i <= (iconList.count * maxIconCountInList)) { 
		NSIndexPath *indexPath = [self getFolderIndexPathForIndex:i];
		SBIcon *icon = [self iconAtIndexPath:indexPath];
		if(icon.displayName != nil && ![icon isKindOfClass:%c(SBFolderIcon)]){
			return i;
			break;
		}
		i++;
	}
	return i;

}

%new - (void)openLastApp {
	SBIconIndexMutableList *iconList = MSHookIvar<SBIconIndexMutableList *>(self, "_lists");
	long long maxIconCountInList = MSHookIvar<long long>(self, "_maxIconCountInLists"); //9

	int i = (iconList.count * maxIconCountInList) - maxIconCountInList; //Begin at the last page index
	NSIndexPath *indexPath = [self getFolderIndexPathForIndex:0];

	while(i <= (maxIconCountInList * iconList.count)) { 
		SBIcon *icon = [self iconAtIndexPath: [self getFolderIndexPathForIndex:i]];

		if(icon.displayName != nil && ![icon isKindOfClass:%c(SBFolderIcon)]){
			indexPath = [self getFolderIndexPathForIndex:i];
		} 
		i++;
	}

	[[self iconAtIndexPath:indexPath] openApp];

}

%new - (void)openAppAtIndex:(int)index {
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	
	if (!iconController.isEditing) { 

		SBIconIndexMutableList *iconList = MSHookIvar<SBIconIndexMutableList *>(self, "_lists");
		long long maxIconCountInList = MSHookIvar<long long>(self, "_maxIconCountInLists"); //9
		int i = [self getFirstAppIconIndex]+index;

		while (i <= (maxIconCountInList * iconList.count)) {
			NSIndexPath *indexPath = [self getFolderIndexPathForIndex:i];
			SBIcon *icon = [self iconAtIndexPath:indexPath];
			if(icon.displayName != nil && ![icon isKindOfClass:%c(SBFolderIcon)]){
				[icon openApp];
				break;
			}
			i++;
		}

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
} 