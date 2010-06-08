/* ColorElement.m
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
#import	"ColorElement.h"

@implementation ColorElement
- (void) selectAt: (NSPoint)mouse
{
  ThemeDocument	*doc;
  doc = [[AppController sharedController] selectedDocument];

  [colorWell setColor: [doc colorForKey: @"alternateRowBackgroundColor"]];

  [super selectAt: mouse];
}

- (void) takeColorFrom: (id)sender
{
  NSColor	*color = [(NSColorWell*)sender color];

  if (color != nil)
    {
      int		tag = [[colorMenu selectedItem] tag];
      NSString	*name = [self tagToName: tag];

      if (name != nil)
	{
	  [owner setColor: color forKey: name];
	}
    }
}

- (void) takeNameFrom: (id)sender
{
  int		tag = [[colorMenu selectedItem] tag];
  NSString	*name = [self tagToName: tag];
  NSColor	*color = [owner colorForKey: name];

  [colorWell setColor: color];
}

- (NSString*) tagToName: (int)tag
{
  NSString	*name = nil;

  switch (tag)
    {
      case  1: name = @"alternateRowBackgroundColor"; break;
      case  2: name = @"alternateSelectedControlColor"; break;
      case  3: name = @"alternateSelectedControlTextColor"; break;
      case  4: name = @"controlBackgroundColor"; break;
      case  5: name = @"controlColor"; break;
      case  6: name = @"controlDarkShadowColor"; break;
      case  7: name = @"controlHighlightColor"; break;
      case  8: name = @"controlLightHighlightColor"; break;
      case  9: name = @"controlShadowColor"; break;
      case 10: name = @"controlTextColor"; break;
      case 11: name = @"disabledControlTextColor"; break;
      case 12: name = @"gridColor"; break;
      case 13: name = @"headerColor"; break;
      case 14: name = @"headerTextColor"; break;
      case 15: name = @"highlightColor"; break;
      case 16: name = @"nameboardFocusIndicatorColor"; break;
      case 17: name = @"knobColor"; break;
      case 18: name = @"rowBackgroundColor"; break;
      case 19: name = @"scrollBarColor"; break;
      case 20: name = @"secondarySelectedControlColor"; break;
      case 21: name = @"selectedControlColor"; break;
      case 22: name = @"selectedControlTextColor"; break;
      case 23: name = @"selectedKnobColor"; break;
      case 24: name = @"selectedMenuItemColor"; break;
      case 25: name = @"selectedMenuItemTextColor"; break;
      case 26: name = @"selectedTextBackgroundColor"; break;
      case 27: name = @"selectedTextColor"; break;
      case 28: name = @"shadowColor"; break;
      case 29: name = @"textBackgroundColor"; break;
      case 30: name = @"textColor"; break;
      case 31: name = @"windowBackgroundColor"; break;
      case 32: name = @"windowFrameColor"; break;
      case 33: name = @"windowFrameTextColor"; break;
      default:
	  break;
    }
  return name;
}

- (NSString*) title
{
  return @"System Colors";
}
@end

