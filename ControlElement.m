/* ControlElement.m
 *
 * Copyright (C) 2006-2008 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <rfm@gnu.org>
 * Date:	2006,2008
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

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSTheme.h>
#import	"AppController.h"
#import	"ThemeDocument.h"
#import "ControlElement.h"
#import "TilesBox.h"

@implementation ControlElement

- (void) dealloc
{
  [images release];
  [super dealloc];
}

- (NSString*) imageName
{
  return [images objectForKey: [[tilesMenu selectedItem] title]];
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
      NSAssert(tilesImages != nil, NSInternalInconsistencyException);
      tiles = [[TilesBox alloc]
	initWithFrame: [[tilesImages contentView] frame]];
      [tiles setOwner: self];
      [tilesImages setContentView: tiles]; 
      RELEASE(tiles);

      /* Set the images in the popup
       */
      images = [imageInfo copy];
      titles = [[images allKeys] sortedArrayUsingSelector: @selector(compare:)];
      count = [titles count];
      for (i = 0; i < count; i++)
        {
	  [tilesMenu insertItemWithTitle: [titles objectAtIndex: i] atIndex: i];
	}
      count = [[tilesMenu itemArray] count];
      while (count > i)
        {
	  [tilesMenu removeItemAtIndex: --count];
	}

      /* Select the first image and make it active.
       */
      [tilesMenu selectItemAtIndex: 0];
      [self takeTileStyle: tilesStyle];
      [self takeTileSelection: tilesMenu];
    }
  return self;
}

- (int) style
{
  return [[tilesStyle selectedItem] tag];
}

- (void) takeCodeDelete: (id)sender
{
  /* insert your code here */
}


- (void) takeCodeEdit: (id)sender
{
  /* insert your code here */
}


- (void) takeCodeMethod: (id)sender
{
  /* insert your code here */
}


- (void) takeColorName: (id)sender
{
  /* insert your code here */
}


- (void) takeColorValue: (id)sender
{
  /* insert your code here */
}


- (void) takeTileImage: (id)sender
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
	  [self takeTileSelection: tilesMenu];
	}
    }
}


- (void) takeTilePosition: (id)sender
{
  if (sender == tilesHorizontal)
    {
      [owner setTiles: [self imageName]
	     withPath: nil
	    hDivision: [sender intValue]
	    vDivision: 0];
      [tiles setNeedsDisplay: YES];
    }
  if (sender == tilesVertical)
    {
      [owner setTiles: [self imageName]
	     withPath: nil
	    hDivision: 0
	    vDivision: [sender intValue]];
      [tiles setNeedsDisplay: YES];
    }
}


- (void) takeTileSelection: (id)sender
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

      [tilesHorizontal setMinValue: 1.0];
      [tilesVertical setMinValue: 1.0];
      [tilesHorizontal setMaxValue: (double)mh];
      [tilesVertical setMaxValue: (double)mv];
      [tilesHorizontal setIntValue: h];
      [tilesVertical setIntValue: v];
      [tilesHorizontal setNumberOfTickMarks: mh];
      [tilesVertical setNumberOfTickMarks: mv];
      [tilesHorizontal setAllowsTickMarkValuesOnly: YES];
      [tilesVertical setAllowsTickMarkValuesOnly: YES];
    }
  [tiles setNeedsDisplay: YES];
}


- (void) takeTileStyle: (id)sender
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
	  [tilesImages setContentView: tiles]; 
	  RELEASE(tiles);
	}
    }
  else
    {
      if ([tiles isKindOfClass: [FlippedTilesBox class]] == YES)
        {
	  tiles = [[TilesBox alloc] initWithFrame: [tiles frame]];
	  [tiles setOwner: self];
	  [tilesImages setContentView: tiles]; 
	  RELEASE(tiles);
	}
    }
  [tiles setNeedsDisplay: YES];
}

@end
