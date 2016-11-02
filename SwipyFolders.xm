#import "SwipyFolders.h"


/**
 * The preferences
 *	
 */

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

static NSInteger nestedFolderBehaviour;

static UISwipeGestureRecognizer *swipeUp;
static UISwipeGestureRecognizer *swipeDown;
static UILongPressGestureRecognizer *shortHold;

static NSDictionary *customFolderSettings;

static bool classicFoldersEnabled;

#define HAS_BIOPROTECT (%c(BioProtectController) != nil) 

static void loadPreferences() {
	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];

	classicFoldersEnabled = NO;
	if([NSFileManager.defaultManager fileExistsAtPath:@"/private/var/mobile/Library/Preferences/org.coolstar.classicfolders.plist"] && [NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ClassicFolders.dylib"]) {
		NSUserDefaults *classicFolderPreferences = [[NSUserDefaults alloc] initWithSuiteName:@"org.coolstar.classicfolders"];
		classicFoldersEnabled = ([classicFolderPreferences boolForKey:@"enabled"]) ? YES : NO;
	}

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

		@"nestedFolderBehaviour": [NSNumber numberWithInteger:0],
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
	swipeUpMethodCustomAppIndex 	= [preferences integerForKey:@"swipeUpMethodCustomAppIndex"];
	swipeDownMethodCustomAppIndex 	= [preferences integerForKey:@"swipeDownMethodCustomAppIndex"];
	doubleTapMethodCustomAppIndex 	= [preferences integerForKey:@"doubleTapMethodCustomAppIndex"];
	shortHoldMethodCustomAppIndex 	= [preferences integerForKey:@"shortHoldMethodCustomAppIndex"];
	forceTouchMethodCustomAppIndex 	= [preferences integerForKey:@"forceTouchMethodCustomAppIndex"];

	nestedFolderBehaviour 	= [preferences integerForKey:@"nestedFolderBehaviour"];

	customFolderSettings = [preferences dictionaryForKey:@"customFolderSettings"];

	[preferences release];
	if(enabled) {
		swipeUp.enabled 	= (swipeUpMethod != 0) ? YES : NO;
		swipeDown.enabled 	= (swipeDownMethod != 0) ? YES : NO;
		shortHold.enabled 	= (shortHoldMethod != 0 && !longHoldInvokesEditMode) ? YES : NO;
	}
}


static UIColor *colorShiftedBy(UIColor *color, CGFloat shift) {
	CGFloat red, green, blue, alpha;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	return [UIColor colorWithRed:red + shift green:green + shift blue:blue + shift alpha:alpha];
}

static void saveFolderSettings(NSDictionary *folderSettings) {
	NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
	[preferences setObject:folderSettings forKey:@"customFolderSettings"];
	[preferences synchronize];
	customFolderSettings = [folderSettings copy];
}

static void setFolderSetting(NSString *folderID, NSString *key, id setting) {
	NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	NSMutableDictionary *mutableFolderSettings = [customFolderSettings[folderID] mutableCopy];
	if(!mutableFolderSettings) mutableFolderSettings = [NSMutableDictionary new];
	if(!mutableCustomFolderSettings) mutableCustomFolderSettings = [NSMutableDictionary new];

	[mutableFolderSettings setObject:setting forKey:key];
	[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:folderID];

	saveFolderSettings(mutableCustomFolderSettings);
}



/**
 * Setting the folder preview
 *	
 */


%hook SBFolderIconImageView
static UIImageView *customImageView;


-(id)initWithFrame:(CGRect)arg1{

	//UIView *view = %orig;
	self = %orig;

	if(enabled) {
		CGSize size = [%c(SBIconView) defaultIconImageSize];
		CGRect iconFrame = CGRectMake(0, 0, size.width, size.height);
		if(!hideGreyFolderBackground) {
			CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54; 
			iconFrame = CGRectMake(7.5, 7.5, iconSize, iconSize); //Full size is 60
		}


		self.customImageView = [[UIImageView alloc] initWithFrame:iconFrame];
		self.customImageView.backgroundColor = [UIColor clearColor];

		[self insertSubview:self.customImageView atIndex:0];
	}

	return self;

}


