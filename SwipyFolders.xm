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
	swipeUpMethodCustomAppIndex 	= 	[preferences integerForKey:@"swipeUpMethodCustomAppIndex"];
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



/**
 * Setting the folder preview
 *	
 */

%hook SBFolderIconImageView

- (void)_showLeftMinigrid{
	%orig;

	
	SBFolder *folder = self._folderIcon.folder;
	NSDictionary *folderSettings = customFolderSettings[folder.folderID];

	SBIconController *iconController = [%c(SBIconController) sharedInstance];

	if(enabled && !iconController.isEditing){	
		
		
		UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>(self, "_leftWrapperView");
		
		if((enableFolderPreview && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0 || [folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil))) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1)){
			SBIcon *firstIcon = [folder getFirstIcon];
			UIImage *firstImage = [firstIcon getIconImage:2];
			
			//innerFolderImageView.image = firstImage;
			
			self.backgroundView.customImageView.image = firstImage;

		
			[self hideInnerFolderImageView: YES];


			CGSize size = [%c(SBIconView) defaultIconImageSize];
			CGRect iconFrame = CGRectMake(-1, -1, size.width, size.height);
			
			if((!hideGreyFolderBackground && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderHideGreyFolderBackground"] intValue] == 1)) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1 && [folderSettings[@"customFolderHideGreyFolderBackground"] intValue] == 0)) {
				CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54; 
				iconFrame = CGRectMake(7.5, 7.5, iconSize, iconSize);
			}
				
			self.backgroundView.customImageView.frame = iconFrame;
			//[self bringSubviewToFront:innerFolderImageView];

		} else {
			self.backgroundView.customImageView.image = nil;
			[self hideInnerFolderImageView: NO];
			[self sendSubviewToBack:self.backgroundView];
			[self bringSubviewToFront:innerFolderImageView];
			

			
		}


	}

	
}

%new -(void)hideInnerFolderImageView:(BOOL)hide {
	UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>(self, "_leftWrapperView");
	innerFolderImageView.hidden = hide;
}



%end


%hook SBFolderIconBackgroundView
static UIImageView *customImageView;

- (UIView *)initWithDefaultSize{

	UIView *view = %orig;

	if(enabled) {
		CGSize size = [%c(SBIconView) defaultIconImageSize];
		CGRect iconFrame = CGRectMake(-1, -1, size.width, size.height);
		if(!hideGreyFolderBackground) {
			CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54; 
			iconFrame = CGRectMake(7.5, 7.5, iconSize, iconSize); //Full size is 60
		}


		self.customImageView = [[UIImageView alloc] initWithFrame:iconFrame];
		self.customImageView.backgroundColor = [UIColor clearColor];

		[view insertSubview:self.customImageView atIndex:0];
	}

	return view;

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


%end

%hook SBFolderIconZoomAnimator

-(void)_prepareAnimation{

	%orig;


	SBFolder *folder = self.targetIcon.folder;
	NSDictionary *folderSettings = customFolderSettings[folder.folderID];
	SBFolderIconImageView *folderIconImageView  = self.targetIconView._folderIconImageView;

	if((enableFolderPreview && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0 || [folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil))) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1)){

		[folderIconImageView bringSubviewToFront:folderIconImageView.backgroundView];

		folderIconImageView.backgroundView.customImageView.alpha = 0;
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5];
		[folderIconImageView.backgroundView.customImageView setAlpha:1.0];
		[UIView commitAnimations];
	} else {

		/*[folderIconImageView hideInnerFolderImageView: NO];
		[folderIconImageView sendSubviewToBack:folderIconImageView.backgroundView];*/
	}

	//If not calling %orig; the icons behind the screen are not removed, so cool iOS 10 gimmick?


}
%end

/**
 * Some stupid methods to let it work with ClassicFolders
 *	
 */

%hook SBFolderController

