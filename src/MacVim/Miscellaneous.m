/* vi:set ts=8 sts=4 sw=4 ft=objc:
 *
 * VIM - Vi IMproved		by Bram Moolenaar
 *				MacVim GUI port by Bjorn Winckler
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 */

#import "MacVim.h"
#import "Miscellaneous.h"



// NSUserDefaults keys
NSString *MMTabMinWidthKey              = @"MMTabMinWidth";
NSString *MMTabMaxWidthKey              = @"MMTabMaxWidth";
NSString *MMTabOptimumWidthKey          = @"MMTabOptimumWidth";
NSString *MMShowAddTabButtonKey         = @"MMShowAddTabButton";
NSString *MMTextInsetLeftKey            = @"MMTextInsetLeft";
NSString *MMTextInsetRightKey           = @"MMTextInsetRight";
NSString *MMTextInsetTopKey             = @"MMTextInsetTop";
NSString *MMTextInsetBottomKey          = @"MMTextInsetBottom";
NSString *MMTypesetterKey               = @"MMTypesetter";
NSString *MMCellWidthMultiplierKey      = @"MMCellWidthMultiplier";
NSString *MMBaselineOffsetKey           = @"MMBaselineOffset";
NSString *MMTranslateCtrlClickKey       = @"MMTranslateCtrlClick";
NSString *MMTopLeftPointKey             = @"MMTopLeftPoint";
NSString *MMOpenInCurrentWindowKey      = @"MMOpenInCurrentWindow";
NSString *MMNoFontSubstitutionKey       = @"MMNoFontSubstitution";
NSString *MMLoginShellKey               = @"MMLoginShell";
NSString *MMUntitledWindowKey           = @"MMUntitledWindow";
NSString *MMTexturedWindowKey           = @"MMTexturedWindow";
NSString *MMZoomBothKey                 = @"MMZoomBoth";
NSString *MMCurrentPreferencePaneKey    = @"MMCurrentPreferencePane";
NSString *MMLoginShellCommandKey        = @"MMLoginShellCommand";
NSString *MMLoginShellArgumentKey       = @"MMLoginShellArgument";
NSString *MMDialogsTrackPwdKey          = @"MMDialogsTrackPwd";
NSString *MMOpenLayoutKey               = @"MMOpenLayout";
NSString *MMVerticalSplitKey            = @"MMVerticalSplit";
NSString *MMPreloadCacheSizeKey         = @"MMPreloadCacheSize";
NSString *MMLastWindowClosedBehaviorKey = @"MMLastWindowClosedBehavior";
#ifdef INCLUDE_OLD_IM_CODE
NSString *MMUseInlineImKey              = @"MMUseInlineIm";
#endif // INCLUDE_OLD_IM_CODE
NSString *MMSuppressTerminationAlertKey = @"MMSuppressTerminationAlert";
NSString *MMDrawerPreferredEdgeKey      = @"MMDrawerPreferredEdge";



@implementation NSIndexSet (MMExtras)

+ (id)indexSetWithVimList:(NSString *)list
{
    NSMutableIndexSet *idxSet = [NSMutableIndexSet indexSet];
    NSArray *array = [list componentsSeparatedByString:@"\n"];
    unsigned i, count = [array count];

    for (i = 0; i < count; ++i) {
        NSString *entry = [array objectAtIndex:i];
        if ([entry intValue] > 0)
            [idxSet addIndex:i];
    }

    return idxSet;
}

@end // NSIndexSet (MMExtras)




@implementation NSDocumentController (MMExtras)

- (void)noteNewRecentFilePath:(NSString *)path
{
    NSURL *url = [NSURL fileURLWithPath:path];
    if (url)
        [self noteNewRecentDocumentURL:url];
}

- (void)noteNewRecentFilePaths:(NSArray *)paths
{
    NSEnumerator *e = [paths objectEnumerator];
    NSString *path;
    while ((path = [e nextObject]))
        [self noteNewRecentFilePath:path];
}

@end // NSDocumentController (MMExtras)




@implementation NSSavePanel (MMExtras)

- (void)hiddenFilesButtonToggled:(id)sender
{
    [self setShowsHiddenFiles:[sender intValue]];
}

