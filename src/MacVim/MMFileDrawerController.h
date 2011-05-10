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
- (FileSystemItem *)itemAtRow:(NSInteger)row;
- (FileSystemItem *)selectedItem;
- (NSMenu *)menuForRow:(NSInteger)row;
- (void)watchRoot;
- (void)unwatchRoot;
- (void)changeOccurredAtPath:(NSString *)path;

@end