%new(v@:@) - (void)setCustomImageView:(UIImageView *)imageView {
	objc_setAssociatedObject(self, &customImageView, imageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new(@@:) - (UIImageView *)customImageView {
	return objc_getAssociatedObject(self, &customImageView);
}

-(void)dealloc {
	[self.customImageView release];
	%orig;
}

- (void)_showLeftMinigrid{
	%orig;

	SBFolder *folder = self._folderIcon.folder;
	NSString *folderID = folder.folderID;

	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	if(iconController.isEditing && ![folder.oldFolderID isEqualToString:@""]) {
		folderID = folder.oldFolderID;
	}

	NSDictionary *folderSettings = customFolderSettings[folderID];


	if(enabled){	
		
		UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>(self, "_leftWrapperView");
		
		if((enableFolderPreview && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0 || [folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil))) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1)){
			SBIcon *firstIcon = [folder getFirstIcon];
			UIImage *firstImage = [firstIcon getIconImage:2];
						
			self.customImageView.image = firstImage;
			[self hideInnerFolderImageView: YES];

			CGSize size = [%c(SBIconView) defaultIconImageSize];
			CGRect iconFrame = CGRectMake(0, 0, size.width, size.height);
			
			if((!hideGreyFolderBackground && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderHideGreyFolderBackground"] intValue] == 1)) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1 && [folderSettings[@"customFolderHideGreyFolderBackground"] intValue] == 0)) {
				CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54; 
				iconFrame = CGRectMake(7.5, 7.5, iconSize, iconSize);
			}
				
			self.customImageView.frame = iconFrame;

			[self bringSubviewToFront:self.customImageView];

		} else {
			self.customImageView.image = nil;
			[self hideInnerFolderImageView: NO];
			[self sendSubviewToBack:self.customImageView]; //Misschien weg?
			[self bringSubviewToFront:innerFolderImageView];
					
		}

	}

}

%new -(void)hideInnerFolderImageView:(BOOL)hide {
	UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>(self, "_leftWrapperView");
	innerFolderImageView.hidden = hide;
}



%end


%hook SBFolderIconZoomAnimator

-(void)_prepareAnimation{

	%orig;

	SBFolderIconImageView *folderIconImageView  = self.targetIconView._folderIconImageView;

	if(folderIconImageView.customImageView.image != nil && !self.targetIcon.folder.open) { //Yes the last argument returns NO already


		SBFolderView *innerFolderView = MSHookIvar<SBFolderView *>(self, "_innerFolderView");
		UIView *scrollView = MSHookIvar<UIView *>(innerFolderView, "_scrollView");

		UIImageView *leftView = MSHookIvar<UIImageView *>(folderIconImageView, "_leftWrapperView");
		leftView.hidden = YES;
		UIImageView *rightView = MSHookIvar<UIImageView *>(folderIconImageView, "_rightWrapperView");
		rightView.hidden = YES;


		folderIconImageView.customImageView.hidden = NO;
		[folderIconImageView bringSubviewToFront:folderIconImageView.customImageView];

		folderIconImageView.customImageView.alpha = 0;
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5];
		[folderIconImageView.customImageView setAlpha:1.0];
		[scrollView setAlpha:0.0];
		[UIView commitAnimations];

		
	} else if(self.targetIcon.folder.open) {
		folderIconImageView.customImageView.hidden = YES;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
			folderIconImageView.customImageView.hidden = NO;
		});	
	}

	//If not calling %orig; the icons behind the screen are not removed, so cool iOS 10 gimmick?

}
%end



%hook SBFolderIconView
- (void)setIcon:(id)arg1 {
	%orig;
	self.shortcutMenuPeekGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:[%c(SBIconController) sharedInstance] action:@selector(_handleShortcutMenuPeek:)];
	self.shortcutMenuPresentProgress = [[UIPreviewForceInteractionProgress alloc] initWithGestureRecognizer:self.shortcutMenuPeekGesture];
	[self cancelLongPressTimer];
}

%end




static SBIcon *firstIcon;
static SBIconView *tappedIcon;
static NSDate *lastTouchedTime;
static NSDate *lastTappedTime;
//static NSDate *forceTouchOpenedTime;
static BOOL doubleTapRecognized;
static BOOL forceTouchRecognized;



/**
 * Methods to iterate all folders, for folder specific options in the preference pane
 *	
 */

CPDistributedMessagingCenter *messagingCenter;

%hook SBIconController

- (id)init {
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"nl.jessevandervelden.swipyfolders.center"];
		[messagingCenter runServerOnCurrentThread];
		[messagingCenter registerForMessageName:@"foldersRepresentation" target:self selector:@selector(handleMessageNamed:withUserInfo:)];
	});
	return %orig;
}

%new - (NSDictionary*)handleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userinfo { //Only going to use for sending over folders so no additional checks needed
	NSArray *folderArray = [[[self rootFolder] folderIcons] allObjects];

	NSMutableDictionary *foldersRepresentation = [NSMutableDictionary dictionary];

	for (int i=0; i<[folderArray count]; i++) {
		SBFolderIcon *folderIcon = [folderArray objectAtIndex:i];
		SBFolder *folder = folderIcon.folder;

		//NSString *defaultDisplayName = MSHookIvar<NSString*>(folder, "defaultDisplayName");
		NSArray *folderAppIcons = [folder.allIcons allObjects]; //orderedIcons iOS 9+
		NSMutableArray *applicationBundleIDs = [[NSMutableArray alloc] init];
		for(int k=0; k<[folderAppIcons count] && k<9; k++ ) {
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:k inSection:0];
			SBIcon *appIcon = (SBApplicationIcon*)[folder iconAtIndexPath:indexPath];
			if(appIcon.application.bundleIdentifier != nil){
				[applicationBundleIDs addObject:appIcon.application.bundleIdentifier];
				//SBApplicationIcon *appIcon = [folderAppIcons objectAtIndex:k];
			}else {
				SBLeafIcon *leafIcon = (SBLeafIcon*)appIcon;
				if(leafIcon.leafIdentifier != nil) {
					[applicationBundleIDs addObject:leafIcon.leafIdentifier];
				} else {
					[applicationBundleIDs addObject:@""];
				}
			} 
			
		}
		NSMutableDictionary *folderDictionary = [NSMutableDictionary dictionary];
		[folderDictionary setObject:folder.displayName forKey:@"displayName"]; // String

		[folderDictionary setObject:applicationBundleIDs forKey:@"applicationBundleIDs"]; //NSArray with bundle id strings

		NSString *folderID = folder.folderID;

		[folderDictionary setObject:folderID forKey:@"folderID"]; 
		
		[foldersRepresentation setObject:folderDictionary forKey:folderID]; //[NSString stringWithFormat:@"%d", i]

	}

	/*
	//Cleanup unused folderSettings:
	NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	for (NSString *folderID in customFolderSettings) {
		if(![folderArray containsObject:folderID]) {
			HBLogDebug(@"De folder die we gaan verwijderen: %@", folderID);
			
			[mutableCustomFolderSettings removeObjectForKey:folderID];
			
		}
	}

	NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
	[preferences setObject:[mutableCustomFolderSettings copy] forKey:@"customFolderSettings"];
	[preferences synchronize];
	customFolderSettings = [mutableCustomFolderSettings copy];
	*/

	return foldersRepresentation;
}



