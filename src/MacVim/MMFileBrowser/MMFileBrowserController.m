#import "MMFileBrowserController.h"
#import "MMWindowController.h"
#import "MMAppController.h"
#import "Miscellaneous.h"
#import "MMVimController.h"

#import "MMFileBrowser.h"
#import "MMFileBrowserFSItem.h"
#import "MMFileBrowserCell.h"

#import <CoreServices/CoreServices.h>

#define DRAG_MOVE_FILES @"MoveFiles"

@interface MMFileBrowserContainerView : NSView
@end

@implementation MMFileBrowserContainerView

- (BOOL) isFlipped {
  return YES;
}

@end


@interface MMFileBrowserController ()
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
  MMFileBrowserCell *cell = [[[MMFileBrowserCell alloc] init] autorelease];
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
                                                   vim:[windowController vimController]];
  [rootItem loadChildrenRecursive:NO expandedChildrenOnly:YES];
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
  if ([item loadChildrenRecursive:NO expandedChildrenOnly:YES]) {
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
- (void)outlineViewSelectionIsChanging:(NSNotification *)notification {
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

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(MMFileBrowserCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  cell.image = [item icon];
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

- (void)fileBrowserWillExpand:(MMFileBrowser *)fileBrowser
                         item:(MMFileBrowserFSItem *)item
                    recursive:(BOOL)recursive;
{
  if (recursive) {
    // Recursive to any depth.
    [item loadChildrenRecursive:YES expandedChildrenOnly:NO];
  } else {
    // Only needed if the item has not been loaded before.
    if (item.children == nil) {
      [item loadChildrenRecursive:NO expandedChildrenOnly:YES];
    }
  }
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification;
{
  MMFileBrowserFSItem *item = [notification.userInfo objectForKey:@"NSObject"];
  // Free memory
  item.children = nil;
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
  // Only reload dirs that are shown
  [rootItem loadChildrenRecursive:YES expandedChildrenOnly:YES];
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
