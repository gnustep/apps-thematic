/* ImageElement.m
 *
 * Copyright (C) 2006-2016 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <rfm@gnu.org>
 *              Riccardo Mottola
 * Date:	2006
 * 
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import	"AppController.h"
#import	"ThemeDocument.h"
#import	"ImageElement.h"

@interface	ImageInfo : NSObject
{
  NSImage	*original;
  NSString	*app;
  NSString	*name;
  NSString	*path;
  NSString	*description;	// not retained
}
- (NSString*) app;
- (NSString*) description;
- (NSImage*) image;
- (id) initWithImage: (NSImage*)i
         description: (NSString*)d
                name: (NSString*)n
                 app: (NSString*)a;
- (NSString*) name;
- (NSString*) path;
- (void) revert;
- (void) setCurrentImage: (NSImage*)i
                  atPath: (NSString*)p;
@end

@implementation	ImageInfo

- (NSString*) app
{
  return app;
}

- (void) dealloc
{
  RELEASE(original);
  RELEASE(description);
  RELEASE(name);
  RELEASE(path);
  RELEASE(app);
  [super dealloc];
}

- (NSString*) description
{
  return description;
}

- (NSImage*) image
{
  return original;
}

- (id) initWithImage: (NSImage*)i
         description: (NSString*)d
                name: (NSString*)n
                 app: (NSString*)a
{
  ASSIGN(original, i);
  ASSIGN(description, d);
  ASSIGNCOPY(app, a);
  ASSIGNCOPY(name, n);
  return self;
}

- (NSString*) name
{
  return name;
}

- (NSString*) path
{
  return path;
}

- (void) revert
{
  NSString      *key;

  DESTROY(path);
  key = [self name];
  if (nil != app) key = [app stringByAppendingPathComponent: key];
  [[[AppController sharedController] selectedDocument] setImage: nil
							 forKey: key];
}

- (void) setCurrentImage: (NSImage*)i
                  atPath: (NSString*)p
{
  NSString      *key;

  ASSIGN(path, p);
  key = [self name];
  if (nil != app) key = [app stringByAppendingPathComponent: key];
  [[[AppController sharedController] selectedDocument] setImage: path
							 forKey: key];
}
@end

@interface	DummyInfo : ImageInfo
@end
@implementation DummyInfo
- (NSString*) name
{
  return @"";
}
- (void) revert
{
  return;
}
@end


@interface	ImagesView : NSMatrix
{
  NSMutableArray	*objects;
  ImageInfo		*selected;
  NSTextField		*description;
  NSString		*lastPath;
  NSString              *bundleIdentifier;
}
- (void) addObject: (ImageInfo*)anObject;
- (void) makeSelectionVisible: (BOOL)flag;
- (void) refreshCells;
- (void) selectObject: (ImageInfo*)obj;
- (ImageInfo*) selected;
- (void) setBundleIdentifier: (NSString*)i;
- (void) setDescription: (NSTextField*)d;
@end

@implementation	ImagesView


- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;   /* Ensure we get initial mouse down event.      */
}

- (void) addObject: (ImageInfo*)anObject
{
  if (anObject != nil
    && [objects indexOfObjectIdenticalTo: anObject] == NSNotFound)
    {
      [objects addObject: anObject];
      [self refreshCells];
    }
}

- (void) changeSelection: (id)sender
{
  NSInteger row = [self selectedRow];
  NSInteger col = [self selectedColumn];
  NSInteger index = row * [self numberOfColumns] + col;
  id	obj = nil;

  if (index >= 0 && index < [objects count])
    {
      obj = [objects objectAtIndex: index];
      [self selectObject: obj];
    }
}

- (void) dealloc
{
  RELEASE(objects);
  RELEASE(lastPath);
  RELEASE(bundleIdentifier);
  [super dealloc];
}

- (void) deleteImage: (id)sender
{
  if (NO == [selected isKindOfClass: [DummyInfo class]])
    {
      [selected revert];
      [self makeSelectionVisible: NO];
      if (nil != bundleIdentifier)
        {
          [objects removeObjectIdenticalTo: selected];
          [self refreshCells];
          selected = [objects objectAtIndex: 0];        // Add new image
        }
      [self selectObject: selected];
    }
}

