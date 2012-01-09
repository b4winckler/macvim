#import "MMFileBrowserController.h"
#import "MMWindowController.h"
#import "MMAppController.h"
#import "ImageAndTextCell.h"
#import "Miscellaneous.h"
#import "MMVimController.h"

#import <CoreServices/CoreServices.h>

#define DRAG_MOVE_FILES @"MoveFiles"

// ****************************************************************************
// File system model
// ****************************************************************************

// The MMFileBrowserFSItem class is an adaptation of Apple's example in the
// Outline View Programming Topics document.

@interface MMFileBrowserFSItem : NSObject {
  NSString *path;
  MMFileBrowserFSItem *parent;
  NSMutableArray *children;
  MMVimController *vim;
  NSImage *icon;
  BOOL includesHiddenFiles;
  BOOL ignoreNextReload;
}

@property (nonatomic, assign) BOOL includesHiddenFiles, ignoreNextReload;
@property (readonly) MMFileBrowserFSItem *parent;

- (id)initWithPath:(NSString *)path parent:(MMFileBrowserFSItem *)parentItem vim:(MMVimController *)vim;
- (NSInteger)numberOfChildren; // Returns -1 for leaf nodes
- (MMFileBrowserFSItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;
- (BOOL)isLeaf;
- (BOOL)reloadRecursive:(BOOL)recursive;
- (MMFileBrowserFSItem *)itemAtPath:(NSString *)itemPath;
- (MMFileBrowserFSItem *)itemWithName:(NSString *)name;
- (NSArray *)parents;

@end

@interface MMFileBrowserFSItem (Private)
- (MMFileBrowserFSItem *)_itemAtPath:(NSArray *)components;
- (BOOL)_ignoreFile:(NSString *)filename;
@end


@implementation MMFileBrowserFSItem

static NSMutableArray *leafNode = nil;

+ (void)initialize {
  if (self == [MMFileBrowserFSItem class]) {
    leafNode = [[NSMutableArray alloc] init];
  }
}

@synthesize parent, includesHiddenFiles, ignoreNextReload;

- (id)initWithPath:(NSString *)thePath parent:(MMFileBrowserFSItem *)parentItem vim:(MMVimController *)vimInstance {
  if ((self = [super init])) {
    icon = nil;
    path = [thePath retain];
    parent = parentItem;
    vim = vimInstance;
    if (parent) {
      includesHiddenFiles = parent.includesHiddenFiles;
    } else {
      includesHiddenFiles = NO;
    }
    ignoreNextReload = NO;
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
      // Create a dummy array, which is replaced by -[MMFileBrowserFSItem reloadRecursive]
      children = [NSArray new];
      [self reloadRecursive:NO];
    } else {
      children = leafNode;
    }
  }
  return children;
}

