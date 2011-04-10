#import "MMFileDrawerController.h"
#import "MMWindowController.h"
#import "MMAppController.h"
#import "ImageAndTextCell.h"


@interface FilesOutlineView : NSOutlineView
- (NSMenu *)menuForEvent:(NSEvent *)event;
@end

@implementation FilesOutlineView
- (NSMenu *)menuForEvent:(NSEvent *)event {
  NSInteger row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
  return [(MMFileDrawerController *)[self delegate] menuForRow:row];
}
@end


// The FileSystemItem class is an adaptation of Apple's example in the Outline
// View Programming Topics document.

// TODO use NSTreeNode
@interface FileSystemItem : NSObject {
  NSString *path;
  FileSystemItem *parent;
  NSMutableArray *children;
  NSImage *icon;
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
    icon = nil;
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

// TODO for now we don't really resize
- (NSImage *)icon {
  if (icon == nil) {
    icon = [[NSWorkspace sharedWorkspace] iconForFiles:[NSArray arrayWithObject:path]];
    [icon retain];
    [icon setSize:NSMakeSize(16, 16)];
  }
  return icon;
}

- (void)dealloc {
  if (children != leafNode) {
    [children release];
  }
  [path release];
  [icon release];
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

  FilesOutlineView *filesView = [[[FilesOutlineView alloc] initWithFrame:NSZeroRect] autorelease];
  [filesView setDelegate:self];
  [filesView setDataSource:self];
  [filesView setHeaderView:nil];
  NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:nil] autorelease];
  [column setDataCell:[[[ImageAndTextCell alloc] init] autorelease]];
  [filesView addTableColumn:column];
  [filesView setOutlineTableColumn:column];

  NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setAutohidesScrollers:YES];
  [scrollView setDocumentView:filesView];
  [drawer setContentView:scrollView];

  [self setView:filesView];
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
        [(NSOutlineView *)[self view] expandItem:rootItem];
        [drawer setParentWindow:[windowController window]];
        [drawer open];
      }
    }
  }
}

- (FileSystemItem *)itemAtRow:(NSInteger)row {
  return [(FilesOutlineView *)[self view] itemAtRow:row];
}

- (FileSystemItem *)selectedItem {
  return [self itemAtRow:[(FilesOutlineView *)[self view] selectedRow]];
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
  NSArray *files = [NSArray arrayWithObject:[[self selectedItem] fullPath]];
  // TODO what's the good way?
  [(MMAppController *)[NSApp delegate] openFiles:files withArguments:nil];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
  [imageAndTextCell setImage:[item icon]];
}

- (NSMenu *)menuForRow:(NSInteger)row {
  NSMenu *menu = [[[NSMenu alloc] init] autorelease];
  //NSMenuItem *item = [menu addItemWithTitle:@"Rename…" action:@selector(renameFile:) keyEquivalent:@""];
  //[item setTarget:self];
  //[item setTag:row];
  FileSystemItem *fsItem = [self itemAtRow:row];
  NSMenuItem *item = [menu addItemWithTitle:[NSString stringWithFormat:@"Reveal “%@” in Finder", [fsItem relativePath]]
                                     action:@selector(revealInFinder:)
                              keyEquivalent:@""];
  [item setTarget:self];
  [item setTag:row];
  return menu;
}


// Actions

- (void)renameFile:(NSMenuItem *)sender {
  FileSystemItem *item = [self itemAtRow:[sender tag]];
  NSLog(@"Rename: %@", [item fullPath]);
  [(FilesOutlineView *)[self view] editColumn:0 row:[sender tag] withEvent:nil select:YES];
}

- (void)revealInFinder:(NSMenuItem *)sender {
  NSString *path = [[self itemAtRow:[sender tag]] fullPath];
  NSArray *urls = [NSArray arrayWithObject:[NSURL fileURLWithPath:path]];
  [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
}


- (void)dealloc {
  [drawer release];
  [rootItem release];
  [super dealloc];
}


@end
