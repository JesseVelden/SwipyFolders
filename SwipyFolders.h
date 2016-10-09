@interface _UITapticEngine : NSObject
- (void)actuateFeedback:(NSInteger)count;
@end

@interface UIDevice (Private)
- (_UITapticEngine *)_tapticEngine;
@end

@interface UIInteractionProgress : NSObject
@property (assign, nonatomic, readonly) CGFloat percentComplete;
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
- (NSString*)displayIdentifier;
- (_Bool)statusBarHiddenForCurrentOrientation;
- (_Bool)isRunning;
@end;


@interface SBIcon : NSObject
+ (struct CGSize)defaultIconImageSize;
+ (struct CGSize)defaultIconSize;
@property(readonly, copy, nonatomic) NSString *displayName;
- (UIImage*)getIconImage:(int)arg1;
- (_Bool)isFolderIcon;
- (_Bool)isNewsstandIcon;
- (void)launch; 
- (void)launchFromLocation:(NSInteger)location; 
- (void)launchFromLocation:(NSInteger)location context:(id)context; 
- (SBApplication*)application;
- (id)folder;
- (void)openAppFromFolder:(NSString*)folder;
- (id)getIconView;

@end

@interface SBLeafIcon : SBIcon
- (id)leafIdentifier;
@end

@interface SBApplicationIcon : SBLeafIcon
- (SBApplication*)application;
@end


@interface SBFolder : NSObject
@property(readonly, nonatomic) long long listCount;
@property(readonly, nonatomic) long long _maxIconCountInLists;
@property(copy, nonatomic) NSString *displayName;
@property(readonly, copy, nonatomic) NSArray *lists;
@property (assign,nonatomic) SBIcon * icon; 
- (SBApplicationIcon *)iconAtIndexPath:(NSIndexPath *)indexPath;
- (id)folderIcons;
- (id)defaultDisplayName;
- (id)allIcons;
- (id)orderedIcons;
- (void)setDefaultDisplayName:(SBFolder*)folder;
- (NSIndexPath*)indexPathForIcon:(id)arg1;
- (void)didRemoveFolder:(id)arg1;


- (NSString*)createFolderIDWithDisplayName:displayName andFirstIconIdentifier:(NSString*)firstIconIdentifier;
- (NSString*)folderID;
- (void)replaceOldFolderID:(NSString*)oldFolderID byNewFolderID:(NSString*)newFolderID;


- (NSIndexPath*)getFolderIndexPathForIndex:(int)index;
- (void)openLastApp;
- (void)openAppAtIndex:(int)index;
- (void)openFirstApp;
- (void)openSecondApp; 
- (void)quickActionOnFirstApp; 
- (int)getFirstAppIconIndex;
- (SBIcon*)getFirstIcon;

@end

@interface SBIconListModel : NSObject
@property(readonly, nonatomic) __weak SBFolder *folder; 
- (void)removeListObserver:(id)arg1;
- (void)removeNodeObserver:(id)arg1;
@end

@interface SBFolderView : UIView
@property(retain, nonatomic) SBFolder *folder; 
@property(readonly, nonatomic, getter=isEditing) _Bool editing; 
- (void)_setFolderName:(id)arg1;
- (void)setEditing:(_Bool)arg1 animated:(_Bool)arg2;
- (void)cleanupAfterClosing;
- (void)updateIcon;
@end

@interface SBBookmarkIcon : SBLeafIcon //Eigenlijk SBLeafIcon
@property(readonly, nonatomic) NSURL *launchURL;
@end

@interface SBIconIndexMutableList : NSObject
@property(readonly, nonatomic) long long count;
@end

@interface SBIconView : UIView
@property(retain, nonatomic) SBIcon *icon;
@property(assign, getter = isHighlighted) BOOL highlighted;
@property(retain, nonatomic) UIPreviewForceInteractionProgress *shortcutMenuPresentProgress; 
@property(retain, nonatomic) UILongPressGestureRecognizer *shortcutMenuPeekGesture; 
+ (id)sharedInstance;
- (void)_handleSecondHalfLongPressTimer:(id)arg1;
- (void)cancelLongPressTimer;
+ (struct CGSize)defaultIconImageSize;
- (UIImageView *)_currentImageView;
- (void)setWallpaperRelativeCenter:(struct CGPoint)arg1;
- (void)setIsEditing:(_Bool)arg1;
- (UIView*)labelView;

//New:
- (NSDictionary*)getFolderSetting:(NSString*)setting withDefaultSetting:(NSInteger)globalSetting withDefaultCustomAppIndex:(NSInteger)globalAppIndex;
- (void)sf_method:(NSDictionary*)methodInfo withForceTouch:(BOOL)forceTouch;
- (void)sf_swipeUp:(UISwipeGestureRecognizer *)gesture;
- (void)sf_swipeDown:(UISwipeGestureRecognizer *)gesture;
- (void)sf_shortHold:(UILongPressGestureRecognizer *)gesture;

- (BOOL)isFolderIconView;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)swipeUp shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)ges;
- (BOOL)gestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
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

