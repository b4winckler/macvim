#import "MMFileBrowserFSItem.h"
#import "MMVimController.h"
#include <fts.h>

@interface MMFileBrowserFSItem ()
- (id)initWithPath:(char *)thePath
            parent:(MMFileBrowserFSItem *)parentItem
             isDir:(BOOL)dir
               vim:(MMVimController *)vimInstance;
- (MMFileBrowserFSItem *)_itemAtPath:(NSArray *)components;
@end


@implementation MMFileBrowserFSItem

// TODO remove this from the global namespace, have one instance shared by all fs items for one file browser instance
static NSMutableDictionary *iconCache = nil;
+ (void)initialize {
  if (self == [MMFileBrowserFSItem class]) {
    iconCache = [NSMutableDictionary new];
  }
}

@synthesize parent, includesHiddenFiles, ignoreNextReload, children;

- (void)dealloc {
  [children release];
  free(cpath);
  [icon release];
  vim = nil;
  [super dealloc];
}

- (id)initWithPath:(NSString *)thePath vim:(MMVimController *)vimInstance;
{
  return [self initWithPath:(char *)[thePath UTF8String] parent:nil isDir:YES vim:vimInstance];
}

- (id)initWithPath:(char *)thePath
            parent:(MMFileBrowserFSItem *)parentItem
             isDir:(BOOL)dir
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
    } else {
      includesHiddenFiles = NO;
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

static void
MMFileBrowserFSItemStackIncrease(NSMutableArray *stack,
                                 MMFileBrowserFSItem *newItem,
                                 NSMutableArray **newChildren,
                                 BOOL *checkChildrenForExistingItem)
{
  BOOL check = NO;
  // Use an existing children list if this dir has been loaded before.
  if (newItem.children) {
    check = YES;
    *newChildren = newItem.children;
  } else {
    *newChildren = [NSMutableArray new];
    newItem.children = *newChildren;
    [*newChildren release];
  }
  *checkChildrenForExistingItem = check;
  NSArray *stackEntry = [[NSArray alloc] initWithObjects:newItem,
                                                         *newChildren,
                                                         [NSNumber numberWithBool:check],
                                                         nil];
  [stack addObject:stackEntry];
  [stackEntry release];
}

- (BOOL)loadChildrenRecursive:(BOOL)recursive expandedChildrenOnly:(BOOL)expandedChildrenOnly;
{
  // Only reload items that have been loaded before
  // NSLog(@"Reload: %@", path);
  if (parent) {
    includesHiddenFiles = parent.includesHiddenFiles;
  }

  BOOL newItemsCreated = NO;

  char *path = (char *)[[self fullPath] UTF8String];
  NSLog(@"Open dir: %s, recursive: %s", path, (recursive ? "YES" : "NO"));
  char *paths[2] = { path, NULL };
  // TODO we can sort with the third arg
  FTS *root = fts_open(paths, FTS_LOGICAL | FTS_COMFOLLOW | FTS_NOCHDIR, NULL);
  assert(root != NULL && @"Failed to open dir.");

  // Setup the stack for recursive search
  MMFileBrowserFSItem *currentItem = self;
  NSMutableArray *currentChildren;
  BOOL checkChildrenForExistingItem;
  NSMutableArray *stack = [NSMutableArray new];
  MMFileBrowserFSItemStackIncrease(stack, currentItem, &currentChildren, &checkChildrenForExistingItem);
  short childrenStackLevel = FTS_ROOTLEVEL;

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
        if (node->fts_level < childrenStackLevel) {
          // Keep the current level on the stack!
          for (short i = childrenStackLevel; i > node->fts_level; i--) {
            [stack removeObjectAtIndex:i-1];
          }
          childrenStackLevel = node->fts_level;
          NSArray *stackEntry = [stack objectAtIndex:childrenStackLevel-1];
          currentItem = [stackEntry objectAtIndex:0];
          currentChildren = [stackEntry objectAtIndex:1];
          checkChildrenForExistingItem = [[stackEntry objectAtIndex:2] boolValue];
        }

        if (MMFileBrowserFSItemIgnoreFile(node->fts_name, includesHiddenFiles)) {
          if (dir) fts_set(root, node, FTS_SKIP);
          continue;
        }

        // TODO remove deleted files

        MMFileBrowserFSItem *child = nil;
        // First check if the item already exists.
        if (checkChildrenForExistingItem) {
          for (MMFileBrowserFSItem *c in currentChildren) {
            if (strcmp(c->cpath, node->fts_name) == 0) {
              child = c;
              break;
            }
          }
        }
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
                                                     parent:currentItem
                                                      isDir:dir
                                                        vim:vim];
          [currentChildren addObject:child];
          [child release];
        }

        // Set the new child as the current item and the current children.
        if (dir && recursive) {
          currentItem = child;
          MMFileBrowserFSItemStackIncrease(stack,
                                           currentItem,
                                           &currentChildren,
                                           &checkChildrenForExistingItem);
          childrenStackLevel++;
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
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSString *type;
    NSString *path = nil;
    if (isDir) {
      type = [[self relativePath] pathExtension];
      if (type.length > 0) {
        // This is possibly a 'bundle' dir (e.g. Foo.xcodeproj).
        path = [self fullPath];
      } else {
        // It's not a 'bundle' dir, so use a normal folder icon.
        type = @"MMFileBrowserFolder";
        path = @"/var"; // Just pick a dir that's guaranteed to have a normal folder icon.
      }
    } else {
      if (![ws getInfoForFile:[self fullPath] application:NULL type:&type]) {
        NSLog(@"FAILED TO FIND INFO FOR %@", [self fullPath]);
        type = @"";
      }
    }
    icon = [iconCache valueForKey:type];
    if (icon == nil) {
      if (isDir) {
        icon = [ws iconForFile:path];
      } else {
        icon = [ws iconForFileType:type];
      }
      [icon setSize:NSMakeSize(16, 16)];
      [iconCache setValue:icon forKey:type];
    }
    [icon retain];
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