- (void)setShowsHiddenFiles:(BOOL)show
{
    // This is undocumented stuff, so be careful. This does the same as
    //     [[self _navView] setShowsHiddenFiles:show];
    // but does not produce warnings.

    if (![self respondsToSelector:@selector(_navView)])
        return;

    id navView = [self performSelector:@selector(_navView)];
    if (![navView respondsToSelector:@selector(setShowsHiddenFiles:)])
        return;

    // performSelector:withObject: does not support a BOOL
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
        [navView methodSignatureForSelector:@selector(setShowsHiddenFiles:)]];
    [invocation setTarget:navView];
    [invocation setSelector:@selector(setShowsHiddenFiles:)];
    [invocation setArgument:&show atIndex:2];
    [invocation invoke];
}

@end // NSSavePanel (MMExtras)




@implementation NSMenu (MMExtras)

- (int)indexOfItemWithAction:(SEL)action
{
    int i, count = [self numberOfItems];
    for (i = 0; i < count; ++i) {
        NSMenuItem *item = [self itemAtIndex:i];
        if ([item action] == action)
            return i;
    }

    return -1;
}

- (NSMenuItem *)itemWithAction:(SEL)action
{
    int idx = [self indexOfItemWithAction:action];
    return idx >= 0 ? [self itemAtIndex:idx] : nil;
}

- (NSMenu *)findMenuContainingItemWithAction:(SEL)action
{
    // NOTE: We only look for the action in the submenus of 'self'
    int i, count = [self numberOfItems];
    for (i = 0; i < count; ++i) {
        NSMenu *menu = [[self itemAtIndex:i] submenu];
        NSMenuItem *item = [menu itemWithAction:action];
        if (item) return menu;
    }

    return nil;
}

- (NSMenu *)findWindowsMenu
{
    return [self findMenuContainingItemWithAction:
        @selector(performMiniaturize:)];
}

- (NSMenu *)findApplicationMenu
{
    // TODO: Just return [self itemAtIndex:0]?
    return [self findMenuContainingItemWithAction:@selector(terminate:)];
}

- (NSMenu *)findServicesMenu
{
    // NOTE!  Our heuristic for finding the "Services" menu is to look for the
    // second item before the "Hide MacVim" menu item on the "MacVim" menu.
    // (The item before "Hide MacVim" should be a separator, but this is not
    // important as long as the item before that is the "Services" menu.)

    NSMenu *appMenu = [self findApplicationMenu];
    if (!appMenu) return nil;

    int idx = [appMenu indexOfItemWithAction: @selector(hide:)];
    if (idx-2 < 0) return nil;  // idx == -1, if selector not found

    return [[appMenu itemAtIndex:idx-2] submenu];
}

- (NSMenu *)findFileMenu
{
    return [self findMenuContainingItemWithAction:@selector(performClose:)];
}

@end // NSMenu (MMExtras)




@implementation NSToolbar (MMExtras)

- (NSUInteger)indexOfItemWithItemIdentifier:(NSString *)identifier
{
    NSArray *items = [self items];
    NSUInteger i, count = [items count];
    for (i = 0; i < count; ++i) {
        id item = [items objectAtIndex:i];
        if ([[item itemIdentifier] isEqual:identifier])
            return i;
    }

    return NSNotFound;
}

- (NSToolbarItem *)itemAtIndex:(NSUInteger)idx
{
    NSArray *items = [self items];
    if (idx < 0 || idx >= [items count])
        return nil;

    return [items objectAtIndex:idx];
}

- (NSToolbarItem *)itemWithItemIdentifier:(NSString *)identifier
{
    NSUInteger idx = [self indexOfItemWithItemIdentifier:identifier];
    return idx != NSNotFound ? [self itemAtIndex:idx] : nil;
}

@end // NSToolbar (MMExtras)




@implementation NSTabView (MMExtras)

- (void)removeAllTabViewItems
{
    NSArray *existingItems = [self tabViewItems];
    NSEnumerator *e = [existingItems objectEnumerator];
    NSTabViewItem *item;
    while ((item = [e nextObject])) {
        [self removeTabViewItem:item];
    }
}

@end // NSTabView (MMExtras)




@implementation NSNumber (MMExtras)