// Returns YES if the children have been reloaded, otherwise it returns NO.
//
// This is really only so the controller knows whether or not to reload the view.
- (BOOL)reloadRecursive:(BOOL)recursive {
  if (children) {
    // Only reload items that have been loaded before
    // NSLog(@"Reload: %@", path);
    if (parent) {
      includesHiddenFiles = parent.includesHiddenFiles;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *reloaded;

    NSArray *entries = [[fileManager contentsOfDirectoryAtPath:path error:NULL]
                         sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    reloaded = [[NSMutableArray alloc] initWithCapacity:[entries count]];

    for (NSString *childName in entries) {
      if ([self _ignoreFile:childName]) {
        continue;
      }

      MMFileBrowserFSItem *child = nil;
      // Check if we already have an item for the child path
      for (MMFileBrowserFSItem *item in children) {
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
        child = [[MMFileBrowserFSItem alloc] initWithPath:[path stringByAppendingPathComponent:childName]
                                              parent:self
                                                 vim:vim];
        [reloaded addObject:child];
        [child release];
      }
    }

    if (children != leafNode) {
      [children release];
    }
    children = reloaded;
    return YES;
  } else {
    // NSLog(@"Not loaded yet, so don't reload: %@", path);
  }
  return NO;
}

- (BOOL)_ignoreFile:(NSString *)filename {
  BOOL isHiddenFile = [filename characterAtIndex:0] == '.';
  if (isHiddenFile && !includesHiddenFiles) {
    // It's a hidden file which are currently not visible.
    return YES;
  } else if (isHiddenFile && [filename length] >= 4) {
    // Does include hidden files, but never add Vim swap files to browser.
    //
    // Vim swap files have names of type
    //   .original-file-name.sXY
    // where XY can be anything from "aa" to "wp".
    NSString *last4 = [filename substringFromIndex:[filename length]-4];
    if ([last4 compare:@".saa"] >= 0 && [last4 compare:@".swp"] <= 0) {
      // It's a swap file, ignore it.
      return YES;
    }
  } else if (!includesHiddenFiles) {
    NSString *eval = [NSString stringWithFormat:@"empty(expand(fnameescape('%@')))", filename];
    NSString *result = [vim evaluateVimExpression:eval];
    return [result isEqualToString:@"1"];
  }
  return NO;
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

// Returns `self' if it's a directory item, otherwise it returns the parent item.
- (MMFileBrowserFSItem *)dirItem {
  return [self isLeaf] ? parent : self;
}

- (NSString *)relativePath {
  return [path lastPathComponent];
}

- (NSString *)fullPath {
  return path;
}

- (MMFileBrowserFSItem *)childAtIndex:(NSUInteger)n {
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

- (MMFileBrowserFSItem *)itemAtPath:(NSString *)itemPath {
  if ([itemPath hasSuffix:@"/"])
    itemPath = [itemPath stringByStandardizingPath];
  NSArray *components = [itemPath pathComponents];
  NSArray *root = [path pathComponents];

  // check if itemPath is enclosed into the current directory
  if([components count] < [root count])
    return nil;
  if(![[components subarrayWithRange:NSMakeRange(0, [root count])] isEqualToArray:root])
    return nil;

  // minus one extra because paths from FSEvents have a trailing slash
  components = [components subarrayWithRange:NSMakeRange([root count], [components count] - [root count])];
  return [self _itemAtPath:components];
}

- (MMFileBrowserFSItem *)_itemAtPath:(NSArray *)components {
  if ([components count] == 0) {
    return self;
  } else {
    MMFileBrowserFSItem *child = [self itemWithName:[components objectAtIndex:0]];
    if (child) {
      return [child _itemAtPath:[components subarrayWithRange:NSMakeRange(1, [components count] - 1)]];
    }
  }
  return nil;
}

- (MMFileBrowserFSItem *)itemWithName:(NSString *)name {
  for (MMFileBrowserFSItem *child in [self children]) {
    if ([[child relativePath] isEqualToString:name]) {
      return child;
    }
  }
  return nil;
}

- (NSArray *)parents {
  NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
  id item = parent;
  while(item != nil) {
    [result addObject:item];
    item = [item parent];
  }
  return result;
}

- (void)dealloc {
  if (children != leafNode) {
    [children release];
  }
  [path release];
  [icon release];
  vim = nil;
  [super dealloc];
}

@end

// ****************************************************************************
// Views
// ****************************************************************************

@interface MMFileBrowserContainerView : NSView
@end

@implementation MMFileBrowserContainerView

- (BOOL) isFlipped {
  return YES;
}

@end

#define ENTER_KEY_CODE 36
#define TAB_KEY_CODE 48
#define ESCAPE_KEY_CODE 53
#define LEFT_KEY_CODE 123
#define RIGHT_KEY_CODE 124
#define DOWN_KEY_CODE 125
#define UP_KEY_CODE 126

static NSString *LEFT_KEY_CHAR, *RIGHT_KEY_CHAR, *DOWN_KEY_CHAR, *UP_KEY_CHAR;

@interface MMFileBrowser : NSOutlineView
- (void)makeFirstResponder;
- (NSMenu *)menuForEvent:(NSEvent *)event;
- (void)cancelOperation:(id)sender;
- (void)expandParentsOfItem:(id)item;
- (void)selectItem:(id)item;
- (NSEvent *)keyEventWithEvent:(NSEvent *)event character:(NSString *)character code:(unsigned short)code;
- (void)sendSelectionChangedNotification;
@end

@implementation MMFileBrowser

- (id)initWithFrame:(NSRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.refusesFirstResponder = YES;
  }
  return self;
}

- (BOOL)becomeFirstResponder {
  if (!self.refusesFirstResponder) {
    [self setNeedsDisplay];
  }
  return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
  self.refusesFirstResponder = YES;
  [self setNeedsDisplay];
  return YES;
}

- (void)makeFirstResponder {
  self.refusesFirstResponder = NO;
  [[self window] makeFirstResponder:self];
}

- (void)cancelOperation:(id)sender {
  // Pressing Esc will select the next key view, which should be the text view
  [[self window] selectNextKeyView:nil];
}

- (void)mouseDown:(NSEvent *)event {
  NSInteger before = self.selectedRow;
  [super mouseDown:event];
  // In case the item is not a directory and was already selected, then force
  // send the selection did change delegate messagges.
  if (event.clickCount == 1 &&
        self.selectedRow == before &&
          ![self isExpandable:[self itemAtRow:self.selectedRow]]) {
    [self sendSelectionChangedNotification];
  }
}

- (NSEvent *)keyEventWithEvent:(NSEvent *)event character:(NSString *)character code:(unsigned short)code {
  return [NSEvent keyEventWithType:event.type
                          location:event.locationInWindow
                     modifierFlags:event.modifierFlags
                         timestamp:event.timestamp
                      windowNumber:event.windowNumber
                           context:event.context
                        characters:character
       charactersIgnoringModifiers:character
                         isARepeat:event.isARepeat
                           keyCode:code];
}

- (void)sendSelectionChangedNotification {
  // These methods aren't really included in the NSOutlineViewDelegate protocol (the docs say
  // it's because of some error), so use performSelector to get rid of warnings.
  [self.delegate performSelector:@selector(outlineViewSelectionIsChanging:) withObject:self];
  [self.delegate performSelector:@selector(outlineViewSelectionDidChange:) withObject:self];
}

- (void)keyDown:(NSEvent *)event {
  if (event.keyCode == ENTER_KEY_CODE) {
    if (event.modifierFlags & NSControlKeyMask) {
      NSMenu *menu = [(MMFileBrowserController *)[self delegate] menuForRow:self.selectedRow];
      NSPoint location = [self rectOfRow:self.selectedRow].origin;
      location.x -= menu.size.width;
      [menu popUpMenuPositioningItem:[menu itemAtIndex:0]
                          atLocation:location
                              inView:self];
    } else {
      [self sendSelectionChangedNotification];
    }
    return;
  } else if (event.keyCode != TAB_KEY_CODE && event.keyCode != ESCAPE_KEY_CODE
      && event.keyCode != LEFT_KEY_CODE && event.keyCode != RIGHT_KEY_CODE
      && event.keyCode != DOWN_KEY_CODE && event.keyCode != UP_KEY_CODE) {
    switch ([[event.characters uppercaseString] characterAtIndex:0]) {
    case 'H':
      LEFT_KEY_CHAR = [NSString stringWithFormat:@"%C", 0xf702];
      event = [self keyEventWithEvent:event character:LEFT_KEY_CHAR code:LEFT_KEY_CODE];
      break;
    case 'L':
      RIGHT_KEY_CHAR = [NSString stringWithFormat:@"%C", 0xf703];
      event = [self keyEventWithEvent:event character:RIGHT_KEY_CHAR code:RIGHT_KEY_CODE];
      break;
    case 'J':
      DOWN_KEY_CHAR = [NSString stringWithFormat:@"%C", 0xf701];
      event = [self keyEventWithEvent:event character:DOWN_KEY_CHAR code:DOWN_KEY_CODE];
      break;
    case 'K':
      UP_KEY_CHAR = [NSString stringWithFormat:@"%C", 0xf700];
      event = [self keyEventWithEvent:event character:UP_KEY_CHAR code:UP_KEY_CODE];
      break;
    case 'T':
      [(MMFileBrowserController *)[self delegate] openSelectedFilesInCurrentWindowWithLayout:MMLayoutTabs];
      event = nil;
      break;
    case 'I':
      [(MMFileBrowserController *)[self delegate] openSelectedFilesInCurrentWindowWithLayout:MMLayoutHorizontalSplit];
      event = nil;
      break;
    case 'S':
      [(MMFileBrowserController *)[self delegate] openSelectedFilesInCurrentWindowWithLayout:MMLayoutVerticalSplit];
      event = nil;
      break;
    default:
      event = nil;
      break;
    }
  }

  if (event != nil) {
    [super keyDown:event];
  }
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
  NSInteger row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
  if ([self numberOfSelectedRows] <= 1) {
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
  }
  return [(MMFileBrowserController *)[self delegate] menuForRow:row];
}

- (void)expandParentsOfItem:(id)item {
  NSArray *parents = [item parents];
  NSEnumerator *e = [parents reverseObjectEnumerator];

  // expand root node
  [self expandItem: nil];

  id parent;
  while((parent = [e nextObject])) {
    if(![self isExpandable:parent])
      break;
    if(![self isItemExpanded:parent])
      [self expandItem: parent];
  }
}

- (void)selectItem:(id)item {
  NSInteger itemIndex = [self rowForItem:item];
  if(itemIndex < 0) {
    [self expandParentsOfItem:item];
    itemIndex = [self rowForItem: item];
    if(itemIndex < 0)
      return;
  }
  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
  [self scrollRowToVisible:itemIndex];
}

@end

// ****************************************************************************
// Controller
// ****************************************************************************

@interface MMFileBrowserController (Private)
- (void)pwdChanged:(NSNotification *)notification;
- (void)changeWorkingDirectory:(NSString *)path;
- (NSArray *)selectedItems;
- (NSArray *)selectedItemPaths;
- (void)openSelectedFilesInCurrentWindowWithLayout:(int)layout;
- (NSArray *)appsAssociatedWithItem:(MMFileBrowserFSItem *)item;
- (MMFileBrowserFSItem *)itemAtRow:(NSInteger)row;
- (void)watchRoot;
- (void)unwatchRoot;
- (void)changeOccurredAtPath:(NSString *)path;
- (void)deleteBufferByPath:(NSString *)path;
- (void)deleteBufferByPath:(NSString *)path reopenPath:(NSString *)newPath;
- (void)selectInBrowserByExpandingItems:(BOOL)expand;
- (void)reloadOnlyDirectChildrenOfItem:(MMFileBrowserFSItem *)item;
@end


@implementation MMFileBrowserController

- (id)initWithWindowController:(MMWindowController *)controller {
  if ((self = [super initWithNibName:nil bundle:nil])) {
    windowController = controller;
    rootItem = nil;
    fsEventsStream = NULL;
    userHasChangedSelection = NO;
    viewLoaded = NO;
  }
  return self;
}

- (void)loadView {
  fileBrowser = [[MMFileBrowser alloc] initWithFrame:NSZeroRect];
  [fileBrowser setFocusRingType:NSFocusRingTypeNone];
  [fileBrowser setDelegate:self];
  [fileBrowser setDataSource:self];
  [fileBrowser setHeaderView:nil];
  [fileBrowser setAllowsMultipleSelection:YES];
  NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:nil] autorelease];
  ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
  [cell setEditable:YES];
  [column setDataCell:cell];
  [fileBrowser addTableColumn:column];
  [fileBrowser setOutlineTableColumn:column];

  [fileBrowser setTarget:self];
  [fileBrowser setDoubleAction:@selector(makeFirstResponder:)];

  [fileBrowser setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationLink forLocal:NO];
  [fileBrowser registerForDraggedTypes:[NSArray arrayWithObjects:DRAG_MOVE_FILES, NSFilenamesPboardType, nil]];

  pathControl = [[NSPathControl alloc] initWithFrame:NSMakeRect(0, 0, 0, 20)];
  [pathControl setRefusesFirstResponder:YES];
  [pathControl setAutoresizingMask:NSViewWidthSizable];
  [pathControl setBackgroundColor:[NSColor whiteColor]];
  [pathControl setPathStyle:NSPathStylePopUp];
  [pathControl setFont:[NSFont fontWithName:[[pathControl font] fontName] size:12]];
  [pathControl setTarget:self];
  [pathControl setAction:@selector(changeWorkingDirectoryFromPathControl:)];

  NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0, pathControl.frame.size.height, 0, 0)] autorelease];
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setAutohidesScrollers:YES];
  [scrollView setDocumentView:fileBrowser];

  [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable | NSViewMaxYMargin];

  MMFileBrowserContainerView *containerView = [[[MMFileBrowserContainerView alloc]
                                                initWithFrame:NSZeroRect] autorelease];
  [containerView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [containerView addSubview:scrollView];
  [containerView addSubview:pathControl];

  [self setView:containerView];
  viewLoaded = YES;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(pwdChanged:)
                                               name:@"MMPwdChanged"
                                             object:[windowController vimController]];

  [self setRoot:[[windowController vimController] objectForVimStateKey:@"pwd"]];
}

