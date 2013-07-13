/* vi:set ts=8 sts=4 sw=4 ft=objc:
 *
 * VIM - Vi IMproved		by Bram Moolenaar
 *				MacVim GUI port by Bjorn Winckler
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */

#import "MacVim.h"



@class PSMTabBarControl;
@class MMWindow;
@class MMFullScreenWindow;
@class MMVimController;
@class MMVimView;
@class MMFileBrowserController;

@interface MMWindowController : NSWindowController
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
    // 10.6 has turned delegate messages into formal protocols
    <NSWindowDelegate, NSSplitViewDelegate>
#endif
{
    NSTabView           *tabView;
    PSMTabBarControl    *tabBarControl;
    MMVimController     *vimController;
    NSSplitView         *splitView;
    MMVimView           *vimView;
    NSView              *sidebarView;
    BOOL                setupDone;
    BOOL                windowPresented;
    BOOL                shouldPlaceVimView;
    BOOL                shouldResizeWindow;
    BOOL                shouldRestoreUserTopLeft;
    BOOL                shouldMaximizeWindow;
    int                 updateToolbarFlag;
    NSString            *windowAutosaveKey;
    BOOL                fullScreenEnabled;
    MMFullScreenWindow  *fullScreenWindow;
    int                 fullScreenOptions;
    BOOL                delayEnterFullScreen;
    NSRect              preFullScreenFrame;
    MMWindow            *decoratedWindow;
    NSString            *lastSetTitle;
    int                 userRows;
    int                 userCols;
    NSPoint             userTopLeft;
    NSPoint             defaultTopLeft;
    BOOL                vimTaskSelectedTab;
    MMFileBrowserController *fileBrowserController;
    NSToolbar           *toolbar;
}

- (id)initWithVimController:(MMVimController *)controller;
- (MMVimController *)vimController;
- (MMVimView *)vimView;
- (NSString *)windowAutosaveKey;
- (void)setWindowAutosaveKey:(NSString *)key;
- (void)cleanup;
- (void)openWindow;
- (BOOL)presentWindow:(id)unused;
- (void)setTextDimensionsWithRows:(int)rows
                          columns:(int)cols
                           isLive:(BOOL)live
                          isReply:(BOOL)reply;
- (void)zoomWithRows:(int)rows columns:(int)cols state:(int)state;
- (void)setTitle:(NSString *)title;
- (void)setDocumentFilename:(NSString *)filename;
- (void)setToolbar:(NSToolbar *)toolbar;
- (void)createScrollbarWithIdentifier:(int32_t)ident type:(int)type;
- (BOOL)destroyScrollbarWithIdentifier:(int32_t)ident;
- (BOOL)showScrollbarWithIdentifier:(int32_t)ident state:(BOOL)visible;
- (void)setScrollbarPosition:(int)pos length:(int)len identifier:(int32_t)ident;
- (void)setScrollbarThumbValue:(float)val proportion:(float)prop
                    identifier:(int32_t)ident;
- (void)setDefaultColorsBackground:(NSColor *)back foreground:(NSColor *)fore;
- (void)setFont:(NSFont *)font;
- (void)setWideFont:(NSFont *)font;
- (void)processInputQueueDidFinish;
- (void)showTabBar:(BOOL)on;
- (void)showToolbar:(BOOL)on size:(int)size mode:(int)mode;
- (void)setMouseShape:(int)shape;
- (void)adjustLinespace:(int)linespace;
- (void)liveResizeWillStart;
- (void)liveResizeDidEnd;

- (void)enterFullScreen:(int)fuoptions backgroundColor:(NSColor *)back;
- (void)leaveFullScreen;
- (void)setFullScreenBackgroundColor:(NSColor *)back;
- (void)invFullScreen:(id)sender;

- (void)setBufferModified:(BOOL)mod;
- (void)setTopLeft:(NSPoint)pt;
- (BOOL)getDefaultTopLeft:(NSPoint*)pt;

- (void)updateTabsWithData:(NSData *)data;
- (void)selectTabWithIndex:(int)idx;

- (void)collapseSidebar:(BOOL)on;
- (BOOL)isSidebarCollapsed;
- (void)setSidebarView:(NSView *)view leftEdge:(BOOL)left;

- (IBAction)addNewTab:(id)sender;
- (IBAction)toggleToolbar:(id)sender;
- (IBAction)performClose:(id)sender;
- (IBAction)findNext:(id)sender;
- (IBAction)findPrevious:(id)sender;
- (IBAction)vimMenuItemAction:(id)sender;
- (IBAction)vimToolbarItemAction:(id)sender;
- (IBAction)fontSizeUp:(id)sender;
- (IBAction)fontSizeDown:(id)sender;
- (IBAction)findAndReplace:(id)sender;
- (IBAction)zoom:(id)sender;
- (IBAction)openFileBrowser:(id)sender;
- (IBAction)closeFileBrowser:(id)sender;
- (IBAction)toggleFileBrowser:(id)sender;
- (IBAction)selectInFileBrowser:(id)sender;
- (IBAction)revealInFileBrowser:(id)sender;
- (IBAction)sidebarEdgePreferenceChanged:(id)sender;

@end
