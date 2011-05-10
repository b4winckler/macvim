#import "MMFileDrawerController.h"
#import "MMWindowController.h"
#import "MMAppController.h"
#import "ImageAndTextCell.h"
#import "Miscellaneous.h"
#import "MMVimController.h"

#import <CoreServices/CoreServices.h>


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
- (BOOL)isLeaf;
- (void)clear;
- (FileSystemItem *)itemAtPath:(NSString *)itemPath;
@end

@interface FileSystemItem (Private)
- (FileSystemItem *)_itemAtPath:(NSArray *)components;
@end


BOOL isSwapFile(NSString *path) {
  if (!path) return NO;
  NSString *name = [path lastPathComponent];
  if ([name length] < 4) return NO;

  // NOTE: Vim swap files have names of type
  //   .original-file-name.sXY
  // where XY can be anything from "aa" to "wp".
  // We only detect "swp" for now.
  return [name characterAtIndex:0] == '.' &&
         [[name pathExtension] isEqualToString:@"swp"];
}

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
        // Don't add Vim swap files to browser
        if (isSwapFile(childPath))
          continue;

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

- (void)clear {
  [children release];
  children = nil;
}

- (BOOL)isLeaf {
  return [self children] == leafNode;
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

- (FileSystemItem *)itemAtPath:(NSString *)itemPath {
  NSArray *components = [itemPath pathComponents];
  NSLog(@"Components: %@", components);
  NSArray *root = [path pathComponents];
  NSLog(@"Root: %@", root);
  // minus one extra because paths from FSEvents have a trailing slash
  components = [components subarrayWithRange:NSMakeRange([root count], [components count] - [root count] - 1)];
  NSLog(@"Components: %@", components);
  return [self _itemAtPath:components];
}

- (FileSystemItem *)_itemAtPath:(NSArray *)components {
  if ([components count] == 0) {
    return self;
  } else {
    NSString *component = [components objectAtIndex:0];
    NSLog(@"Find: %@", component);
    for (FileSystemItem *child in [self children]) {
      if ([[child relativePath] isEqualToString:component]) {
        return [child _itemAtPath:[components subarrayWithRange:NSMakeRange(1, [components count] - 1)]];
      }
    }
  }

  return nil;
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



@interface MMFileDrawerController (Private)
- (FilesOutlineView *)outlineView;
@end


@implementation MMFileDrawerController

- (id)initWithWindowController:(MMWindowController *)controller {
  if ((self = [super initWithNibName:nil bundle:nil])) {
    windowController = controller;
    rootItem = nil;
    fsEventsStream = NULL;
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


- (void)setRoot:(NSString *)root
{
  root = [root stringByStandardizingPath];

  BOOL isDir;
  BOOL valid = [[NSFileManager defaultManager] fileExistsAtPath:root
                                                    isDirectory:&isDir];
  if (!(valid && isDir))
    return;

  if (rootItem) {
    [self unwatchRoot];
    [rootItem autorelease];
    rootItem = nil;
  }

  rootItem = [[FileSystemItem alloc] initWithPath:root parent:nil];
  [(NSOutlineView *)[self view] expandItem:rootItem];
  [self watchRoot];
}

- (void)open
{
  if (!rootItem) {
    NSString *root = [[windowController vimController]
                                                  objectForVimStateKey:@"pwd"];
    [self setRoot:(root ? root : @"~/")];
  }

  [drawer setParentWindow:[windowController window]];
  [drawer open];
}

- (void)close
{
  [drawer close];
}

- (void)toggle
{
  if (!rootItem) {
    NSString *root = [[windowController vimController]
                                                  objectForVimStateKey:@"pwd"];
    [self setRoot:(root ? root : @"~/")];
  }

  [drawer setParentWindow:[windowController window]];
  [drawer toggle:self];
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
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [[self selectedItem] fullPath];
  BOOL isDir;
  BOOL valid = [fileManager fileExistsAtPath:path isDirectory:&isDir];
  if (!valid || isDir)
    return; // Don't try to open directories

  // Force file to open in current window
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  BOOL openInCurrentWindow = [ud boolForKey:MMOpenInCurrentWindowKey];
  [ud setBool:YES forKey:MMOpenInCurrentWindowKey];

  NSArray *files = [NSArray arrayWithObject:path];
  [(MMAppController *)[NSApp delegate] openFiles:files withArguments:nil];

  [ud setBool:openInCurrentWindow forKey:MMOpenInCurrentWindowKey];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  ImageAndTextCell *imageAndTextCell = (ImageAndTextCell *)cell;
  [imageAndTextCell setImage:[item icon]];
}

- (NSMenu *)menuForRow:(NSInteger)row {
  NSMenu *menu = [[[NSMenu alloc] init] autorelease];
  NSMenuItem *item;
  //NSMenuItem *item = [menu addItemWithTitle:@"Rename…" action:@selector(renameFile:) keyEquivalent:@""];
  //[item setTarget:self];
  //[item setTag:row];
  FileSystemItem *fsItem = [self itemAtRow:row];
  [menu addItemWithTitle:[NSString stringWithFormat:@"Reveal “%@” in Finder", [fsItem relativePath]]
                  action:@selector(revealInFinder:)
           keyEquivalent:@""];
  [menu addItemWithTitle:@"New Folder" action:@selector(newFolder:) keyEquivalent:@""];
  for (item in [menu itemArray]) {
    [item setTarget:self];
    [item setTag:row];
  }
  return menu;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
        shouldEditTableColumn:(NSTableColumn *)tableColumn
                         item:(id)item
{
  // Called when an item was double-clicked.  Change the root to item clicked
  // on and expand.
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [item fullPath];
  BOOL isDir;
  BOOL valid = [fileManager fileExistsAtPath:path isDirectory:&isDir];
  if (valid && isDir) {
    [self setRoot:path];
    [[self outlineView] reloadData];
    [[self outlineView] expandItem:rootItem];
  }

  return NO;
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

- (void)newFolder:(NSMenuItem *)sender {
  FileSystemItem *item = [self itemAtRow:[sender tag]];
  NSString *path = [item fullPath];
  if ([item isLeaf]) {
    path = [path stringByDeletingLastPathComponent];
  }
  path = [path stringByAppendingPathComponent:@"untitled folder"];
  NSLog(@"create new folder: %@", path);
  [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:NULL];
}


// FSEvents

static void change_occured(ConstFSEventStreamRef stream,
                           void *watcher,
                           size_t eventCount,
                           void *paths,
                           const FSEventStreamEventFlags flags[],
                           const FSEventStreamEventId ids[]) {
  MMFileDrawerController *self = (MMFileDrawerController *)watcher;
  for (NSString *path in (NSArray *)paths) {
    [self changeOccurredAtPath:path];
  }
}

- (void)changeOccurredAtPath:(NSString *)path {
  NSLog(@"Change at: %@", path);
  FileSystemItem *item = [rootItem itemAtPath:path];
  if (item) {
    NSLog(@"Found item: %@", item);
    [item clear];
    [(FilesOutlineView *)[self view] reloadItem:item reloadChildren:YES];
  }
}

- (void)watchRoot {
  NSString *path = [rootItem fullPath];
  NSLog(@"Watch: %@", path);
  
  FSEventStreamContext context;
  context.version = 0;
  context.info = (void *)self;
  context.retain = NULL;
  context.release = NULL;
  context.copyDescription = NULL;

  fsEventsStream = FSEventStreamCreate(kCFAllocatorDefault,
                                       &change_occured,
                                       &context,
                                       (CFArrayRef)[NSArray arrayWithObject:path],
                                       kFSEventStreamEventIdSinceNow,
                                       1.5,
                                       // TODO MacVim doesn't deal with the root path changing afaik
                                       //kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagUseCFTypes);
                                       kFSEventStreamCreateFlagUseCFTypes);

  FSEventStreamScheduleWithRunLoop(fsEventsStream, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
  FSEventStreamStart(fsEventsStream);
}

- (void)unwatchRoot
{
  if (fsEventsStream != NULL) {
    FSEventStreamStop(fsEventsStream);
    FSEventStreamInvalidate(fsEventsStream);
    FSEventStreamRelease(fsEventsStream);
    fsEventsStream = NULL;
  }
}

- (void)dealloc {
  [drawer release];
  [rootItem release];
  [self unwatchRoot];

  [super dealloc];
}


- (FilesOutlineView *)outlineView
{
  return (FilesOutlineView *)[self view];
}

@end
