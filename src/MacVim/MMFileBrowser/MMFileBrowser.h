#import <Cocoa/Cocoa.h>

@class MMFileBrowserFSItem;

@interface MMFileBrowser : NSOutlineView
- (void)makeFirstResponder;
- (NSMenu *)menuForEvent:(NSEvent *)event;
- (void)cancelOperation:(id)sender;
- (void)expandParentsOfItem:(id)item;
- (void)selectItem:(id)item;
- (NSEvent *)keyEventWithEvent:(NSEvent *)event character:(NSString *)character code:(unsigned short)code;
- (void)sendSelectionChangedNotification;
@end

@protocol MMFileBrowserDelegate <NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate>
- (void)outlineViewSelectionIsChanging:(NSNotification *)notification;
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
- (NSMenu *)menuForRow:(NSInteger)row;
- (void)openSelectedFilesInCurrentWindowWithLayout:(int)layout;
- (void)fileBrowserWillExpand:(MMFileBrowser *)fileBrowser
                         item:(MMFileBrowserFSItem *)item
                    recursive:(BOOL)recursive;
@end

