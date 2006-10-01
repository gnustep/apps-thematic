/* MiscElement.m
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
#import "ThemeDocument.h"
#import	"MiscElement.h"

@implementation MiscElement

- (void) selectAt: (NSPoint)mouse
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSDictionary	*info = [doc infoDictionary];
  NSArray	*arr;
  NSString	*str;

  arr = [info objectForKey: @"GSThemeAuthors"];
  if ([arr count] > 0)
    {
      [author setStringValue: [arr objectAtIndex: 0]];
    }
  str = [info objectForKey: @"GSThemeIcon"];
  if (str != nil)
    {
      [iconName setStringValue: str];
    }
  [iconView setImage: [[GSTheme theme] icon]];
  [super selectAt: mouse];
}

- (void) takeAuthor: (id)sender
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSString	*s = [sender stringValue];

  [doc setInfo: [NSArray arrayWithObject: s] forKey: @"GSThemeAuthors"];
  NSLog(@"takeAuthor: %@", s);
}

- (void) takeIcon: (id)sender
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
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
	  NSRunAlertPanel(_(@"Problem loading theme icon image"), 
	    message, nil, nil, nil);
	}
      NS_ENDHANDLER
      if (image != nil)
        {
	  [doc setResource: path forKey: @"GSThemeIcon"];
	  [iconView setImage: image];
	  [iconName setStringValue: [path lastPathComponent]];
	  RELEASE(image);
	}
    }
}

@end