/**
 * Some bugfixes on pre 9.3 devices:
 *	
 */

//- (void)folderControllerShouldClose:(id)arg1; //9.3 not needed
// Okay, this may look crazy, but without preventing closeFolderAnimated, a 3D touch will close the folder
- (void)closeFolderAnimated:(_Bool)arg1 {
	if(enabled && forceTouchMethod == 1) {

	} else {
		%orig;
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
}



/**
 * Finally the real deal:
 *	
 */

//A method for 3D Touch actions
static BOOL interactionProgressDidComplete = NO;
- (void)_handleShortcutMenuPeek:(UILongPressGestureRecognizer *)recognizer {
	SBIconView *iconView = (SBIconView*)recognizer.view;

	firstIcon = nil;
	if(!iconView.isFolderIconView) {
		%orig;
		return;
	}

	SBFolderIcon *folderIcon = ((SBFolderIconView *)iconView).folderIcon;
	SBFolder* folder = folderIcon.folder;
	firstIcon = [folder getFirstIcon];
	NSDictionary *methodDict = [iconView getFolderSetting:@"ForceTouchMethod" withDefaultSetting:forceTouchMethod withDefaultCustomAppIndex:forceTouchMethodCustomAppIndex];
	NSInteger method = [methodDict[@"method"] intValue];

	if (!self.isEditing && iconView.isFolderIconView && method != 0 && firstIcon && enabled) {

		switch (recognizer.state) {
			case UIGestureRecognizerStateBegan: {
				[iconView cancelLongPressTimer];

				forceTouchRecognized = YES;
				interactionProgressDidComplete = false;
				
				self.presentedShortcutMenu = [[%c(SBApplicationShortcutMenu) alloc] initWithFrame:[UIScreen mainScreen].bounds application:firstIcon.application iconView:iconView interactionProgress:iconView.shortcutMenuPresentProgress orientation:1];
				self.presentedShortcutMenu.applicationShortcutMenuDelegate = self;
				UIViewController *rootView = [[UIApplication sharedApplication].keyWindow rootViewController];
				[rootView.view addSubview:self.presentedShortcutMenu];

				SBIconView *forceTouchIconView = MSHookIvar<SBIconView *>(self.presentedShortcutMenu, "_proxyIconView");
				SBFolderIconImageView *folderIconImageView = MSHookIvar<SBFolderIconImageView *>(forceTouchIconView, "_iconImageView");

				UIView* folderBackgroundView = MSHookIvar<UIView *>(folderIconImageView, "_backgroundView");
				SBWallpaperController *wallpaperCont = [%c(SBWallpaperController) sharedInstance];
				UIColor *dominantColor = [wallpaperCont averageColorForVariant:1];
				folderBackgroundView.backgroundColor = colorShiftedBy(dominantColor, 0.15);
				
				folderBackgroundView.alpha = 0;
				UIImageView *folderImageView = MSHookIvar<UIImageView *>(folderIconImageView, "_leftWrapperView");

				[UIView transitionWithView:folderImageView
				duration:0.5f
				options:UIViewAnimationOptionTransitionCrossDissolve
				animations:^{
					if (method == 4) folderImageView.image = [firstIcon getIconImage:2];
					folderBackgroundView.alpha = 1;
				} completion:nil];



			}break;

			case UIGestureRecognizerStateChanged: {
				[iconView cancelLongPressTimer];
				if (method == 4) [self.presentedShortcutMenu updateFromPressGestureRecognizer:recognizer];
			}break;

			case UIGestureRecognizerStateEnded: {

				if (method == 4 && self.presentedShortcutMenu.isPresented) {
					SBApplicationShortcutMenuContentView *contentView = MSHookIvar<id>(self.presentedShortcutMenu,"_contentView");
					NSMutableArray *itemViews = MSHookIvar<NSMutableArray *>(contentView,"_itemViews");
					for(SBApplicationShortcutMenuItemView *item in itemViews) {
						if (item.highlighted == YES) {
							[self.presentedShortcutMenu menuContentView:contentView activateShortcutItem:item.shortcutItem index:item.menuPosition];
							break;
						}
					}
				} else if(method != 4) {
					[self.presentedShortcutMenu dismissAnimated:true completionHandler:nil];
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

- (void)setIsEditing:(_Bool)editing {
	%orig; 
	if(editing && [self respondsToSelector:@selector(_cleanupForDismissingShortcutMenu:)]) {
		if(self.presentedShortcutMenu != nil) [self _cleanupForDismissingShortcutMenu:self.presentedShortcutMenu];
	}
}


/**
 * Methods for setting other gestures on the folder icon
 *
 */

- (void) iconHandleLongPress:(SBIconView *)iconView {
	lastTouchedTime = nil;
	%orig;
}

- (void) iconTouchBegan:(SBIconView *)iconView {
	lastTouchedTime = [[NSDate date] retain];
	%orig;
}

- (void)iconTapped:(SBIconView *)iconView {
	if (!self.isEditing && iconView.isFolderIconView && enabled) {

			NSDate *nowTime = [[NSDate date] retain];
			if  (shortHoldMethod != 0 && lastTouchedTime && [nowTime timeIntervalSinceDate:lastTouchedTime] >= shortHoldTime) {

				[iconView sf_method:[iconView getFolderSetting:@"ShortHoldMethod" withDefaultSetting:shortHoldMethod withDefaultCustomAppIndex:shortHoldMethodCustomAppIndex] withForceTouch:NO];
				lastTouchedTime = nil;
				iconView.highlighted = NO;
				return;
			} else if (doubleTapMethod != 0) {
				if (iconView == tappedIcon) {
					if (doubleTapMethod != 0 && [nowTime timeIntervalSinceDate:lastTappedTime] < doubleTapTime) {
						doubleTapRecognized = YES;

						[iconView sf_method:[iconView getFolderSetting:@"DoubleTapMethod" withDefaultSetting:doubleTapMethod withDefaultCustomAppIndex:doubleTapMethodCustomAppIndex] withForceTouch:NO];
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
						[iconView sf_method:[iconView getFolderSetting:@"SingleTapMethod" withDefaultSetting:singleTapMethod withDefaultCustomAppIndex:singleTapMethodCustomAppIndex] withForceTouch:NO];
					}
				});	
			} else {
				NSDictionary *method = [iconView getFolderSetting:@"SingleTapMethod" withDefaultSetting:singleTapMethod withDefaultCustomAppIndex:singleTapMethodCustomAppIndex];
				[iconView sf_method:method withForceTouch:NO];
				iconView.highlighted = NO;
				return;
			}
	} else {
		if(self.hasOpenFolder && !iconView.isFolderIconView && enabled) {
			[iconView.icon openAppFromFolder:self.openFolder.folderID];
			if(closeFolderOnOpen) [self closeFolderAnimated:NO withCompletion:nil]; 
		}
		
		%orig;
	}
	forceTouchRecognized = NO;
}

%end





/**
 * Protecting folders for those with BioProtect
 *
 */
static BOOL isProtected = NO;
%hook SBApplicationShortcutMenu
- (void)menuContentView:(id)arg1 activateShortcutItem:(id)arg2 index:(long long)arg3 {
	if(HAS_BIOPROTECT){
		if([self.iconView isFolderIconView]) {
			SBFolder* folder = ((SBFolderIconView *)self.iconView).folderIcon.folder;
			SBIcon *firstIcon = [folder getFirstIcon];
			NSString *bundleIdentifier = firstIcon.application.bundleIdentifier;
			if ([[%c(BioProtectController) sharedInstance ] requiresAuthenticationForIdentifier: bundleIdentifier ] && !isProtected){ 
				NSArray *arguments=[NSArray arrayWithObjects:[NSValue valueWithPointer:&arg1],[NSValue valueWithPointer:&arg2],[NSValue valueWithPointer:&arg3],NULL];
				[[%c(BioProtectController) sharedInstance] authenticateForIdentifier:bundleIdentifier object:self selector:@selector(onBioProtectSuccessWithMenuContentView:activateShortcutItem:index:) arrayOfArgumentsAsNSValuePointers:arguments];
				return;
			}
		}
	}
	isProtected = NO;
	%orig;
}

%new - (void) onBioProtectSuccessWithMenuContentView:(id)arg1 activateShortcutItem:(id)arg2 index:(long long)arg3 {
	isProtected = YES;
	[self menuContentView:arg1 activateShortcutItem:arg2 index:arg3];

}

/**
 * Some methods to let 3D Touch work on folder icons, and some animations
 *
 */
- (void)interactionProgress:(id)arg1 didEnd:(_Bool)arg2 {
	
	if (enabled && arg2 && self.iconView.isFolderIconView) {
		NSDictionary *methodDict = [self.iconView getFolderSetting:@"ForceTouchMethod" withDefaultSetting:forceTouchMethod withDefaultCustomAppIndex:forceTouchMethodCustomAppIndex];
		NSInteger method = [methodDict[@"method"] intValue];
		if(method != 4 && method != 0){
			[self dismissAnimated:false completionHandler:nil];
			[self.iconView sf_method:methodDict withForceTouch:YES];
			return;
		}
	} 

	%orig;
} 


- (void)dismissAnimated:(_Bool)arg1 completionHandler:(id)arg2{
	if(enabled && arg1 && self.iconView.isFolderIconView) {
		SBIconView *forceTouchIconView = MSHookIvar<SBIconView *>(self, "_proxyIconView");
		SBFolderIconImageView *folderIconImageView = MSHookIvar<SBFolderIconImageView *>(forceTouchIconView, "_iconImageView");
		UIImageView *folderImageView = MSHookIvar<UIImageView *>(folderIconImageView, "_leftWrapperView");
		UIView* folderBackgroundView = MSHookIvar<UIView *>(folderIconImageView, "_backgroundView");
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.3];
		[folderImageView setAlpha:0.0];
		[folderBackgroundView setAlpha:0.0];
		[UIView commitAnimations];
	}
	%orig;
}

- (void)_finishPeekingWithCompletionHandler:(id)arg1 {
	if(enabled && self.iconView.isFolderIconView) {
		SBIconView *forceTouchIconView = MSHookIvar<SBIconView *>(self, "_proxyIconView");
		SBFolderIconImageView *folderIconImageView = MSHookIvar<SBFolderIconImageView *>(forceTouchIconView, "_iconImageView");
		UIImageView *folderImageView = MSHookIvar<UIImageView *>(folderIconImageView, "_leftWrapperView");
		UIView* folderBackgroundView = MSHookIvar<UIView *>(folderIconImageView, "_backgroundView");
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5];
		[folderImageView setAlpha:0.0];
		[folderBackgroundView setAlpha:0.0];
		[UIView commitAnimations];
	}
	%orig;
}


- (id)_shortcutItemsToDisplay {
	//Sometimes the labelview of the forceTouchIconView isn't hidden, (even normal aplications) so in order to prevent that:
	SBIconView *forceTouchIconView = MSHookIvar<SBIconView *>(self, "_proxyIconView");
	forceTouchIconView.labelView.hidden = YES;

	NSMutableArray *items = %orig;
	if (enabled) {
		NSDictionary *methodDict = [self.iconView getFolderSetting:@"ForceTouchMethod" withDefaultSetting:forceTouchMethod withDefaultCustomAppIndex:forceTouchMethodCustomAppIndex];
		NSInteger method = [methodDict[@"method"] intValue];

		//In order to set blurring on forceTouch folderIcons, where the first app doesn't support Force Touch, add a fake action
		if ([items count] == 0 && self.iconView.isFolderIconView && method != 4 && method != 0) {
			SBSApplicationShortcutItem *action = [[%c(SBSApplicationShortcutItem) alloc] init];
			[action setLocalizedTitle:@"Fake Action"];

			[items addObject:action];
		}
	}
	return items;
}

%end



%hook SBIconView

/**
 * Get folder specific settings
 *
 */


%new - (BOOL)isFolderIconView {
	return self.icon.isFolderIcon && !([self.icon respondsToSelector:@selector(isNewsstandIcon)] && self.icon.isNewsstandIcon);
}

%new - (NSDictionary*)getFolderSetting:(NSString*)setting withDefaultSetting:(NSInteger)globalSetting withDefaultCustomAppIndex:(NSInteger)globalAppIndex {
	SBFolder *folder = ((SBIconView *)self).icon.folder;
	NSDictionary *folderSettings = customFolderSettings[folder.folderID];

	NSNumber *sendMethod = [NSNumber numberWithInt:globalSetting];
	NSNumber *sendAppIndex = [NSNumber numberWithInt:globalAppIndex];

	NSString *method = [NSString stringWithFormat:@"customFolder%@",setting];
	
	if([folderSettings[@"customFolderFunctionallity"] intValue] == 1){
		if([folderSettings objectForKey:method]) sendMethod = [NSNumber numberWithInt:[[folderSettings objectForKey:method] intValue]];
		if([[folderSettings objectForKey:method] intValue] == 5){
			NSString *appIndexSetting = [NSString stringWithFormat:@"customFolder%@CustomAppIndex",setting];
			sendAppIndex = [NSNumber numberWithInt:[[folderSettings objectForKey:appIndexSetting] intValue]];
		}
	}


	NSMutableDictionary *sendInfo = [NSMutableDictionary new];
	[sendInfo setObject:sendMethod forKey:@"method"];
	[sendInfo setObject:sendAppIndex forKey:@"customAppIndex"];
	if(folderSettings[@"lastOpenedApp"]) [sendInfo setObject:folderSettings[@"lastOpenedApp"] forKey:@"lastOpenedApp"];


	return sendInfo;
}

/**
 * Add the last gestures to the folder icon
 *
 */

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
		
		/* Not in settings anymore as it causes troubles when not enabled at pre-iphone 6s models
		if(!longHoldInvokesEditMode) {
			shortHold = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sf_shortHold:)];
			shortHold.minimumPressDuration = shortHoldTime;
			shortHold.enabled = NO;
			[self addGestureRecognizer:shortHold];
		}
		*/

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
		[self sf_method:[self getFolderSetting:@"ShortHoldMethod" withDefaultSetting:shortHoldMethod withDefaultCustomAppIndex:shortHoldMethodCustomAppIndex] withForceTouch:NO];
	}
}

%new - (void)sf_swipeUp:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:[self getFolderSetting:@"SwipeUpMethod" withDefaultSetting:swipeUpMethod withDefaultCustomAppIndex:swipeUpMethodCustomAppIndex] withForceTouch:NO];
}

