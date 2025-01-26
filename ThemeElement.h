/* ThemeElement.h
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

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>

@class	NSMutableArray;
@class	NSView;
@class	ThemeDocument;

@interface ThemeElement : NSObject
{
  id		window;
  NSView	*inspector;
  NSView	*view;	// Not retained
  ThemeDocument	*owner;	// Not retained
}
/** Deselect the current element
 */
- (void) deselect;

/** Return name for the Gorm file for this element
 */
- (NSString*) gormName;

- (id) initWithView: (NSView*)aView
	      owner: (ThemeDocument*)aDocument;

/** Handle mouse click to select inspector for the view.
 */
- (void) selectAt: (NSPoint)mouse;

/** Return the title for the inspector window.
 */
- (NSString*) title;

/** Return the view this element is handling
 */
- (NSView*) view;
@end

