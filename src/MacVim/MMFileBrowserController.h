#import <Cocoa/Cocoa.h>

@class MMWindowController;
@class MMFileBrowserFSItem;
@class MMFileBrowser;

@protocol MMFileBrowserDelegate <NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate>
- (void)outlineViewSelectionIsChanging:(NSNotification *)notification;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
- (NSMenu *)menuForRow:(NSInteger)row;
- (void)openSelectedFilesInCurrentWindowWithLayout:(int)layout;
@end

@interface MMFileBrowserController : NSViewController <MMFileBrowserDelegate> {
  MMWindowController *windowController;
  MMFileBrowser *fileBrowser;
  NSPathControl *pathControl;
  MMFileBrowserFSItem *rootItem;
  FSEventStreamRef fsEventsStream;
  BOOL userHasChangedSelection;
  BOOL viewLoaded;
  NSArray *dragItems;
}

- (id)initWithWindowController:(MMWindowController *)controller;
- (void)cleanup;
- (void)setRoot:(NSString *)root;
- (void)setNextKeyView:(NSView *)nextKeyView;
- (void)makeFirstResponder:(id)sender;
- (void)selectInBrowser;
- (void)selectInBrowserByExpandingItems;

- (NSMenu *)menuForRow:(NSInteger)row;

@end