- (void)cleanup
{
  if (viewLoaded) {
    [fileBrowser setDelegate:nil];
    [fileBrowser setDataSource:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unwatchRoot];
  }
}

- (void)dealloc
{
  [pathControl release]; pathControl = nil;
  [fileBrowser release]; fileBrowser = nil;
  [rootItem release]; rootItem = nil;

  [super dealloc];
}

- (void)setRoot:(NSString *)root
{
  root = [(root ? root : @"~/") stringByStandardizingPath];

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

  rootItem = [[MMFileBrowserFSItem alloc] initWithPath:root
                                           parent:nil
                                              vim:[windowController vimController]];
  [fileBrowser reloadData];
  [fileBrowser expandItem:rootItem];
  [pathControl setURL:[NSURL fileURLWithPath:root]];

  [self watchRoot];
}

// Typing Tab (or Esc) in browser view sets keyboard focus to next view
- (void)setNextKeyView:(NSView *)nextKeyView {
  [fileBrowser setNextKeyView:nextKeyView];
}

- (void)makeFirstResponder:(id)sender {
  [fileBrowser makeFirstResponder];
  if ([fileBrowser numberOfSelectedRows] == 0) {
    [self selectInBrowser];
  }
}

- (void)selectInBrowser {
  [self selectInBrowserByExpandingItems:NO];
}