@interface SBApplicationShortcutMenu : UIView {
	SBApplicationShortcutMenuContentView* _contentView;
}
@property(retain, nonatomic) SBApplicationShortcutMenuContentView *contentView; 
@property(retain, nonatomic) SBApplication *application; 
@property(retain ,nonatomic) id <SBApplicationShortcutMenuDelegate> applicationShortcutMenuDelegate; 
@property(readonly, nonatomic) _Bool isPresented;
@property(retain, nonatomic) SBIconView *iconView;

- (id)initWithFrame:(CGRect)arg1 application:(id)arg2 iconView:(id)arg3 interactionProgress:(id)arg4 orientation:(long long)arg5;
- (void)presentAnimated:(_Bool)arg1;
- (void)menuContentView:(id)arg1 activateShortcutItem:(id)arg2 index:(long long)arg3;
- (void)updateFromPressGestureRecognizer:(id)arg1;
- (void)dismissAnimated:(_Bool)arg1 completionHandler:(id)arg2;
- (void)_dismissAnimated:(_Bool)arg1 finishPeeking:(_Bool)arg2 ignorePresentState:(_Bool)arg3 completionHandler:(id)arg4;
- (void)applicationShortcutMenuDidDismiss:(id)arg1;
- (void) onBioProtectSuccessWithMenuContentView:(id)arg1 activateShortcutItem:(id)arg2 index:(long long)arg3;

@end


@interface SBIconListView : UIView
-(void)setIconsNeedLayout;
-(void)layoutIconsIfNeeded:(double)needed domino:(BOOL)domino;
-(CGPoint)centerForIcon:(id)icon;
-(CGPoint)originForIcon:(id)icon;
-(CGPoint)originForIconAtIndex:(unsigned)index;
-(CGSize)defaultIconSize;

@end

@interface SBRootIconListView : SBIconListView
- (SBFolder*)folder;
- (NSArray *)icons;
- (unsigned long long)indexOfIcon:(id)icon;
@end

@interface SBIconModel : NSObject
- (SBIcon*)applicationIconForBundleIdentifier:(id)arg1;
- (SBIcon*)applicationIconForDisplayIdentifier:(id)arg1;
- (id)leafIconForIdentifier:(id)arg1;

@end

@interface SBIconViewMap
- (SBIconView*)iconViewForIcon:(SBIcon*)icon;
- (SBIconView*)mappedIconViewForIcon:(SBIcon*)icon;
+(SBIconViewMap *)homescreenMap;
@property(readonly, nonatomic) SBIconModel *iconModel;

@end

@interface SBRootFolder : SBFolder
@end


@interface SBIconController : UIViewController <SBApplicationShortcutMenuDelegate>
@property(retain, nonatomic) SBApplicationShortcutMenu *presentedShortcutMenu;
@property(readonly, nonatomic) SBIconViewMap *homescreenIconViewMap;
+ (id)sharedInstance;
- (void)_revealMenuForIconView:(id)arg1 presentImmediately:(BOOL)arg2;
- (BOOL)_canRevealShortcutMenu;
- (BOOL)isEditing;
- (void)iconHandleLongPress:(id)arg1;
- (void)iconTouchBegan:(id)arg1;
- (void)setIsEditing:(BOOL)arg1;
- (void)_handleShortcutMenuPeek:(UILongPressGestureRecognizer *)recognizer ;
- (void)iconTapped:(SBIconView *)iconView;
- (_Bool)hasOpenFolder;
- (SBFolder*)openFolder;
- (void)scrollToIconListContainingIcon:(SBIcon *)icon animate:(_Bool)arg2;
-(void)openFolder:(id)folder animated:(BOOL)animated;
- (void)closeFolderAnimated:(_Bool)arg1;
- (void)closeFolderAnimated:(_Bool)arg1 withCompletion:(id)arg2;
- (void)_closeFolderController:(id)arg1 animated:(_Bool)arg2 withCompletion:(id)arg3;
-(void)alertView:(id)arg1 clickedButtonAtIndex:(int)arg2;
-(int)currentFolderIconListIndex;
-(int)currentIconListIndex;
- (void)noteIconStateChangedExternally;
- (void)unscatterAnimated:(_Bool)arg1 afterDelay:(double)arg2 withCompletion:(id)arg3;
- (void)_awayControllerUnlocked:(id)unlocked;
- (void)_lockScreenUIWillLock:(id)arg1;
- (void)applicationShortcutMenuDidDismiss:(id)arg1;
- (void)_dismissShortcutMenuAnimated:(_Bool)arg1 completionHandler:(id)arg2;
- (void)dismissShortcutMenuWithCompletionHandler:(id)arg1;
- (void)applicationShortcutMenuDidDismiss:(id)arg1;
- (SBRootFolder *)rootFolder;


- (SBRootIconListView*)currentFolderIconList;
- (SBRootIconListView*)dockListView;
- (SBRootIconListView*)currentRootIconList;

- (BOOL)isFolderIconView:(SBIconView *)view;
- (void)launchFirstApp:(SBIconView *)iconView;


