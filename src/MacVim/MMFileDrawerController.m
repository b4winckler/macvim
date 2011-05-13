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

- (BOOL)acceptsFirstResponder {
  return NO;
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
  NSInteger row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
  return [(MMFileDrawerController *)[self delegate] menuForRow:row];
}

@end


// The FileSystemItem class is an adaptation of Apple's example in the Outline
// View Programming Topics document.

@interface FileSystemItem : NSObject {
  NSString *path;
  FileSystemItem *parent;
  NSMutableArray *children;
  NSImage *icon;
  BOOL includesHiddenFiles;
}

@property (nonatomic, assign) BOOL includesHiddenFiles;

- (id)initWithPath:(NSString *)path parent:(FileSystemItem *)parentItem;
- (NSInteger)numberOfChildren; // Returns -1 for leaf nodes
- (FileSystemItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;
- (BOOL)isLeaf;
- (void)clear;
- (void)reloadRecursive:(BOOL)recursive;
- (FileSystemItem *)itemAtPath:(NSString *)itemPath;

@end

@interface FileSystemItem (Private)
- (FileSystemItem *)_itemAtPath:(NSArray *)components;
@end


@implementation FileSystemItem

static NSMutableArray *leafNode = nil;

+ (void)initialize {
  if (self == [FileSystemItem class]) {
    leafNode = [[NSMutableArray alloc] init];
  }
}

@synthesize includesHiddenFiles;

- (id)initWithPath:(NSString *)thePath parent:(FileSystemItem *)parentItem {
  if ((self = [super init])) {
    icon = nil;
    path = [thePath retain];
    parent = parentItem;
    if (parent) {
      includesHiddenFiles = parent.includesHiddenFiles;
    } else {
      includesHiddenFiles = NO;
    }
  }
  return self;
}

// * Creates, caches, and returns the array of children
// * Loads children incrementally
- (NSArray *)children {
  if (children == nil) {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDir, valid;
    valid = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (valid && isDir) {
      // Create a dummy array, which is replaced by -[FileSystemItem reloadRecursive]
      children = [NSArray new];
      [self reloadRecursive:NO];
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

- (void)reloadRecursive:(BOOL)recursive {
  // Only reload items that have been loaded before
  if (children) {
    // NSLog(@"Reload: %@", path);
    if (parent) {
      includesHiddenFiles = parent.includesHiddenFiles;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *reloaded;

    NSArray *entries = [fileManager contentsOfDirectoryAtPath:path error:NULL];
    reloaded = [[NSMutableArray alloc] initWithCapacity:[entries count]];

    for (NSString *childName in entries) {
      BOOL isHiddenFile = [childName characterAtIndex:0] == '.';
      if (isHiddenFile && !includesHiddenFiles) {
        // It's a hidden file which are currently not visible.
        continue;
      } else if (isHiddenFile && [childName length] >= 4) {
        // Does include hidden files, but never add Vim swap files to browser.
        //
        // Vim swap files have names of type
        //   .original-file-name.sXY
        // where XY can be anything from "aa" to "wp".
        NSString *last3 = [childName substringFromIndex:[childName length]-3];
        if ([last3 compare:@"saa"] >= 0 && [last3 compare:@"swp"] <= 0) {
          // It's a swap file, ignore it.
          continue;
        }
      }

      FileSystemItem *child = nil;
      // Check if we already have an item for the child path
      for (FileSystemItem *item in children) {
        if ([[item relativePath] isEqualToString:childName]) {
          child = item;
          break;
        }
      }
      if (child) {
        // NSLog(@"Already have item for child: %@", childName);
        // If an item already existed use it and reload its children
        [reloaded addObject:child];
        if (recursive && ![child isLeaf]) {
          [child reloadRecursive:YES];
        }
        [children removeObject:child];
      } else {
        // New child, so create a new item
        child = [[FileSystemItem alloc] initWithPath:[path stringByAppendingPathComponent:childName] parent:self];
        [reloaded addObject:child];
        [child release];
      }
    }

    [children release];
    children = reloaded;
  } else {
    // NSLog(@"Not loaded yet, so don't reload: %@", path);
  }
}

- (BOOL)isLeaf {
  if (children) {
    return children == leafNode;
  } else {
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return !isDir;
  }
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
  if ([self isLeaf]) {
    return -1;
  } else {
    return [[self children] count];
  }
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
  NSArray *root = [path pathComponents];
  // minus one extra because paths from FSEvents have a trailing slash
  components = [components subarrayWithRange:NSMakeRange([root count], [components count] - [root count] - 1)];
  return [self _itemAtPath:components];
}

- (FileSystemItem *)_itemAtPath:(NSArray *)components {
  if ([components count] == 0) {
    return self;
  } else {
    NSString *component = [components objectAtIndex:0];
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
- (void)pwdChanged:(NSNotification *)notification;
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
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSRectEdge edge = [ud integerForKey:MMDrawerPreferredEdgeKey] <= 0
                  ? NSMaxXEdge
                  : NSMinXEdge;

  drawer = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200, 0)
                                   preferredEdge:edge];

  FilesOutlineView *filesView = [[[FilesOutlineView alloc] initWithFrame:NSZeroRect] autorelease];
  [filesView setDelegate:self];
  [filesView setDataSource:self];
  [filesView setHeaderView:nil];
  NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:nil] autorelease];
  ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
  [cell setEditable:YES];
  [column setDataCell:cell];
  [filesView addTableColumn:column];
  [filesView setOutlineTableColumn:column];

  NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSZeroRect] autorelease];
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setAutohidesScrollers:YES];
  [scrollView setDocumentView:filesView];
  [drawer setContentView:scrollView];

  [self setView:filesView];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(pwdChanged:)
                                               name:@"MMPwdChanged"
                                             object:[windowController vimController]];
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