%new - (void)sf_swipeDown:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:[self getFolderSetting:@"SwipeDownMethod" withDefaultSetting:swipeDownMethod withDefaultCustomAppIndex:swipeDownMethodCustomAppIndex] withForceTouch:NO];
}


/**
 * The method to do specific actions on a gesture
 *
 */

%new - (void)sf_method:(NSDictionary*)methodDict withForceTouch:(BOOL)forceTouch{
	NSInteger method = [methodDict[@"method"] intValue];
	NSInteger customAppIndex = [methodDict[@"customAppIndex"] intValue];
	NSString *lastOpenedApp;
	if([methodDict objectForKey:@"lastOpenedApp"] != nil) {
		lastOpenedApp = methodDict[@"lastOpenedApp"];
	} else if(method == 7) {
		method = 2; 
	}

	SBFolder * folder = ((SBIconView *)self).icon.folder;

	
	SBIconController* iconController = [%c(SBIconController) sharedInstance];

	if(enabled && !iconController.isEditing) {

		switch (method) {
			case 1: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];

				if(HAS_BIOPROTECT) {
					if ([[%c(BioProtectController) sharedInstance ] requiresAuthenticationForOpeningFolder: folder ]){ 
						[[%c(BioProtectController) sharedInstance ] authenticateForOpeningFolder: folder ]; 
						return;
					}
				}

				
				SBFolderIconView *folderIconView = (SBFolderIconView*)self;
				UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>([folderIconView _folderIconImageView], "_leftWrapperView");


				SBFolderIcon *folderIcon = ((SBFolderIconView *)self).folderIcon;
				[folderIcon setBadge:[NSNumber numberWithInt:0]];

				[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //Open Folder
				
				if(!classicFoldersEnabled) {
					innerFolderImageView.hidden = YES;
					folderIconView._folderIconImageView.customImageView.hidden = YES;

					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
						if(folderIconView._folderIconImageView.customImageView.image == nil) innerFolderImageView.hidden = NO;
						folderIconView._folderIconImageView.customImageView.hidden = NO;
					});	
				}

				if(forceTouch) self.highlighted = NO;

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
					[folderIcon _updateBadgeValue];
				});


			}break;

			case 2: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				firstIcon = [folder getFirstIcon];
				[firstIcon openAppFromFolder:folder.folderID];

			}break;

			case 3: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[folder openAppAtIndex:1];
			}break;

			case 4: {
				//Currently this won't be used as it will be handled natively
				if([iconController respondsToSelector:@selector(presentedShortcutMenu)]) [iconController.presentedShortcutMenu presentAnimated:YES];
			}break;

			case 5: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[folder openAppAtIndex: customAppIndex-1];
			}break;

			case 6: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				[folder openLastApp];
			}break;

			case 7: {
				if(forceTouch) [[UIDevice currentDevice]._tapticEngine actuateFeedback:1];
				//Open the last opened app from the folder

				//Using SBLeafIcon in order to also loads SBBookmarkIcons!!

				SBLeafIcon *icon = nil;
				if([[%c(SBIconController) sharedInstance] respondsToSelector:@selector(homescreenIconViewMap)]) {
					icon = [[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel] leafIconForIdentifier:lastOpenedApp]; //IOS 9.3
				} else {
					if ([[[%c(SBIconViewMap) homescreenMap] iconModel] respondsToSelector:@selector(leafIconForIdentifier:)]) {
						icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] leafIconForIdentifier:lastOpenedApp]; //IOS 4+
					}
				}
				
				[icon openAppFromFolder:folder.folderID];
				
			}

			default: 
			break;
		}
	}
}


