#import <CommonCrypto/CommonDigest.h>
#import "SwipyFolders.h"

//Helper functions:
/*
static NSString * calculateMD5(NSString * input) {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); 

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x", digest[i]];

    return  output;
}
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

#define HAS_BIOPROTECT (%c(BioProtectController) != nil) 

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

%hook SBFolderIconImageView
-(void)layoutSubviews {
  	%orig;

  	SBFolder *folder = self._folderIcon.folder;
	NSDictionary *folderSettings = customFolderSettings[folder.folderID];


  	if(hideGreyFolderBackground || ([folderSettings[@"customFolderAppearance"] intValue] == 1 && [folderSettings[@"customFolderHideGreyFolderBackground"] intValue] == 1)){
	  	CGSize iconImageSize = [%c(SBIconView) defaultIconImageSize];

		UIView *gridContainer  = MSHookIvar<UIView *>(self, "_pageGridContainer");
		CGRect orig = gridContainer.frame;
		gridContainer.frame = CGRectMake(0, 0, iconImageSize.width, iconImageSize.height);

		UIView *wrapper = MSHookIvar<UIView*>(self,"_leftWrapperView");
		orig = wrapper.frame;
		wrapper.frame = CGRectMake(0, 0, iconImageSize.width, iconImageSize.height);

		MSHookIvar<UIView *>(self, "_backgroundView").hidden = YES;
	}
}


- (void)_showLeftMinigrid{
 	%orig;
 	if(enabled && enableFolderPreview){
 		SBFolder *folder = self._folderIcon.folder;
 		NSDictionary *folderSettings = customFolderSettings[folder.folderID];
 		
 		if([folderSettings[@"customFolderAppearance"] intValue] == 1 && ([folderSettings objectForKey:@"customFolderEnableFolderPreview"] == nil || [folderSettings[@"customFolderEnableFolderPreview"] intValue] == 0)) {
			return;
		}
	
		SBIcon *firstIcon = [folder getFirstIcon];
		UIImageView *innerFolderImageView = MSHookIvar<UIImageView *>(self, "_leftWrapperView");
		innerFolderImageView.image = [firstIcon getIconImage:2];
	}
}

%end



static SBIcon *firstIcon;
static SBIconView *tappedIcon;
static NSDate *lastTouchedTime;
static NSDate *lastTappedTime;
static NSDate *forceTouchOpenedTime;
static BOOL doubleTapRecognized;
static BOOL forceTouchRecognized;

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

	/*
	NSArray *sortedFolderArray = [NSArray new];
	sortedFolderArray = [folderArray sortedArrayUsingComparator:^NSComparisonResult(SBFolderIcon* a, SBFolderIcon* b) {
	    NSString *first = a.folder.displayName;
	    NSString *second = b.folder.displayName;
	    return [first compare:second];
	}];
	*/

	NSMutableDictionary *foldersRepresentation = [NSMutableDictionary dictionary];

	for (int i=0; i<[folderArray count]; i++) {
		SBFolderIcon *folderIcon = [folderArray objectAtIndex:i];
		SBFolder *folder = folderIcon.folder;

		//NSString *defaultDisplayName = MSHookIvar<NSString*>(folder, "defaultDisplayName");
		NSArray *folderAppIcons = [folder.orderedIcons allObjects];
		NSMutableArray *applicationBundleIDs = [[NSMutableArray alloc] init];
		for(int k=0; k<[folderAppIcons count]; k++ ) {
			SBApplicationIcon *appIcon = [folderAppIcons objectAtIndex:k];
			if(appIcon.application.bundleIdentifier != nil) [applicationBundleIDs addObject:appIcon.application.bundleIdentifier];
			
		}
		NSMutableDictionary *folderDictionary = [NSMutableDictionary dictionary];
		[folderDictionary setObject:folder.displayName forKey:@"displayName"]; // String
		//[folderDictionary setObject:folder.orderedIcons forKey:@"icons"]; //SBApplicationIcon
		//[folderDictionary setObject:folder.lists forKey:@"lists"]; //SBIconListModel

		[folderDictionary setObject:applicationBundleIDs forKey:@"applicationBundleIDs"]; //NSArray with bundle id strings

		NSString *folderID = folder.folderID;

		[folderDictionary setObject:folderID forKey:@"folderID"]; 
		
		[foldersRepresentation setObject:folderDictionary forKey:folderID]; //[NSString stringWithFormat:@"%d", i]
	}

	HBLogDebug(@"%@", foldersRepresentation);
	return foldersRepresentation;
}

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

//Finally the real deal:
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

				if (method == 4) {
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

//For protecting shortcutmenu items with BioProtect
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

	NSLog(@"Folder settings: %@", folderSettings);

	NSMutableDictionary *sendInfo = [NSMutableDictionary new];
	[sendInfo setObject:sendMethod forKey:@"method"];
	[sendInfo setObject:sendAppIndex forKey:@"customAppIndex"];
	if(folderSettings[@"lastOpenedApp"]) [sendInfo setObject:folderSettings[@"lastOpenedApp"] forKey:@"lastOpenedApp"];


	return sendInfo;
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
		[self sf_method:[self getFolderSetting:@"ShortHoldMethod" withDefaultSetting:shortHoldMethod withDefaultCustomAppIndex:shortHoldMethodCustomAppIndex] withForceTouch:NO];
	}
}

%new - (void)sf_swipeUp:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:[self getFolderSetting:@"SwipeUpMethod" withDefaultSetting:swipeUpMethod withDefaultCustomAppIndex:swipeUpMethodCustomAppIndex] withForceTouch:NO];
}

