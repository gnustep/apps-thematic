/* MenusElement.m
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
 * Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import	"AppController.h"
#import	"ThemeDocument.h"
#import	"MenusElement.h"

@implementation MenusElement

- (void) selectAt: (NSPoint)mouse
{
  ThemeDocument	*doc;
  NSString      *val;

  doc = [[AppController sharedController] selectedDocument];
  val = [doc defaultForKey: @"NSMenuInterfaceStyle"];
  if ([val isEqualToString: @"NSWindows95InterfaceStyle"] == YES)
    {
      [popup selectItemAtIndex: [popup indexOfItemWithTag: 2]];
    }
  else if ([val isEqualToString: @"NSMacintoshInterfaceStyle"] == YES)
    {
      [popup selectItemAtIndex: [popup indexOfItemWithTag: 1]];
    }
  else
    {
      [popup selectItemAtIndex: [popup indexOfItemWithTag: 0]];
    }
  [arrowButton setImage: [NSImage imageNamed: @"NSMenuArrow"]];

  if ([doc extraColorForKey: @"GSMenuBar"] != nil)
    {
      [barColorWell setColor: [doc extraColorForKey: @"GSMenuBar"]];
    }

  if ([doc extraColorForKey: @"GSMenuBarTitle"] != nil)
    {
      [barTitleColorWell setColor: [doc extraColorForKey: @"GSMenuBarTitle"]];
    }

  [super selectAt: mouse];
}

- (void) takeArrowImageFrom: (id)sender
{
  NSArray	*fileTypes = [NSImage imageFileTypes];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: nil
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
          [[[AppController sharedController] selectedDocument] setImage: path
	    forKey: @"common_3DArrowRight"];
	  RELEASE(image);
	}
    }
}

- (void) takeMenuStyleFrom: (id)sender
{
  ThemeDocument	*doc = [[AppController sharedController] selectedDocument];
  int		style = [[sender selectedItem] tag];

  switch (style)
    {
      case 2:
        [doc setDefault: @"NSWindows95InterfaceStyle"
		 forKey: @"NSMenuInterfaceStyle"];
	break;

      case 1:
        [doc setDefault: @"NSMacintoshInterfaceStyle"
		 forKey: @"NSMenuInterfaceStyle"];
	break;

      default:
        [doc setDefault: @"NSNextStepInterfaceStyle"
		 forKey: @"NSMenuInterfaceStyle"];
	break;
    }
}

- (void) takeBarColorFrom: (id)sender
{
  NSColor	*color = [(NSColorWell*)sender color];

  if (color != nil)
    {
      ThemeDocument	*doc = [[AppController sharedController] selectedDocument];
      [doc setExtraColor: color forKey: @"GSMenuBar"];
    }
}

- (void) takeBarTitleColorFrom: (id)sender
{
  NSColor	*color = [(NSColorWell*)sender color];

  if (color != nil)
    {
      ThemeDocument	*doc = [[AppController sharedController] selectedDocument];
      [doc setExtraColor: color forKey: @"GSMenuBarTitle"];
    }
}

- (NSString*) title
{
  return @"Menus";
}
@end

