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

- (void) deselect
{
  NSNotification	*n;

  n = [NSNotification notificationWithName: @"dummy"
				    object: authors
				  userInfo: nil];
  [self textDidEndEditing: n];
  n = [NSNotification notificationWithName: @"dummy"
				    object: details
				  userInfo: nil];
  [self textDidEndEditing: n];
  [super deselect];
}

- (void) selectAt: (NSPoint)mouse
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSDictionary	*info = [doc infoDictionary];
  NSArray	*arr;

  arr = [info objectForKey: @"GSThemeAuthors"];
  if ([arr count] > 0)
    {
      [authors setStringValue: [arr objectAtIndex: 0]];
    }
  arr = [info objectForKey: @"GSThemeDetails"];
  if ([arr count] > 0)
    {
      [details setStringValue: [arr objectAtIndex: 0]];
    }
  [iconView setImage: [[GSTheme theme] icon]];
  [themeName setFont: [NSFont boldSystemFontOfSize: 32]];
  [themeName setStringValue: [[doc name] stringByDeletingPathExtension]];
  [super selectAt: mouse];
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
	  RELEASE(image);
	}
    }
}

- (void) textDidEndEditing: (NSNotification*)aNotification
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSTextView *sender = [aNotification object];
  NSString	*s = [sender string];


//NSLog(@"End editing %@", aNotification);
  if (sender == details)
    {
      [doc setInfo: s forKey: @"GSThemeDetails"];
    }

  if (sender == authors)
    {
      NSMutableArray    *a;
      unsigned		count;

      a = [[s componentsSeparatedByString: @"\n"] mutableCopy];
      count = [a count];
      while (count-- > 0)
        {
          NSString    *line = [a objectAtIndex: count];

          if ([[line stringByTrimmingSpaces] length] == 0)
            {
              [a removeObjectAtIndex: count];
	    }
        }
      [doc setInfo: a forKey: @"GSThemeAuthors"];
      RELEASE(a);
    }
}
@end