%new - (void)sf_swipeDown:(UISwipeGestureRecognizer *)gesture {
	[self sf_method:[self getFolderSetting:@"SwipeDownMethod" withDefaultSetting:swipeDownMethod withDefaultCustomAppIndex:swipeDownMethodCustomAppIndex] withForceTouch:NO];
}

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
				innerFolderImageView.hidden = YES;
				

				[[%c(SBIconController) sharedInstance] openFolder:folder animated:YES]; //Open Folder

				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
					innerFolderImageView.hidden = NO;
				});	

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

				//Using SBLeafIcon in order to also load SBBookmarkIcons!!

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

//To disable Spotlight view from showing up, if user swipe down on the icon && beter swiping up support if it is set to open Shortcutview to prevent moving SpringBoard:
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

	preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
	NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
	NSMutableDictionary *mutableFolderSettings = [customFolderSettings[folderID] mutableCopy];
	if(!mutableFolderSettings) mutableFolderSettings = [NSMutableDictionary new];
	if(!mutableCustomFolderSettings) mutableCustomFolderSettings = [NSMutableDictionary new];

	[mutableFolderSettings setObject:lastOpenedIdentifier forKey:@"lastOpenedApp"];
	[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:folderID];

	[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
	[preferences synchronize];

	CFStringRef toPost = (CFStringRef)@"nl.jessevandervelden.swipyfoldersprefs/prefsChanged";
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);



	if([self respondsToSelector:@selector(launchFromLocation:context:)]) {
		[self launchFromLocation:0 context:nil];
	} else if ([self respondsToSelector:@selector(launchFromLocation:)]) {
		[self launchFromLocation:0];
	} else if ([self respondsToSelector:@selector(launch)]) {
		[self launch];
	}
	
}

%end

static NSString *oldFolderID;
%hook SBFolderView

/*
- (void)_setFolderName:(NSString*)newFolderName { //This isn't even needed anymore!!
	
	//oldFolderID = self.folder.folderID;
	//HBLogDebug(@"De folder: %@ wordt vernoemd naar: %@", oldFolderName, newFolderName);
	%orig;
	
	NSString* newFolderID = [self.folder folderID];
	HBLogDebug(@"De folder: %@ wordt vernoemd naar: %@", oldFolderID, newFolderID);
	[self.folder replaceOldFolderID:oldFolderID byNewFolderID:newFolderID];
	oldFolderID = newFolderID;
}*/

- (void)setEditing:(_Bool)editing animated:(_Bool)arg2{
	%orig; 
	if(editing == 0 && self.folder.displayName && ![self.folder isKindOfClass:%c(SBRootFolder)]) {
		NSString* newFolderID = [self.folder folderID];
		HBLogDebug(@"De folder: %@ wordt vernoemd naar: %@", oldFolderID, newFolderID);
		[self.folder replaceOldFolderID:oldFolderID byNewFolderID:newFolderID];
		//oldFolderID = newFolderID; //If any further changes
	} 
	else if(editing == 1 && self.folder.displayName && ![self.folder isKindOfClass:%c(SBRootFolder)]) {
		oldFolderID = [[self.folder folderID] retain];
	}


}

- (void)cleanupAfterClosing { //Works but what if Springboard crashes while still in editing mode >> then we've corrupted settings
	%orig;
	if(self.editing == 1 && self.folder.displayName && ![self.folder isKindOfClass:%c(SBRootFolder)]) {
		NSString* newFolderID = [self.folder folderID];
		HBLogDebug(@"CLEANUP: de %@ wordt vernoemd naar: %@", oldFolderID, newFolderID);
		[self.folder replaceOldFolderID:oldFolderID byNewFolderID:newFolderID];
		
	}
}



%end

/*
%hook SBFolderIcon
- (void)node:(id)arg1 didRemoveContainedNodeIdentifiers:(id)nodeList {
	%orig;
	NSArray *nodeArray = [nodeList allObjects];
	id firstObject = [nodeArray objectAtIndex:0];
	if([firstObject isKindOfClass:%c(SBIconListModel)]) {
		SBIconListModel *iconListModel = (SBIconListModel*)firstObject;
		if(iconListModel.folder.displayName) %log;
	}
}
%end
*/


%hook SBFolder

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
		HBLogDebug(@"YOO WE GAAN BEGINNEN");
		preferences = [[NSUserDefaults alloc] initWithSuiteName:@"nl.jessevandervelden.swipyfoldersprefs"];
		NSMutableDictionary *mutableCustomFolderSettings = [customFolderSettings mutableCopy];
		NSMutableDictionary *mutableFolderSettings = [customFolderSettings[oldFolderID] mutableCopy];
		if(!mutableFolderSettings || !mutableCustomFolderSettings) return;
		HBLogDebug(@"WE ZIJN VERDER");
		[mutableCustomFolderSettings removeObjectForKey:oldFolderID];
		[mutableCustomFolderSettings setObject:mutableFolderSettings forKey:newFolderID];

		[preferences setObject:mutableCustomFolderSettings forKey:@"customFolderSettings"];
		[preferences synchronize];

		CFStringRef toPost = (CFStringRef)@"nl.jessevandervelden.swipyfoldersprefs/prefsChanged";
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);

	}
}


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
			SBIcon *icon = [self iconAtIndexPath:indexPath];
			if(icon.displayName != nil && ![icon isKindOfClass:%c(SBFolderIcon)]){
				[icon openAppFromFolder:self.folderID];
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