- (void) importImage: (id)sender
{
  NSArray	*fileTypes = [NSImage imageFileTypes];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  NSInteger	result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: lastPath
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      NSString	*path = [oPanel filename];
      NSImage	*image = nil;

      NS_DURING
	{
	  image = [[NSImage alloc] initWithContentsOfFile: path];
	}
      NS_HANDLER
	{
	  NSString *message = [localException reason];
	  NSRunAlertPanel(_(@"Problem loading image"), 
			  message,
			  nil, nil, nil);
	}
      NS_ENDHANDLER
      if (image != nil)
        {
	  ASSIGN(lastPath, [path stringByDeletingLastPathComponent]);
          if ([selected isKindOfClass: [DummyInfo class]])
            {
              NSString  *name;

              name = [[path lastPathComponent] stringByDeletingPathExtension];
              selected = [[ImageInfo alloc] initWithImage: image
                                              description: name
                                                     name: name
                                                      app: bundleIdentifier];
              [self addObject: selected];
              RELEASE(selected);
            }
          [selected setCurrentImage: image atPath: path];
	  RELEASE(image);
	  [self refreshCells];
	}
    }
  [self makeSelectionVisible: NO];
  [self selectObject: selected];
}

- (id) initWithFrame: (NSRect)frame
{
  if ((self = [super initWithFrame: frame]) != nil)
    {
      id	proto;

      [self setAutosizesCells: NO];
      [self setCellSize: NSMakeSize(72,72)];
      [self setIntercellSpacing: NSMakeSize(8,8)];
      [self setAutoresizingMask: NSViewMinYMargin|NSViewWidthSizable];
      [self setMode: NSRadioModeMatrix];

      objects = [[NSMutableArray alloc] init];
      proto = [[NSButtonCell alloc] init];
      [proto setBordered: NO];
      [proto setAlignment: NSCenterTextAlignment];
      [proto setImagePosition: NSImageAbove];
      [proto setSelectable: NO];
      [proto setEditable: NO];
      [self setPrototype: proto];
      RELEASE(proto);

      [self setAction: @selector(changeSelection:)];
      [self setDoubleAction: @selector(importImage:)];
      [self setTarget: self];
    }
  return self;
}

- (void) makeSelectionVisible: (BOOL)flag
{
  if (flag == YES && selected != nil)
    {
      unsigned	pos = [objects indexOfObjectIdenticalTo: selected];
      int	r = pos / [self numberOfColumns];
      int	c = pos % [self numberOfColumns];

      [self selectCellAtRow: r column: c];
    }
  else
    {
      [self deselectAllCells];
    }
  [self displayIfNeeded];
  [[self window] flushWindow];
}

- (void) refreshCells
{
  NSUInteger	count = [objects count];
  NSUInteger	index;
  NSInteger	cols = 0;
  NSInteger	rows;
  NSInteger	width;

  width = [[self superview] bounds].size.width;
  while (width >= 72)
    {
      width -= (72 + 8);
      cols++;
    }
  if (cols == 0)
    {
      cols = 1;
    }
  rows = count / cols;
  if (rows == 0 || rows * cols != count)
    {
      rows++;
    }
  [self renewRows: rows columns: cols];

  for (index = 0; index < count; index++)
    {
      ImageInfo		*img = [objects objectAtIndex: index];
      NSButtonCell	*but = [self cellAtRow: index/cols column: index%cols];

      [but setImage: [img image]];
      /* Make sure big images are shrunk to fit.
       */
      if ([[img image] size].width > 64
        || [[img image] size].height > 64)
        {
          [but setImageScaling: NSImageScaleProportionallyUpOrDown];
        }
      else
        {
          [but setImageScaling: NSImageScaleNone];
        }
      [but setTitle: @""];
      [but setShowsStateBy: NSChangeGrayCellMask];
      [but setHighlightsBy: NSChangeGrayCellMask];
    }
  while (index < rows * cols)
    {
      NSButtonCell	*but = [self cellAtRow: index/cols column: index%cols];

      [but setImage: nil];
      [but setTitle: @""];
      [but setShowsStateBy: NSNoCellMask];
      [but setHighlightsBy: NSNoCellMask];
      index++;
    }
  [self setIntercellSpacing: NSMakeSize(8,8)];
  [self sizeToCells];
  [self setNeedsDisplay: YES];
}

/*
 * Return the rectangle in which an objects image will be displayed.
 * (use window coordinates)
 */
