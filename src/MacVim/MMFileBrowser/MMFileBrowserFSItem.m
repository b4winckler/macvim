#import "MMFileBrowserFSItem.h"
#import "MMVimController.h"
#include <fts.h>

@class MMFileBrowserFSItemIconCache;

@interface MMFileBrowserFSItem () {
  char *cpath;
  MMFileBrowserFSItem *parent;
  MMVimController *vim;
  BOOL includesHiddenFiles;
  BOOL ignoreNextReload;
  NSImage *icon;
  MMFileBrowserFSItemIconCache *iconCache;
}

@property (readonly) const char *cpath;

- (id)initWithPath:(char *)thePath
            parent:(MMFileBrowserFSItem *)parentItem
             isDir:(BOOL)dir
         iconCache:(MMFileBrowserFSItemIconCache *)theIconCache
               vim:(MMVimController *)vimInstance;
- (MMFileBrowserFSItem *)_itemAtPath:(NSArray *)components;

@end



@interface MMFileBrowserFSItemStack : NSObject

@property (readonly) NSMutableArray *stack;
@property (readonly) short level;
@property (readonly) BOOL checkChildrenForExistingItem;
@property (readonly) MMFileBrowserFSItem *currentItem;
@property (readonly) NSMutableArray *currentChildren;
@property (readonly) NSMutableArray *removeFromCurrentChildren;

- (void)push:(MMFileBrowserFSItem *)item;
- (void)popTo:(short)toLevel;

@end

@implementation MMFileBrowserFSItemStack

@synthesize stack, level, checkChildrenForExistingItem;
@synthesize currentItem, currentChildren, removeFromCurrentChildren;

- (void)dealloc;
{
  [stack release];
  [super dealloc];
}

- (id)init;
{
  if ((self = [super init])) {
    stack = [NSMutableArray new];
    level = FTS_ROOTLEVEL;
    checkChildrenForExistingItem = NO;
    currentItem = nil;
    currentChildren = nil;
    removeFromCurrentChildren = nil;
  }
  return self;
}

- (void)push:(MMFileBrowserFSItem *)item;
{
  currentItem = item;
  // Use an existing children list if this dir has been loaded before.
  if (currentItem.children) {
    checkChildrenForExistingItem = YES;
    currentChildren = currentItem.children;
    removeFromCurrentChildren = [currentChildren mutableCopy];
  } else {
    currentChildren = [NSMutableArray new];
    currentItem.children = currentChildren;
    [currentChildren release];
    removeFromCurrentChildren = nil;
  }
  NSNumber *check = [NSNumber numberWithBool:checkChildrenForExistingItem];
  NSArray *stackEntry = [[NSArray alloc] initWithObjects:currentItem,
                                                         currentChildren,
                                                         check,
                                                         removeFromCurrentChildren,
                                                         nil];
  [stack addObject:stackEntry];
  [stackEntry release];
  level++;
}

// Ensure all items that need to be removed are removed.
- (void)flush;
{
  [self popTo:FTS_ROOTLEVEL];
}

- (void)popTo:(short)toLevel;
{
  NSArray *stackEntry;
  // Keep the current level on the stack!
  for (short i = level; i > toLevel; i--) {
    stackEntry = [stack lastObject];
    if ([stackEntry count] > 3) {
      NSMutableArray *children = [stackEntry objectAtIndex:1];
      NSArray *remove = [stackEntry objectAtIndex:3];
      for (MMFileBrowserFSItem *item in remove) {
        // NSLog(@"REMOVE: %@", item);
        [children removeObject:item];
      }
    }
    [stack removeLastObject];
  }
  level = toLevel;
  stackEntry = [stack lastObject];
  currentItem = [stackEntry objectAtIndex:0];
  currentChildren = [stackEntry objectAtIndex:1];
  if ([stackEntry count] > 3) {
    removeFromCurrentChildren = [stackEntry objectAtIndex:3];
  } else {
    removeFromCurrentChildren = nil;
  }
  checkChildrenForExistingItem = [[stackEntry objectAtIndex:2] boolValue];
}

// Also marks the child as not needing removal.
- (MMFileBrowserFSItem *)existingChild:(const char *)filename;
{
  if (checkChildrenForExistingItem) {
    for (MMFileBrowserFSItem *c in currentChildren) {
      if (strcmp(c.cpath, filename) == 0) {
        if (removeFromCurrentChildren) [removeFromCurrentChildren removeObject:c];
        return c;
      }
    }
  }
  return nil;
}

