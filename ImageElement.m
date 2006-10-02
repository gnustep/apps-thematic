/* ImageElement.m
 *
 * Copyright (C) 2006 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <rfm@gnu.org>
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
  NSImage	*current;
  NSString	*name;
  NSString	*path;
  NSString	*description;	// not retained
}
- (NSImage*) current;
- (NSString*) description;
- (id) initWithImage: (NSImage*)i description: (NSString*)d;
- (NSString*) name;
- (NSString*) path;
- (void) revert;
- (void) setCurrentImage: (NSImage*)i atPath: (NSString*)p;
@end

@implementation	ImageInfo
- (NSImage*) current
{
  return current;
}

- (void) dealloc
{
  RELEASE(original);
  RELEASE(current);
  RELEASE(description);
  RELEASE(name);
  RELEASE(path);
  [super dealloc];
}

- (NSString*) description
{
  return description;
}

- (id) initWithImage: (NSImage*)i description: (NSString*)d
{
  ASSIGN(original, i);
  ASSIGN(current, i);
  ASSIGN(description, d);
  ASSIGN(name, [[original name] substringFromIndex: 7]);
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
  DESTROY(path);
  ASSIGN(current, original);
}

- (void) setCurrentImage: (NSImage*)i atPath: (NSString*)p
{
  ASSIGN(current, i);
  ASSIGN(path, p);
  [[[AppController sharedController] selectedDocument] setImage: path
							 forKey: name];
}
@end



@interface	ImagesView : NSMatrix
{
  NSMutableArray	*objects;
  ImageInfo		*selected;
  NSTextField		*description;
}
- (void) addObject: (ImageInfo*)anObject;
- (void) makeSelectionVisible: (BOOL)flag;
- (void) refreshCells;
- (void) selectObject: (ImageInfo*)obj;
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
  int	row = [self selectedRow];
  int	col = [self selectedColumn];
  int	index = row * [self numberOfColumns] + col;
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
  [super dealloc];
}

- (void) importImage: (id)sender
{
  NSArray	*fileTypes = [NSImage imageFileTypes];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: NSHomeDirectory()
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
	  [selected setCurrentImage: image atPath: path];
	  RELEASE(image);
	  [self refreshCells];
	}
    }
  [self selectObject: selected];
  [self makeSelectionVisible: YES];
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
  unsigned	count = [objects count];
  unsigned	index;
  int		cols = 0;
  int		rows;
  int		width;

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

      [but setImage: [img current]];
      [but setTitle: @""];
      //[but setTitle: [img name]];
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
  unsigned	pos = [objects indexOfObjectIdenticalTo: anObject];
  NSRect	rect;
  int		r;
  int		c;

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
  unsigned	pos;

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

- (void) setDescription: (NSTextField*)d
{
  description = d;
}
@end



@implementation ImageElement

- (id) initWithView: (NSView*)aView
	      owner: (ThemeDocument*)aDocument
{
  if ((self = [super initWithView: aView owner: aDocument]) != nil)
    {
      NSRect		frame;

      frame = [[scrollView documentView] frame];
      frame.origin = NSZeroPoint;
  
      imagesView = [[ImagesView alloc] initWithFrame: frame];
      [imagesView setDescription: description];
      [scrollView setDocumentView: imagesView];
      RELEASE(imagesView);
  
#define	I(X,Y) {\
NSImage *i = [NSImage imageNamed: [@"common_" stringByAppendingString: X]]; \
ImageInfo *ii = [[ImageInfo alloc] initWithImage: i description: Y]; \
[imagesView addObject: ii]; \
RELEASE(ii); \
}
I(@"3DArrowDown", @"Pulldown menu marker");
I(@"3DArrowRight", @"Right arrow used in browsers");
I(@"3DArrowRightH", @"Highlighted Right arrow used in browsers");
I(@"ArrowDown", @"Scroller Down arrow");
I(@"ArrowDownH", @"Highlighted Scroller Down arrow");
I(@"ArrowLeft", @"Scroller Left arrow");
I(@"ArrowLeftH", @"Highlighted Scroller Left arrow");
I(@"ArrowRight", @"Scroller Right arrow");
I(@"ArrowRightH", @"Highlighted Scroller Right arrow");
I(@"ArrowUp", @"Scroller Up arrow");
I(@"ArrowUpH", @"Highlighted Scroller Up arrow");
I(@"CenterTabStop", @"Ruler mark (center tab stop)");
I(@"Close", @"Window Close button");
I(@"CloseBroken", @"Window Close button for document needing saving");
I(@"CloseBrokenH", @"Highlighted Window Close button for document needing saving");
I(@"CloseH", @"Highlighted Window Close button");
I(@"ColorSwatch", @"Color swatch");
I(@"DecimalTabStop", @"Ruler mark (decimal tab stop)");
I(@"Dimple", @"Scroller thumb dimple");
I(@"Home", @"Home directory icon");
I(@"LeftTabStop", @"Ruler mark (left tab stop)");
I(@"Miniaturize", @"Window Miniaturize button");
I(@"MiniaturizeH", @"Highlighted Window Miniaturize button");
I(@"Mount", @"Disk mount icon");
I(@"Nibble", @"Popup menu marker");
I(@"Printer", @"Printer icon (used on toolbar)");
I(@"RightTabStop", @"Ruler mark (right tab stop)");
I(@"SliderHoriz", @"Horizontal Slider");
I(@"SliderVert", @"Vertical Slider");
I(@"TabDownSelectedLeft", @"Tab view (down selected left)");
I(@"TabDownSelectedRight", @"Tab view (down selected right)");
I(@"TabDownSelectedToUnSelectedJunction", @"Tab view (down selected to unselected junction)");
I(@"TabDownUnSelectedJunction", @"Tab view (down unselected junction)");
I(@"TabDownUnSelectedLeft", @"Tab view (down unselected left)");
I(@"TabDownUnSelectedRight", @"Tab view (down unselected right)");
I(@"TabDownUnSelectedToSelectedJunction", @"Tab view (down unselected to selected junction)");
I(@"TabSelectedLeft", @"Tab view (selected left)");
I(@"TabSelectedRight", @"Tab view (selected right)");
I(@"TabSelectedToUnSelectedJunction", @"Tab view (selected to unselected junction)");
I(@"TabUnSelectToSelectedJunction", @"Tab view (unselected to selected junction)");
I(@"TabUnSelectedJunction", @"Tab view (unselected junction)");
I(@"TabUnSelectedLeft", @"Tab view (unselected left)");
I(@"TabUnSelectedRight", @"Tab view (unselected right)");
I(@"Tile", @"Icon background tile");
I(@"ToolbarClippedItemsMark", @"Toolbar mark for clipped items");
I(@"ToolbarCustomizeToolbarItem", @"Toolbar Customize item");
I(@"ToolbarSeparatorItem", @"Toolbar Separator item");
I(@"ToolbarShowColorsItem", @"Toolbar Colors item");
I(@"ToolbarShowFontsItem", @"Toolbar Font item");
I(@"Unmount", @"Disk unmount icon");
I(@"copyCursor", @"Cursor (dragging over view which will copy)");
I(@"linkCursor", @"Cursor (dragging over view which will link)");
I(@"noCursor", @"Cursor (dragging over view which won't accept drop)");
I(@"outlineCollapsed", @"Outline view marker for collapsed outline");
I(@"outlineExpanded", @"Outline view marker for expanded outline");
I(@"outlineUnexpandable", @"Outline view marker for unexpandable outline");
I(@"ret", @"Return/Enter key");
I(@"retH", @"Highlighted Return/Enter key");

    }
  return self;
}

@end