-(void)prepareToOpen{ 
	%orig;

	
	if(enabled && ![self isKindOfClass:%c(SBRootFolderController)]) {
		SBFolder *folder = self.folder;
		NSDictionary *folderSettings = customFolderSettings[folder.folderID];

		SBIcon *icon = folder.icon;
		SBFolderIconView *folderIconView = (SBFolderIconView*)icon.getIconView;
		SBFolderIconImageView *folderIconImageView = folderIconView._folderIconImageView;

		if((enableFolderPreview && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0 || [folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil))) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1)){

			[folderIconImageView hideInnerFolderImageView: YES];

			[folderIconImageView bringSubviewToFront:folderIconImageView.backgroundView];

		} else {
			[folderIconImageView hideInnerFolderImageView: NO];

			[folderIconImageView sendSubviewToBack:folderIconImageView.backgroundView];
		}

	}

}

-(void)prepareToClose{ 
	%orig;	

	if(enabled && ![self isKindOfClass:%c(SBRootFolderController)]) {

		SBFolder *folder = self.folder;
		NSDictionary *folderSettings = customFolderSettings[folder.folderID];

		SBIcon *icon = folder.icon;
		SBFolderIconView *folderIconView = (SBFolderIconView*)icon.getIconView;
		SBFolderIconImageView *folderIconImageView = folderIconView._folderIconImageView;

		if((enableFolderPreview && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0 || [folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil))) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1)){

			//[folderIconImageView hideInnerFolderImageView: YES];

			[folderIconImageView bringSubviewToFront:folderIconImageView.backgroundView];

			
		} else {
			[folderIconImageView hideInnerFolderImageView: NO];

			[folderIconImageView sendSubviewToBack:folderIconImageView.backgroundView];
			UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>(folderIconImageView, "_leftWrapperView");
			[folderIconImageView bringSubviewToFront:innerFolderImageView];
		}
	}




}

-(void)setOpen:(BOOL)arg1 {
	%orig;
	
	if(enabled) {
		if(arg1 && ![self isKindOfClass:%c(SBRootFolderController)]) {
			SBFolder *folder = self.folder;
			NSDictionary *folderSettings = customFolderSettings[folder.folderID];

			SBIcon *icon = folder.icon;
			SBFolderIconView *folderIconView = (SBFolderIconView*)icon.getIconView;
			SBFolderIconImageView *folderIconImageView = folderIconView._folderIconImageView;
			if((enableFolderPreview && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0 || [folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil))) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1)){


				[folderIconImageView hideInnerFolderImageView: YES];

				[folderIconImageView bringSubviewToFront:folderIconImageView.backgroundView];

			} else {
				[folderIconImageView hideInnerFolderImageView: NO];

				[folderIconImageView sendSubviewToBack:folderIconImageView.backgroundView];
			}
		}
	}

	%orig;
}

%end