/**
 * To disable Spotlight view from showing up, if user swipes down on the icon
 *  and better swiping up support to prevent moving SpringBoard:
 *
 */

%new - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	if(!enabled) return YES;

	BOOL conflictGesture = NO;

	NSArray *targets = MSHookIvar<NSMutableArray *>(otherGestureRecognizer, "_targets");
	for(UIGestureRecognizerTarget *_target in targets) {
		id target = MSHookIvar<id>(_target, "_target");
		if([target isKindOfClass:%c(SBSearchScrollView)]) {
			otherGestureRecognizer.enabled = NO;
		}
		/*if([target isKindOfClass:%c(SBIconScrollView)]) {
			conflictGesture = YES;
			otherGestureRecognizer.enabled = NO;
			break;
		}*/
	}

	return !conflictGesture;

}

%end



%hook SBIcon

/**
 * Helper function to get an icon view
 *
 */

%new - (id)getIconView {
	SBIconView *iconView;
	if([[%c(SBIconController) sharedInstance] respondsToSelector:@selector(homescreenIconViewMap)]) {
		iconView = [[[%c(SBIconController) sharedInstance] homescreenIconViewMap] mappedIconViewForIcon:self];
	} else {
		iconView = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:self];
	}

	return iconView;
}

/**
 * Opening a specific app, and log that to the folder settings as the last opened app in folder settings
 *  and check if BioProtect is enabled for a specific app
 *
 */