- (void)selectInBrowserByExpandingItems {
  [self selectInBrowserByExpandingItems:YES];
}

- (void)selectInBrowserByExpandingItems:(BOOL)expand {
  if ([windowController isSidebarCollapsed])
    return;
  NSString *fn = [[windowController vimController]
                                                  evaluateVimExpression:@"expand('%:p')"];
  if([fn length] > 0) {
    MMFileBrowserFSItem *item = [rootItem itemAtPath:fn];
    // always select file if `expand' is `YES', otherwise only if its parent is expanded
    if (expand || item.parent == rootItem || [fileBrowser isItemExpanded:item.parent]) {
      [fileBrowser selectItem:item];
    } else {
      [fileBrowser selectRowIndexes:nil byExtendingSelection:NO];
    }
  }
}

- (MMFileBrowserFSItem *)itemAtRow:(NSInteger)row {
  return [fileBrowser itemAtRow:row];
}

- (NSArray *)selectedItems {
  NSMutableArray *items = [NSMutableArray array];
  [[fileBrowser selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
    [items addObject:[fileBrowser itemAtRow:index]];
  }];
  return items;
}

- (NSArray *)selectedItemPaths {
  NSMutableArray *paths = [NSMutableArray array];
  NSArray *items = [self selectedItems];
  for (MMFileBrowserFSItem *item in items) {
    if ([item isLeaf]) {
      [paths addObject:[item fullPath]];
    }
  }
  return paths;
}