- (NSRect) rectForObject: (id)anObject
{
  NSInteger	pos = [objects indexOfObjectIdenticalTo: anObject];
  NSRect	rect;
  NSInteger	r;
  NSInteger	c;

  if (pos == NSNotFound)
    return NSZeroRect;
  r = pos / [self numberOfColumns];
  c = pos % [self numberOfColumns];
  rect = [self cellFrameAtRow: r column: c];
  /*
   * Adjust to image area.
   */
  rect.size.height -= 15;
  rect = [self convertRect: rect toView: nil];
  return rect;
}

- (void) removeObject: (id)anObject
{
  NSInteger	pos;

  pos = [objects indexOfObjectIdenticalTo: anObject];
  if (pos == NSNotFound)
    {
      return;
    }
  [objects removeObjectAtIndex: pos];
  [self refreshCells];
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  [self refreshCells];
}

- (void) selectObject: (ImageInfo*)obj
{
  selected = obj;
  [description setStringValue: [obj description]];
  [self makeSelectionVisible: YES];
}

- (ImageInfo*) selected
{
  return selected;
}

- (void) setBundleIdentifier: (NSString*)i
{
  ASSIGN(bundleIdentifier, i);
}

- (void) setDescription: (NSTextField*)d
{
  description = d;
}

@end



@implementation ImageElement

- (void) dealloc
{
  RELEASE(texts);
  RELEASE(views);
  RELEASE(systemView);
  RELEASE(textView);
  [super dealloc];
}

- (void) deleteImage: (id)sender
{
  [imagesView deleteImage: sender];
}

- (void) importImage: (id)sender
{
  [imagesView importImage: sender];
}

