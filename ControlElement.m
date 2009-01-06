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
#import "CodeEditor.h"
#import "TilesBox.h"

@implementation ControlElement

- (void) _endCodeEdit: (NSNotification*)n
{
  NSDictionary	*u = [n userInfo];
  NSString	*c = [u objectForKey: @"Control"];

  /* Check to see if the notification is for us.
   */
  if ([c isEqualToString: className] == YES)
    {
      NSString	*m = [u objectForKey: @"Method"];
      NSString	*t = [u objectForKey: @"Text"];
      NSString	*code = [owner codeForKey: m];

      /* If the code has been changed, update the documnent.
       */
      if ([t isEqual: code] == NO)
	{
	  [owner setCode: t forKey: m];
	  [[n object] codeBuildFor: owner method: m];
	}
    }
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [className release];
  [classInfo release];
  [fragments release];
  [images release];
  [super dealloc];
}

- (NSString*) elementName
{
  NSString	*n = [self imageName];

  if ([n hasSuffix: @"Highlighted"])
    {
      n = [n substringToIndex: [n length] - 11];
    }
  else if ([n hasSuffix: @"Selected"])
    {
      n = [n substringToIndex: [n length] - 8];
    }
  return n;
}

- (GSThemeControlState) elementState
{
  NSString	*n = [self imageName];

  if ([n hasSuffix: @"Highlighted"])
    {
      return GSThemeHighlightedState;
    }
  else if ([n hasSuffix: @"Selected"])
    {
      return GSThemeSelectedState;
    }
  return GSThemeNormalState;
}

- (NSString*) imageName
{
  return [images objectForKey: [[tilesMenu selectedItem] title]];
}

- (id) initWithView: (NSView*)aView
              owner: (ThemeDocument*)aDocument
{
  self = [super initWithView: aView owner: aDocument];
  if (self != nil)
    {
      AppController		*sharedController;
      NSDictionary		*codeInfo;
      NSMutableDictionary	*md;
      NSDictionary		*d;
      NSArray			*titles;
      unsigned			count;
      unsigned			i;

      sharedController = [AppController sharedController];
      codeInfo = [sharedController codeInfo];
      className = [NSStringFromClass([aView class]) retain];

      md = [NSMutableDictionary dictionary];
      d = [codeInfo objectForKey: className];
      classInfo = [d copy];
      d = [d objectForKey: @"Fragments"];
      [md addEntriesFromDictionary: d];
      d = [codeInfo objectForKey: @"Generic"];
      d = [d objectForKey: @"Fragments"];
      [md addEntriesFromDictionary: d];
      fragments = [md copy];

      /* Create view in which to draw image
       */
      NSAssert(tilesImages != nil, NSInternalInconsistencyException);
      tiles = [[TilesBox alloc]
	initWithFrame: [[tilesImages contentView] frame]];
      [tiles setOwner: self];
      [tilesImages setContentView: tiles]; 
      RELEASE(tiles);

      /* Set the images in the popup and make a list mapping the titles
       * to the image names we will be using.
       */
      titles = [classInfo objectForKey: @"States"];
      if ([titles count] == 0)
	{
	  titles = [NSArray arrayWithObject: @"Normal"];
	}
      count = [titles count];
      md = [NSMutableDictionary dictionaryWithCapacity: count];
      for (i = 0; i < count; i++)
        {
	  NSString	*title = [titles objectAtIndex: i];

	  [tilesMenu insertItemWithTitle: title atIndex: i];
	  if ([title isEqualToString: @"Normal"] == YES)
	    {
	      [md setObject: className forKey: title];
	    }
	  else
	    {
	      [md setObject: [className stringByAppendingString: title]
		     forKey: title];
	    }
	}
      images = [md copy];
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

      [codeMenu removeAllItems];
      if ([fragments count] > 0)
	{
	  NSArray	*names = [fragments allKeys];

	  names = [names sortedArrayUsingSelector: @selector(compare:)];
	  [codeMenu addItemsWithTitles: names];
	  [self takeCodeMethod: codeMenu];
	}
      /* Take note of ending of editing.
       */
      [[NSNotificationCenter defaultCenter]
	addObserver: self
	selector: @selector(_endCodeEdit:)
	name: @"CodeEditDone"
	object: [CodeEditor codeEditor]];
    }
  return self;
}

- (void) selectAt: (NSPoint)mouse
{
  [super selectAt: mouse];
}

- (int) style
{
  return [[tilesStyle selectedItem] tag];
}

- (void) takeCodeDelete: (id)sender
{
  NSString	*method = [[codeMenu selectedItem] title];

  // FIXME ... need undo manager!
  [owner setCode: nil forKey: method];
}


- (void) takeCodeEdit: (id)sender
{
  NSString	*method = [[codeMenu selectedItem] title];
  NSString	*code = [owner codeForKey: method];

  if (code == nil)
    {
      NSString	*path;

      path = [method stringByReplacingString: @":" withString: @"_"];
      path = [[NSBundle mainBundle] pathForResource: path ofType: @"txt"];
      if (path == nil)
	{
	  NSRunAlertPanel(_(@"Problem editing method"),
	    _(@"No template found for method %@"),
	    nil, nil, nil, method);
	  return;
	}
      code = [NSString stringWithContentsOfFile: path];
    }
  [[CodeEditor codeEditor] editText: code control: className method: method];
}


- (void) takeCodeMethod: (id)sender
{
  NSString	*method = [[sender selectedItem] title];
  NSString	*helpText = [fragments objectForKey: method];

  if (helpText == nil) helpText = @"";
  [codeDescription setText: helpText];
  [codeDescription setEditable: NO];
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
