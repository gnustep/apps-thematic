/* TiledElement.m
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
#import <GNUstepGUI/GSTheme.h>
#import	"AppController.h"
#import	"ThemeDocument.h"
#import	"TiledElement.h"

@interface	TilesBox : NSView
{
  TiledElement	*owner;
}
- (void) setOwner: (TiledElement*)o;
@end
@interface	FlippedTilesBox : TilesBox
@end


@implementation	TilesBox

- (void) drawRect: (NSRect)rect
{
  GSDrawTiles	*t;
  NSColor	*b = [NSColor controlBackgroundColor];

  t = [[GSTheme theme] tilesNamed: [owner imageName] cache: YES];
  if (t == nil)
    {
      NSRectFill([self bounds]);
    }
  else
    {
      GSThemeFillStyle	s = 0;

      switch ([owner style])
        {
	  case 5:
	  case 0:	s = GSThemeFillStyleMatrix; break;
	  case 6:
	  case 1:	s = GSThemeFillStyleRepeat; break;
	  case 7:
	  case 2:	s = GSThemeFillStyleCenter; break;
	  case 8:
	  case 3:	s = GSThemeFillStyleScale; break;
	  case 9:
	  case 4:	s = GSThemeFillStyleNone; break;
        }
      [[GSTheme theme] fillRect: [self bounds]
		      withTiles: t
		     background: b
		      fillStyle: s];
    }
}

- (void) mouseDown: (NSEvent*)anEvent
{
  [owner takeImage: self];
}

- (void) setOwner: (TiledElement*)o
{
  owner = o;
}
@end

@implementation	FlippedTilesBox
- (BOOL) isFlipped
{
  return YES;
}
@end

@implementation TiledElement

- (void) dealloc
{
  RELEASE(images);
  return [super dealloc];
}

- (NSString*) imageName
{
  return [images objectForKey: [[popup selectedItem] title]];
}

- (id) initWithView: (NSView*)aView
              owner: (ThemeDocument*)aDocument
	     images: (NSDictionary*)imageInfo
{
  self = [super initWithView: aView owner: aDocument];
  if (self != nil)
    {
      NSArray		*titles;
      unsigned		count;
      unsigned		i;

      /* Create view in which to draw image
       */
      tiles = [[TilesBox alloc] initWithFrame: [[imageBox contentView] frame]];
      [tiles setOwner: self];
      [imageBox setContentView: tiles]; 
      RELEASE(tiles);

      /* Set the images in the popup
       */
      images = [imageInfo copy];
      titles = [[images allKeys] sortedArrayUsingSelector: @selector(compare:)];
      count = [titles count];
      for (i = 0; i < count; i++)
        {
	  [popup insertItemWithTitle: [titles objectAtIndex: i] atIndex: i];
	}
      count = [[popup itemArray] count];
      while (count > i)
        {
	  [popup removeItemAtIndex: --count];
	}

      /* Select the first image and make it active.
       */
      [popup selectItemAtIndex: 0];
      [self takeStyle: style];
      [self takeSelection: popup];
    }
  return self;
}

- (int) style
{
  return [[style selectedItem] tag];
}

- (void) takeImage: (id)sender
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
	  NSSize	s = [image size];
	  int		h = (int)s.width;
	  int		v = (int)s.height;

	  RELEASE(image);
	  [owner setTiles: [self imageName]
	  	 withPath: path
		hDivision: (h / 3)
		vDivision: (v / 3)];
	  [self takeSelection: popup];
	}
    }
}

- (void) takePosition: (id)sender
{
  if (sender == hSlider)
    {
      [owner setTiles: [self imageName]
	     withPath: nil
	    hDivision: [sender intValue]
	    vDivision: 0];
      [tiles setNeedsDisplay: YES];
    }
  if (sender == vSlider)
    {
      [owner setTiles: [self imageName]
	     withPath: nil
	    hDivision: 0
	    vDivision: [sender intValue]];
      [tiles setNeedsDisplay: YES];
    }
}

- (void) takeSelection: (id)sender
{
  NSImage	*image;
  int		h;
  int		v;

  image = [owner tiles: [self imageName] hDivision: &h vDivision: &v];
  if (image != nil)
    {
      NSSize	s = [image size];
      int	mh = (int)(s.width / 2);
      int	mv = (int)(s.width / 2);

      [hSlider setMinValue: 1.0];
      [vSlider setMinValue: 1.0];
      [hSlider setMaxValue: (double)mh];
      [vSlider setMaxValue: (double)mv];
      [hSlider setIntValue: h];
      [vSlider setIntValue: v];
      [hSlider setNumberOfTickMarks: mh];
      [vSlider setNumberOfTickMarks: mv];
      [hSlider setAllowsTickMarkValuesOnly: YES];
      [vSlider setAllowsTickMarkValuesOnly: YES];
    }
  [tiles setNeedsDisplay: YES];
}

- (void) takeStyle: (id)sender
{
  /* Change tiles box to be flipped or non-flipped as necessary,
   * then get it to redraw in the new style.
   * NB. To use this code (debug purposes) you need to edit the TiledElement
   * GORM file so that the popup menu for selecting the display style has
   * five extra buttons (with tags 5-9) for drawing in a flipped view.
   */
  if ([sender tag] > 4)
    {
      if ([tiles isKindOfClass: [FlippedTilesBox class]] == NO)
        {
	  tiles = [[FlippedTilesBox alloc] initWithFrame: [tiles frame]];
	  [tiles setOwner: self];
	  [imageBox setContentView: tiles]; 
	  RELEASE(tiles);
	}
    }
  else
    {
      if ([tiles isKindOfClass: [FlippedTilesBox class]] == YES)
        {
	  tiles = [[TilesBox alloc] initWithFrame: [tiles frame]];
	  [tiles setOwner: self];
	  [imageBox setContentView: tiles]; 
	  RELEASE(tiles);
	}
    }
  [tiles setNeedsDisplay: YES];
}
@end