// HACK to allow font size to be changed via menu (bound to Cmd+/Cmd-)
- (NSInteger)tag
{
    return [self intValue];
}

@end // NSNumber (MMExtras)




@implementation NSView (MMExtras)

// Convert from view coordinate to screen coordinate
- (NSPoint)convertToScreen:(NSPoint)point
{
    NSWindow *win = [self window];
    return [win convertBaseToScreen:[self convertPoint:point toView:nil]];
}

// Convert to view coordinate from screen coordinate
- (NSPoint)convertFromScreen:(NSPoint)point
{
    NSWindow *win = [self window];
    return [win convertScreenToBase:[self convertPoint:point fromView:nil]];
}

- (NSSize)calculateDesiredSize
{
    // Call 'desiredSize' to get desired size for view _if_ we respond to this
    // selector.  Since 'desiredSize' returns an NSSize we have to jump through
    // hoops to actually call this selector.
    // If we do not support this selector then it is assumed that the desired
    // size equals the current size.
    NSSize size = [self frame].size;
    if ([self respondsToSelector:@selector(desiredSize)]) {
        // Get method signature for method which takes no argument and returns
        // an NSSize (we don't use 'desiredSize' since it is defined in a class
        // which should not included here).
        NSMethodSignature *sig = [NSWindow instanceMethodSignatureForSelector:
                                                    @selector(contentMaxSize)];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setSelector:@selector(desiredSize)];
        [inv setTarget:self];
        [inv invoke];
        [inv getReturnValue:&size];
        ASLogTmp(@"size=%@  desired=%@", NSStringFromSize([self frame].size),
                NSStringFromSize(size));
    }

    NSEnumerator *e = [[self subviews] objectEnumerator];
    NSView *v;
    while ((v = [e nextObject])) {
        NSSize desiredSize = [v calculateDesiredSize];
        NSSize actualSize  = [v frame].size;

        size.width  += desiredSize.width  - actualSize.width + 1;
        size.height += desiredSize.height - actualSize.height + 2;
    }

    return size;
}

@end




@implementation NSScreen (MMExtras)

// Return the frame (in screen coordinates) where it is possible to drag to
// resize a window.
- (NSRect)resizableFrame
{
    NSRect f = [self frame];
    NSRect v = [self visibleFrame];

    // We assume that "visibleFrame" may be smaller than "frame" to compensate
    // for the Dock or menu bar.  The Dock is assumed to be positioned
    // left/right/bottom of the screen and the menu at the top.
    v.size.width = f.size.width;
    v.size.height += v.origin.y - f.origin.y;
    v.origin = f.origin;

    return v;
}

@end




    NSView *
showHiddenFilesView()
{
    // Return a new button object for each NSOpenPanel -- several of them
    // could be displayed at once.
    // If the accessory view should get more complex, it should probably be
    // loaded from a nib file.
    NSButton *button = [[[NSButton alloc]
        initWithFrame:NSMakeRect(0, 0, 140, 18)] autorelease];
    [button setTitle:
        NSLocalizedString(@"Show Hidden Files", @"Show Hidden Files Checkbox")];
    [button setButtonType:NSSwitchButton];

    [button setTarget:nil];
    [button setAction:@selector(hiddenFilesButtonToggled:)];

    // Use the regular control size (checkbox is a bit smaller without this)
    NSControlSize buttonSize = NSRegularControlSize;
    float fontSize = [NSFont systemFontSizeForControlSize:buttonSize];
    NSCell *theCell = [button cell];
    NSFont *theFont = [NSFont fontWithName:[[theCell font] fontName]
                                      size:fontSize];
    [theCell setFont:theFont];
    [theCell setControlSize:buttonSize];
    [button sizeToFit];

    return button;
}




    NSString *
normalizeFilename(NSString *filename)
{
    return [filename precomposedStringWithCanonicalMapping];
}

    NSArray *
normalizeFilenames(NSArray *filenames)
{
    NSMutableArray *outnames = [NSMutableArray array];
    if (!filenames)
        return outnames;

    unsigned i, count = [filenames count];
    for (i = 0; i < count; ++i) {
        NSString *nfkc = normalizeFilename([filenames objectAtIndex:i]);
        [outnames addObject:nfkc];
    }

    return outnames;
}
