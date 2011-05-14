#import <Cocoa/Cocoa.h>

@class MMWindowController;
@class FileSystemItem;

@interface MMFileDrawerController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate> {
  MMWindowController *windowController;
  NSDrawer *drawer;
  FileSystemItem *rootItem;
  FSEventStreamRef fsEventsStream;
}

- (id)initWithWindowController:(MMWindowController *)controller;
- (void)setRoot:(NSString *)root;
- (void)open;
- (void)close;
- (void)toggle;

- (NSMenu *)menuForRow:(NSInteger)row;

@end