- (id) initWithView: (NSView*)aView
	      owner: (ThemeDocument*)aDocument
{
  if ((self = [super initWithView: aView owner: aDocument]) != nil)
    {
      NSRect	        frame;
      NSDictionary      *apps;
      NSEnumerator      *appEnum;
      NSString          *app;
      NSInteger         tag;

      selectedTag = -2;

      frame = [[scrollView documentView] frame];
      frame.origin = NSZeroPoint;
  
      texts = [NSMutableArray new];
      views = [NSMutableArray new];

      systemView = [[ImagesView alloc] initWithFrame: frame];
      [systemView setDescription: description];
  
      textView = [[NSTextView alloc] init];
      [textView setSelectable: YES];
      [textView setEditable: NO];
      [textView setDrawsBackground: YES];
      [textView setHorizontallyResizable: NO];
      [textView setVerticallyResizable: NO];
      [textView setFrameSize: frame.size];
      [[textView textStorage] replaceCharactersInRange: NSMakeRange(0,0)
        withString: @"Enter the bundle identifier of an application in order to start adding application-specific images.  You may then import images to replace the named images provided and used by that application."];

      imagesView = systemView;
      [scrollView setDocumentView: imagesView];
#define	I(X,Y) {\
NSImage *i = [NSImage imageNamed: X]; \
ImageInfo *ii = [[ImageInfo alloc] initWithImage: i description: Y name: X app: nil]; \
[imagesView addObject: ii]; \
RELEASE(ii); \
}
I(@"common_3DArrowDown", @"Pulldown menu marker");
I(@"common_3DArrowRight", @"Right arrow used in browsers");
I(@"common_3DArrowRightH", @"Highlighted Right arrow used in browsers");
I(@"common_ArrowDown", @"Scroller Down arrow");
I(@"common_ArrowDownH", @"Highlighted Scroller Down arrow");
I(@"common_ArrowLeft", @"Scroller Left arrow");
I(@"common_ArrowLeftH", @"Highlighted Scroller Left arrow");
I(@"common_ArrowRight", @"Scroller Right arrow");
I(@"common_ArrowRightH", @"Highlighted Scroller Right arrow");
I(@"common_ArrowUp", @"Scroller Up arrow");
I(@"common_ArrowUpH", @"Highlighted Scroller Up arrow");
I(@"common_CenterTabStop", @"Ruler mark (center tab stop)");
I(@"common_Close", @"Window Close button");
I(@"common_CloseBroken", @"Window Close button for document needing saving");
I(@"common_CloseBrokenH", @"Highlighted Window Close button for document needing saving");
I(@"common_CloseH", @"Highlighted Window Close button");
I(@"common_ColorSwatch", @"Color swatch");
I(@"common_DecimalTabStop", @"Ruler mark (decimal tab stop)");
I(@"common_Dimple", @"Vertical scroller thumb dimple");
I(@"common_DimpleHoriz", @"Horizontal scroller thumb dimple");
I(@"common_Home", @"Home directory icon");
I(@"common_LeftTabStop", @"Ruler mark (left tab stop)");
I(@"common_Miniaturize", @"Window Miniaturize button");
I(@"common_MiniaturizeH", @"Highlighted Window Miniaturize button");
I(@"common_Mount", @"Disk mount icon");
I(@"common_Nibble", @"Popup menu marker");
I(@"common_Printer", @"Printer icon (used on toolbar)");
I(@"common_RightTabStop", @"Ruler mark (right tab stop)");
I(@"common_SliderHoriz", @"Horizontal Slider");
I(@"common_SliderVert", @"Vertical Slider");
I(@"common_TabDownSelectedLeft", @"Tab view (down selected left)");
I(@"common_TabDownSelectedRight", @"Tab view (down selected right)");
I(@"common_TabDownSelectedToUnSelectedJunction", @"Tab view (down selected to unselected junction)");
I(@"common_TabDownUnSelectedJunction", @"Tab view (down unselected junction)");
I(@"common_TabDownUnSelectedLeft", @"Tab view (down unselected left)");
I(@"common_TabDownUnSelectedRight", @"Tab view (down unselected right)");
I(@"common_TabDownUnSelectedToSelectedJunction", @"Tab view (down unselected to selected junction)");
I(@"common_TabSelectedLeft", @"Tab view (selected left)");
I(@"common_TabSelectedRight", @"Tab view (selected right)");
I(@"common_TabSelectedToUnSelectedJunction", @"Tab view (selected to unselected junction)");
I(@"common_TabUnSelectToSelectedJunction", @"Tab view (unselected to selected junction)");
I(@"common_TabUnSelectedJunction", @"Tab view (unselected junction)");
I(@"common_TabUnSelectedLeft", @"Tab view (unselected left)");
I(@"common_TabUnSelectedRight", @"Tab view (unselected right)");
I(@"common_Tile", @"Icon background tile");
I(@"common_ToolbarClippedItemsMark", @"Toolbar mark for clipped items");
I(@"common_ToolbarCustomizeToolbarItem", @"Toolbar Customize item");
I(@"common_ToolbarSeparatorItem", @"Toolbar Separator item");
I(@"common_ToolbarShowColorsItem", @"Toolbar Colors item");
I(@"common_ToolbarShowFontsItem", @"Toolbar Font item");
I(@"common_Unmount", @"Disk unmount icon");
I(@"common_copyCursor", @"Cursor (dragging over view which will copy)");
I(@"common_linkCursor", @"Cursor (dragging over view which will link)");
I(@"common_noCursor", @"Cursor (dragging over view which won't accept drop)");
I(@"common_outlineCollapsed", @"Outline view marker for collapsed outline");
I(@"common_outlineExpanded", @"Outline view marker for expanded outline");
I(@"common_outlineUnexpandable", @"Outline view marker for unexpandable outline");
I(@"common_ret", @"Return/Enter key");
I(@"common_retH", @"Highlighted Return/Enter key");
I(@"common_Root_PC", @"Image of the Root computer - PC");
I(@"common_Desktop", @"Desktop Folder");
I(@"common_Folder", @"Folder");
I(@"common_DocsFolder", @"Documents Folder");
I(@"common_ImageFolder", @"Images Folder");
I(@"common_DownloadFolder", @"Downloads Folder");
I(@"common_GSFolder", @"System Folder");
 I(@"common_ApplicationFolder",@"Application Folder");
I(@"common_LibraryFolder", @"Library Folder");
I(@"common_MusicFolder", @"Music Folder");
I(@"common_HomeDirectory", @"Home Directory Folder");
I(@"common_Unknown", @"Unknown File");
I(@"common_UnknownApplication", @"Unknown Application");
I(@"common_UnknownTool", @"Unknown Tool");
I(@"common_VideoFolder", @"Movie Folder");
I(@"common_RadioOn", @"Selected Radio Button");
I(@"common_RadioOff", @"Unselected Radio Button");
I(@"common_SwitchOn", @"Selected Switch Button");
I(@"common_SwitchOff", @"Unselected Switch Button");
I(@"common_RecyclerEmpty", @"Recycler bin Empty");
I(@"common_RecyclerFull", @"Recycler bin Full");
I(@"common_MultipleSelection", @"Multiple selection");
 
#undef  I

      apps = [aDocument applicationImageNames];
      appEnum = [[[apps allKeys]
        sortedArrayUsingSelector: @selector(compare:)] objectEnumerator];
      tag = 0;
      while (nil != (app = [appEnum nextObject]))
        {
          NSEnumerator  *imgEnum;
          NSString      *img;
          ImagesView    *appView;
          NSImage       *i;
          ImageInfo     *ii;

          appView = [[ImagesView alloc] initWithFrame: frame];
          [appView setBundleIdentifier: app];
          [appView setDescription: description];
          [views addObject: appView];
          RELEASE(appView);
          i = [NSImage imageNamed: @"ImageAdd"];
          ii = [[DummyInfo alloc] initWithImage: i
                                    description: @"Import a new image"
                                           name: @""
                                            app: app];
          [appView addObject: ii];
          RELEASE(ii);
          [texts addObject: app];

          imgEnum = [[[apps objectForKey: app]
            sortedArrayUsingSelector: @selector(compare:)] objectEnumerator];
          while (nil != (img = [imgEnum nextObject]))
            {
              NSString  *key;

              key = [app stringByAppendingPathComponent: img];
              img = [img stringByDeletingPathExtension];
              i = [aDocument imageForKey: key];
              ii = [[ImageInfo alloc] initWithImage: i
                                        description: img
                                               name: img
                                                app: app];
              [appView addObject: ii];
              RELEASE(ii);
            }
          [collectionMenu addItemWithTitle:app];
          [[collectionMenu itemWithTitle:app] setTag:tag];
          tag++;
        }
    }
  return self;
}