%new - (void)openAppFromFolder:(NSString*)folderID {
	if(HAS_BIOPROTECT) {
		if ([[%c(BioProtectController) sharedInstance ] requiresAuthenticationForIdentifier: self.application.bundleIdentifier ]){ 
			[[%c(BioProtectController) sharedInstance ] launchApplicationWithIdentifier: self.application.bundleIdentifier ];
			return;
		}
	}

	
	NSString *lastOpenedIdentifier;
	if(![self isKindOfClass:%c(SBLeafIcon)]){
		lastOpenedIdentifier = self.application.bundleIdentifier;
	} else {
		SBLeafIcon *leafIcon = (SBLeafIcon*)self;
		lastOpenedIdentifier = leafIcon.leafIdentifier;
	}

	setFolderSetting(folderID, @"lastOpenedApp", lastOpenedIdentifier);

	if([self respondsToSelector:@selector(launchFromLocation:context:)]) {
		[self launchFromLocation:0 context:nil];
	} else if ([self respondsToSelector:@selector(launchFromLocation:)]) {
		[self launchFromLocation:0];
	} else if ([self respondsToSelector:@selector(launch)]) {
		[self launch];
	}
	
}

%end


/**
 * Methods to save a new folder ID after editing
 *
 */

%hook SBFolderView