-(id)_currentFolderController;

@end

@interface SBFolderController : NSObject
-(void)prepareToClose;
@property (nonatomic,retain) SBFolder * folder; 
@end



@interface SBFolderIcon : SBIcon
- (SBFolder *)folder;
- (void)iconImageDidUpdate:(SBIcon *)icon;
- (id)miniGridCellImageForIcon:(SBIcon*)icon;
@end

@interface SBIconImageView : UIView
@end

@interface SBIconBlurryBackgroundView : UIView
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)arg1;
- (void)didAddSubview:(id)arg1;
@end

@interface SBFolderIconBackgroundView : UIView
- (UIImageView *)customImageView;
- (void)setCustomImageView:(UIImageView *)imageView;
- (id)initWithDefaultSize;
- (id)_contentsImageForColor:(struct CGColor *)arg1;
@end


@interface SBFolderIconImageView : SBIconImageView
- (SBFolderIcon *)_folderIcon;
- (void)_showLeftMinigrid;
- (SBFolderIconBackgroundView*)backgroundView;

- (id)initWithFrame:(struct CGRect)arg1;
- (void)_setPageElements:(id)arg1;
- (void)_setupGridViewsInDefaultConfiguration;

-(void)hideInnerFolderImageView:(BOOL)hide;

- (void)setCustomIconImage:(UIImage *)image;
- (void)setCustomImageView:(UIImageView *)imageView;
- (UIImageView *)customImageView;

@end


@interface SBFolderIconView : SBIconView
- (SBFolder *)folder;
- (SBFolderIcon*)folderIcon;
- (SBFolderIconImageView*)_folderIconImageView;

- (void)scrollToGapOrTopIfFullOfPage:(unsigned long long)arg1 animated:(_Bool)arg2;
- (void)scrollToTopOfPage:(unsigned long long)arg1 animated:(_Bool)arg2;
- (void)scrollToFirstGapAnimated:(_Bool)arg1;
- (void)scrollToTopOfFirstPageAnimated:(_Bool)arg1;


- (void)folder:(id)arg1 didAddList:(id)arg2;

- (void)setCustomIconImage:(UIImage *)image;
- (void)setCustomImageView:(UIImageView *)imageView;
-(UIImage*)generateIconImage:(int)image ;
- (UIImage*)getGenericIconImage:(int)arg1;
- (void)setCustomFolderIcon;

- (UIView *)initWithFrame:(struct CGRect)frame;
- (UIImageView *)customImageView;
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
+ (struct CGSize)cellSpacing;
+ (struct CGSize)cellSize;
@end

@interface UIScrollViewPanGestureRecognizer : UIPanGestureRecognizer
@end

@interface SBSearchGesture : UIScrollViewPanGestureRecognizer
@end

@interface SBAppStatusBarManager : NSObject
+ (id)sharedInstance;
- (void)showStatusBar;
- (void)hideStatusBar;
@end

@interface SBUIController : NSObject
- (void)restoreContentAndUnscatterIconsAnimated:(BOOL)animated withCompletion:(id)completion;
@end

@interface SBDeviceLockController : NSObject
- (BOOL)attemptDeviceUnlockWithPassword:(NSString *)passcode appRequested:(BOOL)requested;
@end

@interface SBLockScreenManager : NSObject
- (void)_bioAuthenticated:(id)arg1;
- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options;
- (_Bool)biometricEventMonitorShouldRelockAfterBioUnlock:(id)arg1;
@end

@interface SpringBoard : UIApplication
- (SBApplication *)_accessibilityFrontMostApplication;
- (BOOL)addIcon:(SBIcon *)icon asDirty:(BOOL)dirty;
@end


@interface SBFolderIconZoomAnimator : NSObject
@property (nonatomic,retain,readonly) SBFolderIconView * targetIconView; 
@property (nonatomic,retain,readonly) SBFolderIcon * targetIcon; 

@end

@interface UIGestureRecognizerTarget : NSObject {
	id _target;
}
@end

@interface SBUIBiometricEventMonitor : NSObject

@end

@interface BioProtectController : NSObject
- (void)biometricEventMonitor:(SBUIBiometricEventMonitor*)arg1 handleBiometricEvent:(int)arg2;
- (void)showAlert;
- (void)launchApplicationWithIdentifier:(id)arg1;
-(BOOL)requiresAuthenticationForOpeningFolder:(SBFolder *)folder;
-(void)authenticateForOpeningFolder:(SBFolder *)folder;
-(BOOL)requiresAuthenticationForIdentifier:(id)identifier;
- (void)authenticateForIdentifier:(id)arg1 object:(id)arg2 selector:(SEL)arg3 arrayOfArgumentsAsNSValuePointers:(id)arg4;
@end



@interface CPDistributedMessagingCenter : NSObject
+(CPDistributedMessagingCenter*)centerNamed:(NSString*)serverName;
-(void)registerForMessageName:(NSString*)messageName target:(id)target selector:(SEL)selector;
-(NSDictionary*)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info;
-(void)runServerOnCurrentThread;
@end