#import "MMFileDrawerController.h"
#import "MMWindowController.h"
#import "MMAppController.h"

// The FileSystemItem class is an adaptation of Apple's example in the Outline
// View Programming Topics document.

@interface FileSystemItem : NSObject {
  NSString *path;
  FileSystemItem *parent;
  NSMutableArray *children;
}

- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)parentItem;
- (NSInteger)numberOfChildren; // Returns -1 for leaf nodes
- (FileSystemItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;

@end

@implementation FileSystemItem

static NSMutableArray *leafNode = nil;

+ (void)initialize {
  if (self == [FileSystemItem class]) {
    leafNode = [[NSMutableArray alloc] init];
  }
}

- (id)initWithPath:(NSString *)thePath parent:(FileSystemItem *)parentItem {
  if ((self = [super init])) {
    path = [thePath retain];
    parent = parentItem;
  }
  return self;
}

// Creates, caches, and returns the array of children
// Loads children incrementally
- (NSArray *)children {
  if (children == nil) {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir, valid;
    valid = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (valid && isDir) {
      NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:NULL];
      children = [[NSMutableArray alloc] initWithCapacity:[array count]];

      for (NSString *childPath in array) {
        FileSystemItem *child = [[FileSystemItem alloc] initWithPath:[path stringByAppendingPathComponent:childPath] parent:self];
        [children addObject:child];
        [child release];
      }
    } else {
      children = leafNode;
    }
  }
  return children;
}

- (NSString *)relativePath {
  return [path lastPathComponent];
}

- (NSString *)fullPath {
  return path;
}

- (FileSystemItem *)childAtIndex:(NSUInteger)n {
  return [[self children] objectAtIndex:n];
}

- (NSInteger)numberOfChildren {
  NSArray *tmp = [self children];
  return tmp == leafNode ? -1 : [tmp count];
}

- (void)dealloc {
  if (children != leafNode) {
    [children release];
  }
  [path release];
  [super dealloc];
}

@end


@implementation MMFileDrawerController

- (id)initWithWindowController:(MMWindowController *)controller {
  if ((self = [super initWithNibName:nil bundle:nil])) {
    windowController = controller;
    rootItem = nil;
  }
  return self;
}


- (void)loadView {
  drawer = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200, 0) preferredEdge:NSMaxXEdge];

  NSOutlineView *filesView = [[NSOutlineView alloc] initWithFrame:NSZeroRect];
  [filesView setDelegate:self];
  [filesView setDataSource:self];
  [filesView setHeaderView:nil];
  NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:nil];
  [filesView addTableColumn:column];
  [filesView setOutlineTableColumn:column];
  [column release];

  NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setAutohidesScrollers:YES];
  [scrollView setDocumentView:filesView];
  [drawer setContentView:scrollView];
  [scrollView release];

  [self setView:filesView];
  [filesView release];
}


// TODO This is really not the right way to get the root path,
// but for now I focus on getting the drawer done.
- (void)setRootFilename:(NSString *)filename {
  if (rootItem == nil) {
    NSRange range = [filename rangeOfString:@"("];
    if (range.location != NSNotFound) {
      range.location += 1;
      NSRange end = [filename rangeOfString:@")" options:NSBackwardsSearch];
      range.length = end.location - range.location;
      NSString *expandedPath = [[filename substringWithRange:range] stringByStandardizingPath];

      BOOL isDir, valid;
      valid = [[NSFileManager defaultManager] fileExistsAtPath:expandedPath isDirectory:&isDir];
      if (valid && isDir) {
        rootItem = [[FileSystemItem alloc] initWithPath:expandedPath parent:nil];
        [self view]; // loads the view
        [drawer setParentWindow:[windowController window]];
        [drawer open];
      }
    }
  }
}


// Data Source methods
 
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return item == nil ? 1 : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return item == nil ? YES : ([item numberOfChildren] != -1);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  return item == nil ? rootItem : [(FileSystemItem *)item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  return item == nil ? [rootItem relativePath] : [item relativePath];
}


// Delegate methods

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  NSOutlineView *view = (NSOutlineView *)[self view];
  NSString *path = [(FileSystemItem *)[view itemAtRow:[view selectedRow]] fullPath];
  // TODO what's the good way?
  [(MMAppController *)[NSApp delegate] openFiles:[NSArray arrayWithObject:path] withArguments:nil];
}


- (void)dealloc {
  [drawer release];
  [rootItem release];
  [super dealloc];
}


@end
