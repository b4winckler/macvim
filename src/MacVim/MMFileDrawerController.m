#import "MMFileDrawerController.h"
#import "MMWindowController.h"

@implementation MMFileDrawerController

- (id)initWithWindowController:(MMWindowController *)controller {
  if ((self = [super initWithNibName:nil bundle:nil])) {
    windowController = controller;
    [self view]; // ensures the view is loaded
    [drawer setParentWindow:[windowController window]];
    [drawer open];
  }
  return self;
}

- (void)loadView {
  drawer = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200, 0) preferredEdge:NSMaxXEdge];
  NSLog(@"Drawer: %@", drawer);
  
  NSView *contentView = [drawer contentView];
  NSLog(@"Content view: %@, frame: %@", contentView, NSStringFromRect([contentView frame]));

  NSOutlineView *filesView = [[NSOutlineView alloc] initWithFrame:[contentView frame]];
  [drawer setContentView:filesView];
  [self setView:filesView];
  [filesView release];
}

- (void)dealloc {
  [drawer release];
  [super dealloc];
}


@end
