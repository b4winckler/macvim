#import <Cocoa/Cocoa.h>

@class MMVimController;

@interface MMFileBrowserFSItem : NSObject {
  char *cpath;
  BOOL isDir;
  MMFileBrowserFSItem *parent;
  MMVimController *vim;
  BOOL includesHiddenFiles;
  BOOL ignoreNextReload;
  NSImage *icon;
}

@property (nonatomic, assign) BOOL includesHiddenFiles, ignoreNextReload;
@property (readonly) MMFileBrowserFSItem *parent;
@property (nonatomic, retain) NSMutableArray *children;

- (id)initWithPath:(NSString *)thePath vim:(MMVimController *)vimInstance;
- (NSInteger)numberOfChildren; // Returns -1 for leaf nodes
- (MMFileBrowserFSItem *)childAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSString *)fullPath;
- (NSString *)relativePath;
- (BOOL)isLeaf;
- (BOOL)loadChildrenRecursive:(BOOL)recursive expandedChildrenOnly:(BOOL)expandedChildrenOnly;
- (MMFileBrowserFSItem *)itemAtPath:(NSString *)itemPath;
- (MMFileBrowserFSItem *)itemWithName:(NSString *)name;
- (NSArray *)parents;
- (MMFileBrowserFSItem *)dirItem;

@end