%new - (void)updateIcon {
	if(enabled) {
		SBIcon *icon = self.folder.icon;
		SBFolderIconView *folderIconView = (SBFolderIconView*)icon.getIconView;
		SBFolderIconImageView *folderIconImageView = folderIconView._folderIconImageView;
			
		if(folderIconImageView.customImageView.image != nil) {
			[folderIconImageView hideInnerFolderImageView: YES];
			[folderIconImageView bringSubviewToFront:folderIconImageView.customImageView];
			SBIcon *firstIcon = [self.folder getFirstIcon];
			UIImage *firstImage = [firstIcon getIconImage:2];


			[UIView transitionWithView:folderIconImageView.customImageView
					duration:0.5f
					options:UIViewAnimationOptionTransitionCrossDissolve
					animations:^{
						folderIconImageView.customImageView.image = firstImage;
					} completion:nil];

		} else {
			//[folderIconImageView sendSubviewToBack:folderIconImageView.backgroundView]; // The most important part
		}
	} 
}

%end


%hook SBFolder

static NSString *oldFolderID;
%new - (void)createOldFolderID {
	self.oldFolderID = [self folderID];
}

%new(v@:@) - (void)setOldFolderID:(NSString *)folderID {
	objc_setAssociatedObject(self, &oldFolderID, folderID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new(@@:) - (NSString *)oldFolderID {
	return objc_getAssociatedObject(self, &oldFolderID);
}


/**
 * Getting the folder ID, based on the folder name and the first app in the folder
 *
 */

%new - (NSString*)folderID {
	//Misschien iets meer optimalisatie. Gewoon geen md5
	SBIcon *firstIcon = [self iconAtIndexPath: [self getFolderIndexPathForIndex:[self getFirstAppIconIndex]]]; //To ignore nested folder settings

	NSString *firstIconIdentifier;
	if(![firstIcon isKindOfClass:%c(SBLeafIcon)]){
		firstIconIdentifier = firstIcon.application.bundleIdentifier;
	} else {
		SBLeafIcon *leafIcon = (SBLeafIcon*)firstIcon;
		firstIconIdentifier = leafIcon.leafIdentifier;
	}

	return [self createFolderIDWithDisplayName:self.displayName andFirstIconIdentifier:firstIconIdentifier];
}

%new - (NSString*)createFolderIDWithDisplayName:displayName andFirstIconIdentifier:(NSString*)firstIconIdentifier {

	NSString *folderID = [NSString stringWithFormat:@"%@-%@", displayName, firstIconIdentifier];

	return folderID;
}


/**
 * Some methods to get the first index of an app in a folder
 *  as some stupids are using other tweaks
 *
 */


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
		//SBApplicationIcon *icon = [self iconAtIndexPath:indexPath];
		SBIcon *icon = (SBApplicationIcon*)[self iconAtIndexPath:indexPath];
		if([icon respondsToSelector:@selector(application)]) {
			if(icon.application.displayName != nil){ //&& ![icon isKindOfClass:%c(SBFolderIcon)
				return i;
				break;
			} else if([icon isKindOfClass:%c(SBLeafIcon)]){
				SBLeafIcon *leafIcon = (SBLeafIcon*)icon;
				if(leafIcon.leafIdentifier != nil) {
					return i;
					break;
				}
			}
		}
		i++;
	}
	return i;

}

%new - (SBIcon*)getFirstIcon { 
	switch (nestedFolderBehaviour) {
		case 2: {
			SBIcon *icon = [self iconAtIndexPath: [self getFolderIndexPathForIndex:0]];
			if([icon isKindOfClass:%c(SBFolderIcon)]) {
				return [icon.folder iconAtIndexPath: [icon.folder getFolderIndexPathForIndex:[icon.folder getFirstAppIconIndex]]];
			} else {
				return [self iconAtIndexPath: [self getFolderIndexPathForIndex:[self getFirstAppIconIndex]]];
			}
		}break;
		default: {
			return [self iconAtIndexPath: [self getFolderIndexPathForIndex:[self getFirstAppIconIndex]]];
		}break;
	}
}


/**
 * Some methods to open up apps at a specific index
 *
 */