@end


@interface MMFileBrowserFSItemIconCache : NSObject {
  NSMutableDictionary *cache;
}
@end

@implementation MMFileBrowserFSItemIconCache

- (void)dealloc;
{
  [cache release];
  [super dealloc];
}

- (id)init;
{
  if ((self = [super init])) {
    cache = [NSMutableDictionary new];
  }
  return self;
}

- (NSImage *)iconForItem:(MMFileBrowserFSItem *)item;
{
  NSString *type = nil;
  NSString *path = nil;
  if (item.isDir) {
    type = [[item relativePath] pathExtension];
    if (type.length > 0) {
      // This is possibly a 'bundle' dir (e.g. Foo.xcodeproj).
      path = [item fullPath];
    } else {
      // It's not a 'bundle' dir, so use a normal folder icon.
      type = @"MMFileBrowserFolder";
      path = @"/var"; // Just pick a dir that's guaranteed to have a normal folder icon.
    }
  } else {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    if (![ws getInfoForFile:[item fullPath] application:NULL type:&type]) {
      NSLog(@"FAILED TO FIND INFO FOR %@", [item fullPath]);
      type = @"";
    }
  }
  return [self iconForFileType:type isDir:item.isDir path:path];
}

- (NSImage *)iconForFileType:(NSString *)type isDir:(BOOL)isDir path:(NSString *)path;
{
  NSImage *icon = [cache valueForKey:type];
  if (icon == nil) {
    if (isDir) {
      icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    } else {
      icon = [[NSWorkspace sharedWorkspace] iconForFileType:type];
    }
    [icon setSize:NSMakeSize(16, 16)];
    [cache setValue:icon forKey:type];
  }
  return icon;
}

@end



@implementation MMFileBrowserFSItem

@synthesize parent, isDir, cpath, includesHiddenFiles, ignoreNextReload, children;

- (void)dealloc {
  [children release];
  free(cpath);
  if (!parent) {
    [iconCache release];
  }
  vim = nil;
  [super dealloc];
}

- (id)initWithPath:(NSString *)thePath vim:(MMVimController *)vimInstance;
{
  return [self initWithPath:(char *)[thePath UTF8String]
                     parent:nil
                      isDir:YES
                  iconCache:nil
                        vim:vimInstance];
}

- (id)initWithPath:(char *)thePath
            parent:(MMFileBrowserFSItem *)parentItem
             isDir:(BOOL)dir
         iconCache:(MMFileBrowserFSItemIconCache *)theIconCache
               vim:(MMVimController *)vimInstance;
{
  if ((self = [super init])) {
    icon = nil;
    parent = parentItem;
    vim = vimInstance;
    isDir = dir;

    cpath = strdup(thePath);

    if (parent) {
      includesHiddenFiles = parent.includesHiddenFiles;
      iconCache = theIconCache;
    } else {
      includesHiddenFiles = NO;
      iconCache = [MMFileBrowserFSItemIconCache new];
    }
    ignoreNextReload = NO;
  }
  return self;
}

- (NSString *)description;
{
  return [NSString stringWithFormat:@"<MMFileBrowserFSItem type:%s path:%s>", (isDir ? "dir " : "file"), cpath];
}

static BOOL
MMFileBrowserFSItemIgnoreFile(const char *filename, BOOL includesHiddenFiles)
{
  BOOL isHiddenFile = filename[0] == '.';
  if (isHiddenFile && !includesHiddenFiles) {
    // It's a hidden file which are currently not visible.
    return YES;
  } else {
    size_t len = strlen(filename);
    if (isHiddenFile && len >= 4) {
      // Does include hidden files, but never add Vim swap files to browser.
      //
      // Vim swap files have names of type
      //   .original-file-name.sXY
      // where XY can be anything from "aa" to "wp".
      const char *last4 = &filename[len-4];
      // if ([last4 compare:@".saa"] >= 0 && [last4 compare:@".swp"] <= 0) {
      if (strcmp(last4, ".saa") >= 0 && strcmp(last4, ".swp") <= 0) {
        // It's a swap file, ignore it.
        return YES;
      }
    // TODO THIS IS SLOW!
    //} else if (!includesHiddenFiles) {
      //NSString *eval = [NSString stringWithFormat:@"empty(expand(fnameescape('%@')))", filename];
      //NSString *result = [vim evaluateVimExpression:eval];
      //return [result isEqualToString:@"1"];
    }
  }
  return NO;
}

