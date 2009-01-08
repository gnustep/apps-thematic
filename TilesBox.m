/* TilesBox.m
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
#import	"ControlElement.h"
#import "TilesBox.h"

@implementation	TilesBox

- (void) drawRect: (NSRect)rect
{
  GSDrawTiles	*t;
  NSColor	*b = [NSColor controlBackgroundColor];
  NSString	*n = [owner elementName];
  
  if (n == nil)
    {
      t = nil;
    }
  else
    {
      t = [[GSTheme theme] tilesNamed: [owner elementName]
			        state: [owner elementState]
			        cache: YES];
    }
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
  [owner takeTileImage: self];
}

- (void) setOwner: (id)o
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