- (void)changeWorkingDirectory:(NSString *)path {
  BOOL isDir;
  if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
    if(!isDir) path = [path stringByDeletingLastPathComponent];
    // Tell Vim to change the pwd.  As a side effect this will cause a new root
    // to be set to the folder the user just double-clicked on.
    NSString *input = [NSString stringWithFormat:
                                   @"<C-\\><C-N>:exe \"cd \" . fnameescape(\"%@\")<CR>", path];
    [[windowController vimController] addVimInput:input];
  }
}

// Ignores the user's preference by always opening in the current window for the
// duration of the block. It restores, in addition, the layout preference.
//
// Any directory in `paths' is ignored.
- (void)openSelectedFilesInCurrentWindowWithLayout:(int)layout {
  NSArray *paths = [self selectedItemPaths];
  if ([paths count] > 0) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    BOOL openInCurrentWindow = [ud boolForKey:MMOpenInCurrentWindowKey];
    [ud setBool:YES forKey:MMOpenInCurrentWindowKey];
    int layoutBefore = [ud integerForKey:MMOpenLayoutKey];
    [ud setInteger:layout forKey:MMOpenLayoutKey];

    [(MMAppController *)[NSApp delegate] openFiles:paths withArguments:nil];

    [ud setBool:openInCurrentWindow forKey:MMOpenInCurrentWindowKey];
    [ud setInteger:layoutBefore forKey:MMOpenLayoutKey];

    [fileBrowser cancelOperation:self];
  }
}

// TODO move into MMFileBrowserFSItem
- (NSArray *)appsAssociatedWithItem:(MMFileBrowserFSItem *)item {
  NSString *uti = [[NSWorkspace sharedWorkspace] typeOfFile:[item fullPath] error:NULL];
  if (uti) {
    NSArray *identifiers = (NSArray *)LSCopyAllRoleHandlersForContentType((CFStringRef)uti, kLSRolesAll);
    NSMutableArray *paths = [NSMutableArray array];
    for (NSString *identifier in identifiers) {
      NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:identifier];
      if (appPath) {
        [paths addObject:appPath];
      }
    }
    [identifiers release];
    return [paths count] == 0 ? nil : paths;
  }
  return nil;
}

- (void)reloadOnlyDirectChildrenOfItem:(MMFileBrowserFSItem *)item {
  if ([item reloadRecursive:NO]) {
    if (item == rootItem) {
      [fileBrowser reloadData];
    } else {
      [fileBrowser reloadItem:item reloadChildren:YES];
    }
  }
}

// Vim related methods
// ===================

- (void)deleteBufferByPath:(NSString *)path reopenPath:(NSString *)newPath {
  NSString *input = [NSString stringWithFormat:@"<C-\\><C-N>:call MMDeleteBufferByPath('%@', '%@')<CR>", path, newPath];
  [[windowController vimController] addVimInput:input];
}

- (void)deleteBufferByPath:(NSString *)path {
  [self deleteBufferByPath:path reopenPath:@""];
}

// Data Source methods
// ===================

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (item == nil) {
    item = rootItem;
  }
  return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  if (item == nil) {
    item = rootItem;
  }
  return ([item numberOfChildren] != -1);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) {
    item = rootItem;
  }
  return [(MMFileBrowserFSItem *)item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  if (item == nil) {
    item = rootItem;
  }
  return [item relativePath];
}


// Delegate methods
// ================