- (void) switchCollection: (id)sender
{
  selectedTag = [[sender selectedItem] tag];

  if (-2 == selectedTag)
    {
      imagesView = nil;
      [deleteButton setEnabled: NO];
      [importButton setEnabled: NO];
      [description setSelectable: YES];
      [description setEditable: YES];
      [description setBezeled: YES];
      [description setDrawsBackground: YES];
      [description setStringValue: @"Enter App bundle identifier"];
      [description setAction: @selector(textEntered:)];
      [description setTarget: self];
      [description setStringValue: @"New application"];
      [scrollView setDocumentView: textView];
    }
  else
    {
      if (-1 == selectedTag)
        {
          imagesView = systemView;
          [description setStringValue: @"System images"];
        }
      else
        {
          imagesView = [views objectAtIndex: selectedTag];
          [description setStringValue: [@"Images specific to: "
            stringByAppendingString: [texts objectAtIndex: selectedTag]]];
        }
      [scrollView setDocumentView: imagesView];
      [deleteButton setEnabled: YES];
      [importButton setEnabled: YES];
      [description setSelectable: NO];
      [description setEditable: NO];
      [description setBezeled: NO];
      [description setDrawsBackground: NO];
    }
  [description display];
  [[imagesView window] setTitle:
    [NSString stringWithFormat: @"%@ Inspector", [self title]]];
}

- (void) textEntered: (id)sender
{
  NSString      *bundleIdentifier = [sender stringValue];
  NSUInteger    tag;

  bundleIdentifier = [bundleIdentifier stringByTrimmingSpaces];
  if ([bundleIdentifier length] == 0)
    {
      NSLog(@"Empty bundle identifier ignored");
      return;
    }
  if ([bundleIdentifier rangeOfString: @"/"].length > 0)
    {
      NSLog(@"Bundle identifier containing '/' ignored");
      return;
    }
  /* Do we already have this bundle identifier?
   * If so, select it.
   */
  tag = [texts indexOfObject: bundleIdentifier];
  if (NSNotFound == tag)
    {
      tag = [texts count];

      imagesView = [[ImagesView alloc] initWithFrame: [imagesView frame]];
      [imagesView setBundleIdentifier: bundleIdentifier];
      [imagesView setDescription: description];
      [views addObject: imagesView];
      RELEASE(imagesView);
      NSImage *i = [NSImage imageNamed: @"ImageAdd"];
      ImageInfo *ii = [[DummyInfo alloc] initWithImage: i
                                           description: @"Import a new image"
                                                  name: @""
                                                   app: bundleIdentifier];
      [imagesView addObject: ii];
      RELEASE(ii);
      [texts addObject: bundleIdentifier];
      [collectionMenu addItemWithTitle: bundleIdentifier];
      [[collectionMenu lastItem] setTag: tag];
    }

  [collectionMenu selectItemAtIndex:
    [collectionMenu indexOfItemWithTag: tag]];
  [self switchCollection: collectionMenu];
}

- (NSString*) title
{
  if (selectedTag < 0)
    {
      return @"System Images";
    }
  return @"Application Images";
}
@end

