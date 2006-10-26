/* TiledElement.h
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

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>
#import "ThemeElement.h"

@class	NSDictionary;
@class	TilesBox;

@interface TiledElement : ThemeElement
{
  NSDictionary	*images;
  TilesBox	*tiles;
  id		popup;
  id		imageBox;
  id    	hSlider;
  id    	vSlider;
  id		style;
}
- (NSString*) imageName;
/**
 * Set the image names (and short descriptive strings as keys) for the
 * images used to tile this element in different states.  The popup will
 * be set to use the descriptive strings as lables.
 */
- (id) initWithView: (NSView*)aView
              owner: (ThemeDocument*)aDocument
	     images: (NSDictionary*)imageInfo;
- (int) style;
- (void) takeImage: (id)sender;
- (void) takePosition: (id)sender;
- (void) takeSelection: (id)sender;
- (void) takeStyle: (id)sender;
@end