- (NSMenu *)menuForRow:(NSInteger)row {
  NSMenu *menu = [[NSMenu new] autorelease];
  NSMenuItem *item;
  NSString *title;
  SEL action;
  MMFileBrowserFSItem *fsItem = [self itemAtRow:row];
  BOOL multipleSelection = [fileBrowser numberOfSelectedRows] > 1;

  // File operations
  [menu addItemWithTitle:@"New File" action:@selector(newFile:) keyEquivalent:@""];
  [menu addItemWithTitle:@"New Folder" action:@selector(newFolder:) keyEquivalent:@""];
  if (fsItem) {
    action = multipleSelection ? NULL : @selector(renameFile:);
    [menu addItemWithTitle:@"Rename…" action:action keyEquivalent:@""];
    title = multipleSelection ? @"Delete selected Files" : @"Delete selected File";
    [menu addItemWithTitle:title action:@selector(deleteSelectedFiles:) keyEquivalent:@""];

    // Vim open/cwd
    [menu addItem:[NSMenuItem separatorItem]];
    title = multipleSelection ? @"Open selected Files in Tabs" : @"Open selected File in Tab";
    [menu addItemWithTitle:title action:@selector(openFilesInTabs:) keyEquivalent:@""];
    title = multipleSelection ? @"Open selected Files in Horizontal Split Views" : @"Open selected File in Horizontal Split View";
    [menu addItemWithTitle:title action:@selector(openFilesInHorizontalSplitViews:) keyEquivalent:@""];
    title = multipleSelection ? @"Open selected Files in Vertical Split Views" : @"Open selected File in Vertical Split View";
    [menu addItemWithTitle:title action:@selector(openFilesInVerticalSplitViews:) keyEquivalent:@""];
    action = multipleSelection ? NULL : @selector(changeWorkingDirectoryToSelection:);
    title = [NSString stringWithFormat:@"Change working directory to “%@”", [[fsItem dirItem] relativePath]];
    [menu addItemWithTitle:title action:action keyEquivalent:@""];

    // Open elsewhere
    NSString *filename = [fsItem relativePath];
    [menu addItem:[NSMenuItem separatorItem]];
    action = multipleSelection ? NULL : @selector(revealInFinder:);
    title = [NSString stringWithFormat:@"Reveal “%@” in Finder", filename];
    [menu addItemWithTitle:title action:action keyEquivalent:@""];
    action = multipleSelection ? NULL : @selector(openWithFinder:);
    title = [NSString stringWithFormat:@"Open “%@” with Finder", filename];
    [menu addItemWithTitle:title action:action keyEquivalent:@""];
    // open with app submenu
    title = [NSString stringWithFormat:@"Open “%@” with…", filename];
    NSMenuItem *openWithFinderItem = [menu addItemWithTitle:title action:NULL keyEquivalent:@""];
    if (!multipleSelection) {
      NSArray *appPaths = [self appsAssociatedWithItem:fsItem];
      if (appPaths) {
        NSMenu *submenu = [[NSMenu new] autorelease];
        NSInteger i;
        for (i = 0; i < [appPaths count]; i++) {
          NSString *appPath = [appPaths objectAtIndex:i];
          NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:appPath];
          NSImage *appIcon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
          [appIcon setSize:NSMakeSize(16, 16)];
          item = [submenu addItemWithTitle:appName action:@selector(openFileWithApp:) keyEquivalent:@""];
          [item setTarget:self];
          [item setRepresentedObject:appPath];
          [item setImage:appIcon];
        }
        [openWithFinderItem setSubmenu:submenu];
      }
    }
  } else {
    fsItem = rootItem;
  }

  // Misc
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Reveal Current File in File Browser" action:@selector(selectInBrowserByExpandingItems) keyEquivalent:@""];
  item = [menu addItemWithTitle:@"Show hidden Files" action:@selector(toggleShowHiddenFiles:) keyEquivalent:@""];
  [item setState:rootItem.includesHiddenFiles ? NSOnState : NSOffState];

  for (item in [menu itemArray]) {
    [item setTarget:self];
    [item setRepresentedObject:fsItem];
  }
  return menu;
}

