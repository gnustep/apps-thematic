/* ThemeElement.m
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
#import	"ThemeElement.h"

@implementation ThemeElement

- (void) dealloc
{
  RELEASE(inspector);
  [super dealloc];
}

- (void) deselect
{
  NSView	*v;

  v = [[[AppController sharedController] inspector] contentView];
  if (v == inspector)
    {
      [[[AppController sharedController] inspector] setContentView: nil];
      [window setContentView: v];
      [[window contentView] setNeedsDisplay: YES];
    }
}

- (NSString*) gormName
{
  return NSStringFromClass(isa);
}

- (id) initWithView: (NSView*)aView
	      owner: (ThemeDocument*)aDocument
{
  view = aView;
  owner = aDocument;
  [NSBundle loadNibNamed: [self gormName] owner: self];
  inspector = RETAIN([window contentView]);
  return self;
}

- (void) selectAt: (NSPoint)mouse
{
  NSWindow	*inspectorWindow;

  [window setContentView: nil];
  inspectorWindow = [[AppController sharedController] inspector];
  [inspectorWindow setContentView: inspector];
  [[window contentView] setNeedsDisplay: YES];
  [inspectorWindow setTitle: [NSString stringWithFormat: @"%@ Inspector",
    NSStringFromClass([view class])]];
  [inspectorWindow orderFront: self];
}

- (NSView*) view
{
  return view;
}
@end

