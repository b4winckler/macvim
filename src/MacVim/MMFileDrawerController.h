#import <Cocoa/Cocoa.h>

@class MMWindowController;
@class FileSystemItem;

@interface MMFileDrawerController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate> {
  MMWindowController *windowController;
  NSDrawer *drawer;
  FileSystemItem *rootItem;
}

- (id)initWithWindowController:(MMWindowController *)controller;
- (void)setRootFilename:(NSString *)filename;
- (FileSystemItem *)itemAtRow:(NSInteger)row;
- (FileSystemItem *)selectedItem;
- (NSMenu *)menuForRow:(NSInteger)row;

@end