// TODO is this the proper way to differentiate between selection changes because the user selected a file
// and a programmatic selection change?
- (void)outlineViewSelectionIsChanging:(NSNotification *)aNotification {
  userHasChangedSelection = YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  MMFileBrowser *outlineView = fileBrowser;
  if (userHasChangedSelection && [outlineView numberOfSelectedRows] == 1) {
    MMFileBrowserFSItem *item = [self itemAtRow:[outlineView selectedRow]];
    if ([item isLeaf]) {
      NSEvent *event = [NSApp currentEvent];
      int layout = [[NSUserDefaults standardUserDefaults] integerForKey:MMOpenLayoutKey];
      if ([event modifierFlags] & NSAlternateKeyMask) {
        if (layout == MMLayoutTabs) {
          // The user normally creates a new tab when opening a file,
          // so open this file in the current one
          layout = MMLayoutArglist;
        } else {
          // The user normally opens a file in the current tab,
          // so open this file in a new one
          layout = MMLayoutTabs;
        }
      }
      [self openSelectedFilesInCurrentWindowWithLayout:layout];
    } else {
      if ([outlineView isItemExpanded:item]) {
        [outlineView collapseItem:item];
      } else {
        [outlineView expandItem:item];
      }
    }
  }
  userHasChangedSelection = NO;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  [(ImageAndTextCell *)cell setImage:[item icon]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
        shouldEditTableColumn:(NSTableColumn *)tableColumn
                         item:(id)item
{
  return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView
     setObjectValue:(NSString *)name
     forTableColumn:(NSTableColumn *)tableColumn
             byItem:(MMFileBrowserFSItem *)item
{
  // save these here, cause by moving the file and reloading the view 'item' will be released
  BOOL isLeaf = [item isLeaf];
  NSString *fullPath = [item fullPath];

  MMFileBrowserFSItem *dirItem = item.parent;
  NSString *newPath = [[dirItem fullPath] stringByAppendingPathComponent:name];
  NSError *error = nil;
  dirItem.ignoreNextReload = YES;
  BOOL moved = [[NSFileManager defaultManager] moveItemAtPath:fullPath
                                                       toPath:newPath
                                                        error:&error];
  if (moved) {
    [self reloadOnlyDirectChildrenOfItem:dirItem];
    // Select the renamed item
    NSInteger row = [fileBrowser rowForItem:[dirItem itemWithName:name]];
    NSIndexSet *index = [NSIndexSet indexSetWithIndex:row];
    [fileBrowser selectRowIndexes:index byExtendingSelection:NO];
    if (isLeaf) {
      newPath = [newPath stringByEscapingSpecialFilenameCharacters];
      [self deleteBufferByPath:fullPath reopenPath:newPath];
    }
    else {
      // TODO: should reopen all open buffers with files inside of this directory
    }
  } else {
    dirItem.ignoreNextReload = NO;
    NSLog(@"[!] Unable to rename `%@' to `%@'. Error: %@", [item fullPath], newPath, [error localizedDescription]);
  }
}

// Initiate the drag operation
- (BOOL)outlineView:(NSOutlineView *)outlineView
         writeItems:(NSArray *)items
       toPasteboard:(NSPasteboard *)pasteboard
{
  dragItems = items;
  [pasteboard declareTypes:[NSArray arrayWithObjects:DRAG_MOVE_FILES, NSFilenamesPboardType, nil] owner:self];
  [pasteboard setData:[NSData data] forType:DRAG_MOVE_FILES];
  [pasteboard setPropertyList:[items valueForKey:@"fullPath"] forType:NSFilenamesPboardType];
  return YES;
}

// Always display the drop insertion marker underneath the folder that the files
// would be dropped on if the mouse button were to be released right now.
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView
                  validateDrop:(id <NSDraggingInfo>)info
                  proposedItem:(MMFileBrowserFSItem *)item
            proposedChildIndex:(NSInteger)index
{
  if (dragItems == nil) {
    return NSDragOperationNone;
  } else {
    if ([item isLeaf]) {
      MMFileBrowserFSItem *dirItem = [item dirItem];
      [outlineView setDropItem:dirItem == rootItem ? nil : dirItem
                dropChildIndex:[[dirItem children] indexOfObject:item]];
    }
    return NSDragOperationEvery;
  }
}

// Handle drop
- (BOOL)outlineView:(NSOutlineView *)outlineView
         acceptDrop:(id < NSDraggingInfo >)info
               item:(MMFileBrowserFSItem *)toItem
         childIndex:(NSInteger)index
{
  if (dragItems == nil) {
    return NO;
  } else {
    if (toItem == nil) toItem = rootItem;

    MMFileBrowserFSItem *fromItem = [(MMFileBrowserFSItem *)[dragItems objectAtIndex:0] dirItem];
    fromItem.ignoreNextReload = YES;
    toItem.ignoreNextReload = YES;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (MMFileBrowserFSItem *dragItem in dragItems) {
      NSString *to = [[toItem fullPath] stringByAppendingPathComponent:[dragItem relativePath]];
      [fileManager moveItemAtPath:[dragItem fullPath] toPath:to error:NULL];
      [self deleteBufferByPath:[dragItem fullPath] reopenPath:to];
    }

    [self reloadOnlyDirectChildrenOfItem:fromItem];
    [self reloadOnlyDirectChildrenOfItem:toItem];

    dragItems = nil;
    return YES;
  }
}


// Actions
// =======

- (void)renameFile:(NSMenuItem *)sender {
  NSInteger row = [fileBrowser rowForItem:[sender representedObject]];
  [fileBrowser editColumn:0 row:row withEvent:nil select:YES];
}

- (void)newFile:(NSMenuItem *)sender {
  MMFileBrowserFSItem *item = [sender representedObject];
  if([item isLeaf]) item = [item parent];
  NSString *path = [[item fullPath] stringByAppendingPathComponent:@"untitled file"];

  int i = 2;
  NSString *result = path;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  while ([fileManager fileExistsAtPath:result]) {
   result = [NSString stringWithFormat:@"%@ %d", path, i];
   i++;
  }

  item.ignoreNextReload = YES;
  if ([fileManager createFileAtPath:result contents:[NSData data] attributes:nil]) {
    [self reloadOnlyDirectChildrenOfItem:item];
    if(item != rootItem) [fileBrowser expandItem:item];
    MMFileBrowserFSItem *newItem = [item itemWithName:[result lastPathComponent]];
    NSInteger row = [fileBrowser rowForItem:newItem];
    NSIndexSet *index = [NSIndexSet indexSetWithIndex:row];
    [fileBrowser selectRowIndexes:index byExtendingSelection:NO];
    [fileBrowser editColumn:0 row:row withEvent:nil select:YES];
  }
  else {
    NSLog(@"Failed to create file %@", path);
  }
}

- (void)newFolder:(NSMenuItem *)sender {
  MMFileBrowserFSItem *selItem = [sender representedObject];
  MMFileBrowserFSItem *dirItem = selItem ? [selItem dirItem] : rootItem;
  NSString *path = [[dirItem fullPath] stringByAppendingPathComponent:@"untitled folder"];

  int i = 2;
  NSString *result = path;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  while ([fileManager fileExistsAtPath:result]) {
    result = [NSString stringWithFormat:@"%@ %d", path, i];
    i++;
  }

  // Make sure that the next FSEvent for this item doesn't cause the view to stop editing
  dirItem.ignoreNextReload = YES;

  [fileManager createDirectoryAtPath:result
         withIntermediateDirectories:NO
                          attributes:nil
                               error:NULL];

  [self reloadOnlyDirectChildrenOfItem:dirItem];

  // Show, select and edit the new folder
  if(selItem) [fileBrowser expandItem:dirItem];
  MMFileBrowserFSItem *newItem = [dirItem itemWithName:[result lastPathComponent]];
  NSInteger row = [fileBrowser rowForItem:newItem];
  NSIndexSet *index = [NSIndexSet indexSetWithIndex:row];
  [fileBrowser selectRowIndexes:index byExtendingSelection:NO];
  [fileBrowser editColumn:0 row:row withEvent:nil select:YES];
}

// Vim open/cwd

- (void)openFilesInTabs:(NSMenuItem *)sender {
  [self openSelectedFilesInCurrentWindowWithLayout:MMLayoutTabs];
}

- (void)openFilesInHorizontalSplitViews:(NSMenuItem *)sender {
  [self openSelectedFilesInCurrentWindowWithLayout:MMLayoutHorizontalSplit];
}

- (void)openFilesInVerticalSplitViews:(NSMenuItem *)sender {
  [self openSelectedFilesInCurrentWindowWithLayout:MMLayoutVerticalSplit];
}

- (void)changeWorkingDirectoryToSelection:(NSMenuItem *)sender {
  [self changeWorkingDirectory:[[[sender representedObject] dirItem] fullPath]];
}

- (void)changeWorkingDirectoryFromPathControl:(NSPathControl *)sender {
  NSPathComponentCell *clickedCell = [sender clickedPathComponentCell];
  [self changeWorkingDirectory:[[clickedCell URL] path]];
}

- (void)deleteSelectedFiles:(NSMenuItem *)sender {
  NSArray *items = [self selectedItems];
  for (MMFileBrowserFSItem *item in items) {
    NSString *fullPath = [item fullPath];
    BOOL isLeaf = [item isLeaf];
    MMFileBrowserFSItem *dirItem = item.parent;

    dirItem.ignoreNextReload = YES;
    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
    [self reloadOnlyDirectChildrenOfItem:dirItem];

    if (isLeaf) {
      [self deleteBufferByPath:fullPath];
    }
  }
}

- (void)toggleShowHiddenFiles:(NSMenuItem *)sender {
  rootItem.includesHiddenFiles = !rootItem.includesHiddenFiles;
  [rootItem reloadRecursive:YES];
  [fileBrowser reloadData];
}

// Open elsewhere

- (void)revealInFinder:(NSMenuItem *)sender {
  NSString *path = [[sender representedObject] fullPath];
  NSArray *urls = [NSArray arrayWithObject:[NSURL fileURLWithPath:path]];
  [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
}

- (void)openWithFinder:(NSMenuItem *)sender {
  [[NSWorkspace sharedWorkspace] openFile:[[sender representedObject] fullPath]];
}

- (void)openFileWithApp:(NSMenuItem *)sender {
  NSMenu *menu = [sender menu];
  NSInteger index = [[menu supermenu] indexOfItemWithSubmenu:menu];
  NSMenuItem *parentMenuItem = [[menu supermenu] itemAtIndex:index];
  MMFileBrowserFSItem *item = [parentMenuItem representedObject];
  NSString *selectedApp = [sender representedObject];
  [[NSWorkspace sharedWorkspace] openFile:[item fullPath] withApplication:selectedApp];
}


// FSEvents
// ========

static void change_occured(ConstFSEventStreamRef stream,
                           void *watcher,
                           size_t eventCount,
                           void *paths,
                           const FSEventStreamEventFlags flags[],
                           const FSEventStreamEventId ids[]) {
  MMFileBrowserController *self = (MMFileBrowserController *)watcher;
  for (NSString *path in (NSArray *)paths) {
    [self changeOccurredAtPath:path];
  }
}

- (void)changeOccurredAtPath:(NSString *)path {
  MMFileBrowserFSItem *item = [rootItem itemAtPath:path];
  if (item) {
    if (item.ignoreNextReload) {
      item.ignoreNextReload = NO;
      return;
    }
    // NSLog(@"Change at: %@", [item fullPath]);
    [self reloadOnlyDirectChildrenOfItem:item];
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

- (void)pwdChanged:(NSNotification *)notification
{
  NSString *pwd = [[notification userInfo] objectForKey:@"pwd"];
  if (pwd) {
    [self setRoot:pwd];
    [fileBrowser reloadData];
    [fileBrowser expandItem:rootItem];
  }
}

@end
