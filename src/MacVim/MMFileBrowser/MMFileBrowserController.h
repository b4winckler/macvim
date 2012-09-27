#import <Cocoa/Cocoa.h>

#import "MMFileBrowser.h"

@class MMWindowController;
@class MMFileBrowserFSItem;

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
