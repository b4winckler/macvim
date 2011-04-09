#import "MMFileDrawerController.h"
#import "MMWindowController.h"

// The FileSystemItem class is an adaptation of Apple's example in the Outline
// View Programming Topics document.

@interface FileSystemItem : NSObject {
  NSString *relativePath;
  FileSystemItem *parent;
  NSMutableArray *children;
}

+ (FileSystemItem *)rootItem;
- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)parentItem;
- (NSInteger)numberOfChildren; // Returns -1 for leaf nodes
- (FileSystemItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;

@end

@implementation FileSystemItem

static FileSystemItem *rootItem = nil;
static NSMutableArray *leafNode = nil;

+ (void)initialize {
  if (self == [FileSystemItem class]) {
    leafNode = [[NSMutableArray alloc] init];
  }
}

+ (FileSystemItem *)rootItem {
  if (rootItem == nil) {
    rootItem = [[FileSystemItem alloc] initWithPath:@"/" parent:nil];
  }
  return rootItem;
}

- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)parentItem {
  if ((self = [super init])) {
    relativePath = [[path lastPathComponent] copy];
    parent = parentItem;
  }
  return self;
}

// Creates, caches, and returns the array of children
// Loads children incrementally
- (NSArray *)children {
  if (children == nil) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [self fullPath];
    BOOL isDir, valid;

    valid = [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];

    if (valid && isDir) {
      NSArray *array = [fileManager contentsOfDirectoryAtPath:fullPath error:NULL];
      children = [[NSMutableArray alloc] initWithCapacity:[array count]];

      for (NSString *childPath in array) {
        FileSystemItem *child = [[FileSystemItem alloc] initWithPath:childPath parent:self];
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
  return relativePath;
}

- (NSString *)fullPath {
  // If no parent, return our own relative path
  if (parent == nil) {
    return relativePath;
  }

  // recurse up the hierarchy, prepending each parent’s path
  return [[parent fullPath] stringByAppendingPathComponent:relativePath];
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
  [relativePath release];
  [super dealloc];
}

@end


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

  NSOutlineView *filesView = [[NSOutlineView alloc] initWithFrame:NSZeroRect];
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


// Data Source methods
 
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return item == nil ? 1 : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return item == nil ? YES : ([item numberOfChildren] != -1);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  return item == nil ? [FileSystemItem rootItem] : [(FileSystemItem *)item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  return item == nil ? [[FileSystemItem rootItem] relativePath] : [item relativePath];
}


- (void)dealloc {
  [drawer release];
  [super dealloc];
}


@end