%new - (void)openLastApp {
	SBIconIndexMutableList *iconList = MSHookIvar<SBIconIndexMutableList *>(self, "_lists");
	long long maxIconCountInList = MSHookIvar<long long>(self, "_maxIconCountInLists"); //9

	int i = (iconList.count * maxIconCountInList) - maxIconCountInList; //Begin at the last page index
	NSIndexPath *indexPath = [self getFolderIndexPathForIndex:0];

	while(i <= (maxIconCountInList * iconList.count)) { 
		//SBApplicationIcon *icon = [self iconAtIndexPath: [self getFolderIndexPathForIndex:i]];
		SBIcon *icon = (SBApplicationIcon*)[self iconAtIndexPath:[self getFolderIndexPathForIndex:i]];
		if([icon respondsToSelector:@selector(application)]) {
			if(icon.application.displayName != nil){ //&& ![icon isKindOfClass:%c(SBFolderIcon)]
				indexPath = [self getFolderIndexPathForIndex:i];
			} else if([icon isKindOfClass:%c(SBLeafIcon)]){
				SBLeafIcon *leafIcon = (SBLeafIcon*)icon;
				if(leafIcon.leafIdentifier != nil) {
					indexPath = [self getFolderIndexPathForIndex:i];
				}
			}
		}
		i++;
	}

	[[self iconAtIndexPath:indexPath] openAppFromFolder:self.folderID];

}

%new - (void)openAppAtIndex:(int)index {
	SBIconController* iconController = [%c(SBIconController) sharedInstance];
	
	if (!iconController.isEditing) { 

		SBIconIndexMutableList *iconList = MSHookIvar<SBIconIndexMutableList *>(self, "_lists");
		long long maxIconCountInList = MSHookIvar<long long>(self, "_maxIconCountInLists"); //9
		int i = [self getFirstAppIconIndex]+index;

		while (i <= (maxIconCountInList * iconList.count)) {
			NSIndexPath *indexPath = [self getFolderIndexPathForIndex:i];
			//SBApplicationIcon *icon = [self iconAtIndexPath:indexPath];
			SBIcon *icon = (SBApplicationIcon*)[self iconAtIndexPath:indexPath];
			if([icon respondsToSelector:@selector(application)]) {
				if(icon.application.displayName != nil ){ // && ![icon isKindOfClass:%c(SBFolderIcon)]
					[icon openAppFromFolder:self.folderID];
					break;
				} else if([icon isKindOfClass:%c(SBLeafIcon)]){
					SBLeafIcon *leafIcon = (SBLeafIcon*)icon;
					if(leafIcon.leafIdentifier != nil) {
						[icon openAppFromFolder:self.folderID];
					}
				}
			}
			i++;
		}

	}
}

%end




%hook SBRootFolderView
static NSMutableArray *oldFolderIDsAtBeginEditing;

-(void)setEditing:(BOOL)editing animated:(BOOL)arg2 {
	NSArray *folderArray = [self.folder.folderIcons allObjects]; //ALL FOLDERS ^^
	NSMutableArray *oldFolderIDsAtEndEditing;

	NSMutableDictionary *mutableCustomFolderSettings;

	if(editing) oldFolderIDsAtBeginEditing = [[NSMutableArray alloc] init];
	else {
		oldFolderIDsAtEndEditing = [[NSMutableArray alloc] init];
		mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	} 

	

	for (int i=0; i<[folderArray count]; i++) {
		SBFolderIcon *folderIcon = [folderArray objectAtIndex:i];
		SBFolder *folder = folderIcon.folder;

		if(editing) {
			[folder createOldFolderID];
			[oldFolderIDsAtBeginEditing addObject:[folder folderID]];
		} else {
			if(folder.oldFolderID) [oldFolderIDsAtEndEditing addObject:folder.oldFolderID];
			//[folder replaceOldFolderID:folder.oldFolderID byNewFolderID:[folder folderID]];
			//Hieronder is efficienter:
			if(![folder.oldFolderID isEqualToString:[folder folderID]] && [mutableCustomFolderSettings objectForKey:folder.oldFolderID]) {
				[mutableCustomFolderSettings removeObjectForKey:folder.oldFolderID];
				[mutableCustomFolderSettings setObject:customFolderSettings[folder.oldFolderID] forKey:[folder folderID]];
			}
		}
	}

	//Remove the folders from customFolderSettings when the folder itself is removed
	if(!editing && mutableCustomFolderSettings) {
		for (int i=0; i<[oldFolderIDsAtBeginEditing count]; i++) {
			NSString *oldFolderID = [oldFolderIDsAtBeginEditing objectAtIndex:i];
			HBLogDebug(@"oldFolder ID: %@", oldFolderID);
			if(![oldFolderIDsAtEndEditing containsObject:oldFolderID] && [oldFolderIDsAtEndEditing count] > 0 && [customFolderSettings objectForKey:oldFolderID]) {
				
				[mutableCustomFolderSettings removeObjectForKey:oldFolderID];
			}
		}
		saveFolderSettings(mutableCustomFolderSettings);
	}

	%orig; 
	
}
	

%end

/**
 * Finally register a listener to reload preferences on changes
 *
 */

%ctor{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)loadPreferences,
		CFSTR("nl.jessevandervelden.swipyfoldersprefs/prefsChanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);

	loadPreferences();
} 