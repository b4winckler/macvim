#import <Cocoa/Cocoa.h>

@class MMWindowController;

@interface MMFileDrawerController : NSViewController <NSOutlineViewDataSource> {
  MMWindowController *windowController;
  NSDrawer *drawer;
}

- (id)initWithWindowController:(MMWindowController *)controller;

@end