//static void
//printItems(MMFileBrowserFSItem *item, int indent)
//{
  //for (int i = 0; i < indent; i++) {
    //printf("  ");
  //}
  //printf("%s\n", [[item description] UTF8String]);
  //if (item->children != nil) {
    //for (MMFileBrowserFSItem *i in item.children) {
      //printItems(i, indent+1);
    //}
  //}
//}

- (BOOL)loadChildrenRecursive:(BOOL)recursive expandedChildrenOnly:(BOOL)expandedChildrenOnly;
{
  BOOL newItemsCreated = NO;

  // Only reload items that have been loaded before
  // NSLog(@"Reload: %@", path);
  if (parent) {
    includesHiddenFiles = parent.includesHiddenFiles;
  }

  char *path = (char *)[[self fullPath] UTF8String];
  char *paths[2] = { path, NULL };

  // NSLog(@"Open dir: %s, recursive: %s", path, (recursive ? "YES" : "NO"));
  // TODO we can sort with the third arg
  FTS *root = fts_open(paths, FTS_LOGICAL | FTS_COMFOLLOW | FTS_NOCHDIR, NULL);
  assert(root != NULL && @"Failed to open dir.");

  // Setup the stack for recursive search
  MMFileBrowserFSItemStack *stack = [MMFileBrowserFSItemStack new];
  [stack push:self];

  FTSENT *node;
  while ((node = fts_read(root)) != NULL) {
    if (node->fts_info == FTS_D || node->fts_info == FTS_F) {
      // Skip the root node, which is the path represented by the root item.
      if (node->fts_level != FTS_ROOTLEVEL) {
        BOOL dir = node->fts_info == FTS_D;
        if (dir && !recursive) {
          fts_set(root, node, FTS_SKIP);
        }

        // Gone back to lower level, restore state
        if (node->fts_level < stack.level) {
          [stack popTo:node->fts_level];
        }

        if (MMFileBrowserFSItemIgnoreFile(node->fts_name, includesHiddenFiles)) {
          if (dir) fts_set(root, node, FTS_SKIP);
          continue;
        }

        // TODO remove deleted files

        // First check if the item already exists.
        MMFileBrowserFSItem *child = [stack existingChild:node->fts_name];
        if (child) {
          // If this is *not* a previously loaded dir and expandedChildrenOnly
          // is `YES` then skip it.
          if (dir && expandedChildrenOnly && child.children == nil) {
            fts_set(root, node, FTS_SKIP);
            continue;
          }
        } else {
          // No item exists yet.
          newItemsCreated = YES;
          child = [[MMFileBrowserFSItem alloc] initWithPath:node->fts_name
                                                     parent:stack.currentItem
                                                      isDir:dir
                                                  iconCache:iconCache
                                                        vim:vim];
          [stack.currentChildren addObject:child];
          [child release];
        }

        // Set the new child as the current item and the current children.
        if (dir && recursive) {
          [stack push:child];
        }
      }
    } else if (node->fts_info == FTS_DNR || node->fts_info == FTS_ERR) {
      NSLog(@"%s: %s", node->fts_name, strerror(node->fts_errno));
    } else {
      // TODO so what is it??
      // NSLog(@"SOMETHING ELSE!");
    }
  }
  fts_close(root);

  [stack flush];
  [stack release];
  //printItems(item, 0);

  return newItemsCreated;
}

- (BOOL)isLeaf {
  return !isDir;
}

// Returns `self' if it's a directory item, otherwise it returns the parent item.
- (MMFileBrowserFSItem *)dirItem {
  return isDir ? self : parent;
}

- (NSString *)relativePath {
  return [NSString stringWithUTF8String:cpath];
}

- (NSString *)fullPath {
  return parent ? [[parent fullPath] stringByAppendingPathComponent:[self relativePath]] : [self relativePath];
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
    icon = [iconCache iconForItem:self];
  }
  return icon;
}

- (MMFileBrowserFSItem *)itemAtPath:(NSString *)itemPath {
  if ([itemPath hasSuffix:@"/"])
    itemPath = [itemPath stringByStandardizingPath];
  NSArray *components = [itemPath pathComponents];
  NSArray *root = [[self fullPath] pathComponents];

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

// Return nil if the children have not been loaded yet, which means that no
// item for the path can be shown yet.
- (MMFileBrowserFSItem *)itemWithName:(NSString *)name {
  if (children != nil) {
    for (MMFileBrowserFSItem *child in [self children]) {
      if ([[child relativePath] isEqualToString:name]) {
        return child;
      }
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

@end

