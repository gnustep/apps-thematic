/* WindowsElement.m
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
#import "ThemeDocument.h"
#import	"WindowsElement.h"

@implementation WindowsElement
- (void) selectAt: (NSPoint)mouse
{
  ThemeDocument	*doc;
  NSString      *val;

  doc = [[AppController sharedController] selectedDocument];
  val = [doc defaultForKey: @"GSBackHandlesWindowDecorations"];
  if ([val boolValue] == NO)
    {
      [popup selectItemAtIndex: [popup indexOfItemWithTag: 0]];
    }
  else
    {
      [popup selectItemAtIndex: [popup indexOfItemWithTag: 1]];
    }
  [super selectAt: mouse];
}

- (void) takeWindowStyleFrom: (id)sender
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  int		style = [[sender selectedItem] tag];

  switch (style)
    {
      case 1:
        [doc setDefault: @"NO"
		 forKey: @"GSBackHandlesWindowDecorations"];
	break;
      default:
        [doc setDefault: @"YES"
		 forKey: @"GSBackHandlesWindowDecorations"];
	break;
    }
}
@end