- (NSMenu *)menuForRow:(NSInteger)row {
  NSMenu *menu = [[[NSMenu alloc] init] autorelease];
  NSMenuItem *item;
  FileSystemItem *fsItem = [self itemAtRow:row];
  [menu addItemWithTitle:@"Rename…" action:@selector(renameFile:) keyEquivalent:@""];
  [menu addItemWithTitle:[NSString stringWithFormat:@"Reveal “%@” in Finder", [fsItem relativePath]]
                  action:@selector(revealInFinder:)
           keyEquivalent:@""];
  [menu addItemWithTitle:@"New Folder" action:@selector(newFolder:) keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  item = [menu addItemWithTitle:@"Show hidden files" action:@selector(toggleShowHiddenFiles:) keyEquivalent:@""];
  [item setState:rootItem.includesHiddenFiles ? NSOnState : NSOffState];
  for (item in [menu itemArray]) {
    [item setTarget:self];
    [item setTag:row];
  }
  return menu;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [[self selectedItem] fullPath];
  BOOL isDir;
  BOOL valid = [fileManager fileExistsAtPath:path isDirectory:&isDir];
  if (!valid || isDir)
    return; // Don't try to open directories

  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  BOOL openInCurrentWindow = [ud boolForKey:MMOpenInCurrentWindowKey];
  int layout = [ud integerForKey:MMOpenLayoutKey];

  // Force file to open in current window
  [ud setBool:YES forKey:MMOpenInCurrentWindowKey];

  NSEvent *event = [NSApp currentEvent];
  if ([event modifierFlags] & NSAlternateKeyMask) {
    if (layout == MMLayoutTabs) {
      // The user normally creates a new tab when opening a file,
      // so open this file in the current one
      [ud setInteger:MMLayoutArglist forKey:MMOpenLayoutKey];
    } else {
      // The user normally opens a file in the current tab,
      // so open this file in a new one
      [ud setInteger:MMLayoutTabs forKey:MMOpenLayoutKey];
    }
  }

  // Open file
  NSArray *files = [NSArray arrayWithObject:path];
  [(MMAppController *)[NSApp delegate] openFiles:files withArguments:nil];

  // Restore preferences
  [ud setBool:openInCurrentWindow forKey:MMOpenInCurrentWindowKey];
  [ud setInteger:layout forKey:MMOpenLayoutKey];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  [(ImageAndTextCell *)cell setImage:[item icon]];
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
    // Tell Vim to change the pwd.  As a side effect this will cause a new root
    // to be set to the folder the user just double-clicked on.
    NSString *input = [NSString stringWithFormat:
                  @"<C-\\><C-N>:exe \"cd \" . fnameescape(\"%@\")<CR>", path];
    [[windowController vimController] addVimInput:input];
  }

  return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  NSString *dir = [[item fullPath] stringByDeletingLastPathComponent];
  NSString *newPath = [dir stringByAppendingPathComponent:(NSString *)object];
  NSError *error = nil;
  BOOL moved = [[NSFileManager defaultManager] moveItemAtPath:[item fullPath]
                                                       toPath:newPath
                                                        error:&error];
  if (!moved) {
    NSLog(@"[!] Unable to rename `%@' to `%@'. Error: %@", [item fullPath], newPath, [error localizedDescription]);
  }
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

  int i = 2;
  NSString *result = path;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  while ([fileManager fileExistsAtPath:result]) {
    result = [NSString stringWithFormat:@"%@ %d", path, i];
    i++;
  }

  [fileManager createDirectoryAtPath:result
         withIntermediateDirectories:NO
                          attributes:nil
                               error:NULL];
}

- (void)toggleShowHiddenFiles:(NSMenuItem *)sender {
  rootItem.includesHiddenFiles = !rootItem.includesHiddenFiles;
  [rootItem reloadRecursive:YES];
  [[self outlineView] reloadData];
  [[self outlineView] expandItem:rootItem];
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
  FileSystemItem *item = [rootItem itemAtPath:path];
  if (item) {
    // NSLog(@"Change occurred in path: %@", [item fullPath]);
    [item reloadRecursive:NO]; // the change occurred in *this* item only
    [(FilesOutlineView *)[self view] reloadItem:item reloadChildren:YES];
  }
}

- (void)watchRoot {
  NSString *path = [rootItem fullPath];
  // NSLog(@"Watch: %@", path);
  
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
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [drawer release];
  [rootItem release];
  [self unwatchRoot];

  [super dealloc];
}


- (FilesOutlineView *)outlineView
{
  return (FilesOutlineView *)[self view];
}

- (void)pwdChanged:(NSNotification *)notification
{
  NSString *pwd = [[notification userInfo] objectForKey:@"pwd"];
  if (pwd) {
    [self setRoot:pwd];
    [[self outlineView] reloadData];
    [[self outlineView] expandItem:rootItem];
  }
}

@end