static SBIcon *firstIcon;
static SBIconView *tappedIcon;
static NSDate *lastTouchedTime;
static NSDate *lastTappedTime;
static NSDate *forceTouchOpenedTime;
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
- (void)_handleShortcutMenuPeek:(UILongPressGestureRecognizer *)recognizer {
	SBIconView *iconView = (SBIconView*)recognizer.view;

	firstIcon = nil;
	if(!iconView.isFolderIconView) {
		%orig;
		return;
	}

	SBFolder* folder = ((SBFolderIconView *)iconView).folderIcon.folder;
	firstIcon = [folder getFirstIcon];
	if (!self.isEditing && iconView.isFolderIconView && forceTouchMethod != 0 && firstIcon && enabled) {
		NSDictionary *methodDict = [iconView getFolderSetting:@"ForceTouchMethod" withDefaultSetting:forceTouchMethod withDefaultCustomAppIndex:forceTouchMethodCustomAppIndex];
		NSInteger method = [methodDict[@"method"] intValue];
		switch (recognizer.state) {
			case UIGestureRecognizerStateBegan: {

				[iconView cancelLongPressTimer];

				[iconView sf_method:methodDict withForceTouch:YES];
				forceTouchRecognized = YES;

			}break;

			case UIGestureRecognizerStateChanged: {
				if (forceTouchMethod == 4) {
					[self.presentedShortcutMenu updateFromPressGestureRecognizer:recognizer];
				}
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
	if (!self.isEditing && iconView.isFolderIconView && !forceTouchRecognized && enabled) {

			NSDate *nowTime = [[NSDate date] retain];
			if (!forceTouchRecognized && shortHoldMethod != 0 && lastTouchedTime && [nowTime timeIntervalSinceDate:lastTouchedTime] >= shortHoldTime) {

				[iconView sf_method:[iconView getFolderSetting:@"ShortHoldMethod" withDefaultSetting:shortHoldMethod withDefaultCustomAppIndex:shortHoldMethodCustomAppIndex] withForceTouch:NO];
				lastTouchedTime = nil;
				
				return;
			} else if(!forceTouchRecognized && doubleTapMethod != 0) {
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
	if([iconController respondsToSelector:@selector(presentedShortcutMenu)]) {
		SBApplicationShortcutMenu *shortcutMenu = MSHookIvar<SBApplicationShortcutMenu*>(iconController, "_presentedShortcutMenu");
		if(shortcutMenu.isPresented) {
			return;
		}
	}

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
				

				[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //Open Folder
				if(!classicFoldersEnabled) {
					innerFolderImageView.hidden = YES;


					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
						innerFolderImageView.hidden = NO;
					});	
				}

				if(forceTouch) self.highlighted = NO;

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
				if([iconController respondsToSelector:@selector(presentedShortcutMenu)]) {
					
					[iconController.presentedShortcutMenu dismissAnimated:NO completionHandler:nil];
					SBApplicationShortcutMenu *shortcutMenu = MSHookIvar<SBApplicationShortcutMenu*>(iconController, "_presentedShortcutMenu");

					NSDate *nowTime = [[NSDate date] retain];

					if(!shortcutMenu.isPresented && (forceTouchOpenedTime == nil || [nowTime timeIntervalSinceDate:forceTouchOpenedTime] > 1)) {
						firstIcon = [folder iconAtIndexPath:[NSIndexPath indexPathForRow:folder.getFirstAppIconIndex inSection:0]];

						iconController.presentedShortcutMenu = [[%c(SBApplicationShortcutMenu) alloc] initWithFrame:[UIScreen mainScreen].bounds application:firstIcon.application iconView:self interactionProgress:nil orientation:1];
						iconController.presentedShortcutMenu.applicationShortcutMenuDelegate = iconController;
						UIViewController *rootView = [[UIApplication sharedApplication].keyWindow rootViewController];
						[rootView.view addSubview:iconController.presentedShortcutMenu];
						[iconController.presentedShortcutMenu presentAnimated:YES];

						SBIconView *editedIconView = MSHookIvar<SBIconView *>(iconController.presentedShortcutMenu, "_proxyIconView");
						editedIconView.labelView.hidden = YES;

						SBFolderIconImageView *folderIconImageView = MSHookIvar<SBFolderIconImageView *>(editedIconView, "_iconImageView");
						UIImageView *folderImageView = MSHookIvar<UIImageView *>(folderIconImageView, "_leftWrapperView");
						folderImageView.image = [firstIcon getIconImage:2];
						//[iconController _dismissShortcutMenuAnimated:YES completionHandler:nil]; //HIERMEE LAAT JE DE STATUSBAR WEER ZIEN!

						forceTouchOpenedTime = nowTime;
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

	NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	NSMutableDictionary *mutableFolderSettings = [customFolderSettings[folderID] mutableCopy];
	if(!mutableFolderSettings) mutableFolderSettings = [NSMutableDictionary new];
	if(!mutableCustomFolderSettings) mutableCustomFolderSettings = [NSMutableDictionary new];

	[mutableFolderSettings setObject:lastOpenedIdentifier forKey:@"lastOpenedApp"];
	[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:folderID];

	NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
	[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
	[preferences synchronize];
	customFolderSettings = [mutableCustomFolderSettings copy];
	


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

static NSString *oldFolderID;
%hook SBFolderView


- (void)setEditing:(_Bool)editing animated:(_Bool)arg2{
	%orig; 
	if(editing == 0 && self.folder.displayName && ![self.folder isKindOfClass:%c(SBRootFolder)]) {
		NSString* newFolderID = [self.folder folderID];
		[self.folder replaceOldFolderID:oldFolderID byNewFolderID:newFolderID];

		[self updateIcon];
	} 
	else if(editing == 1 && self.folder.displayName && ![self.folder isKindOfClass:%c(SBRootFolder)]) {
		oldFolderID = [[self.folder folderID] retain];
	}


}

- (void)cleanupAfterClosing { //Works but what if Springboard crashes while still in editing mode >> then we've corrupted settings
	%orig;
	if(self.editing == 1 && self.folder.displayName && ![self.folder isKindOfClass:%c(SBRootFolder)]) {
		NSString* newFolderID = [self.folder folderID];
		[self.folder replaceOldFolderID:oldFolderID byNewFolderID:newFolderID];

		[self updateIcon];
		
		
	}
}

%new - (void)updateIcon {
	if(enabled) {
		SBIcon *icon = self.folder.icon;
		SBFolderIconView *folderIconView = (SBFolderIconView*)icon.getIconView;
		SBFolderIconImageView *folderIconImageView = folderIconView._folderIconImageView;
			
		CGSize size = [%c(SBIconView) defaultIconImageSize];
		CGRect iconFrame = CGRectMake(-1, -1, size.width, size.height);

		NSDictionary *folderSettings = customFolderSettings[self.folder.folderID];	
		if((!hideGreyFolderBackground && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderHideGreyFolderBackground"] intValue] == 1)) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1 && [folderSettings[@"customFolderHideGreyFolderBackground"] intValue] == 0)) {
			CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54; 
			iconFrame = CGRectMake(7.5, 7.5, iconSize, iconSize);
		}

				
		folderIconImageView.backgroundView.customImageView.frame = iconFrame; 


		if((enableFolderPreview && !([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0 || [folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil))) || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 1)){
			[folderIconImageView hideInnerFolderImageView: YES];
			[folderIconImageView bringSubviewToFront:folderIconImageView.backgroundView.customImageView];
			SBIcon *firstIcon = [self.folder getFirstIcon];
			UIImage *firstImage = [firstIcon getIconImage:2];
			folderIconImageView.backgroundView.customImageView.image = firstImage;

		} else {
			[folderIconImageView hideInnerFolderImageView: NO];
			folderIconImageView.backgroundView.customImageView.image = nil;
			UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>(folderIconImageView, "_leftWrapperView");

			[folderIconImageView bringSubviewToFront:innerFolderImageView];
			folderIconImageView.backgroundView.customImageView.image = nil;

			[folderIconImageView sendSubviewToBack:folderIconImageView.backgroundView]; // The most important part

			//[folderIconImageView.]
		}
	} 
}

%end


%hook SBFolder

/*
- (void)didRemoveFolder:(SBFolder*)folder {
	NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	NSMutableDictionary *mutableFolderSettings = [customFolderSettings[oldFolderID] mutableCopy];
	if(!mutableFolderSettings || !mutableCustomFolderSettings) return;
	[mutableCustomFolderSettings removeObjectForKey:oldFolderID];

	[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
	[preferences synchronize];
	customFolderSettings = [mutableCustomFolderSettings copy];
	%orig;
}
*/


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

	NSString *folderID = [NSString stringWithFormat:@"%@-%@", displayName, firstIconIdentifier]; //calculateMD5(); //md5? slower :(

	return folderID;
}

%new - (void)replaceOldFolderID:(NSString*)oldFolderID byNewFolderID:(NSString*)newFolderID {
	if(oldFolderID && ![oldFolderID isEqualToString:newFolderID]) {
		NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
		NSMutableDictionary *mutableFolderSettings = [customFolderSettings[oldFolderID] mutableCopy];
		if(!mutableFolderSettings || !mutableCustomFolderSettings) return;
		[mutableCustomFolderSettings removeObjectForKey:oldFolderID];
		[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:newFolderID];

		NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
		[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
		[preferences synchronize];
		customFolderSettings = [mutableCustomFolderSettings copy];

	}
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