/* ControlElement.h
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
 * Foundation, Inc., 31 Milk Street #960789 Boston, MA 02196 USA.
 */


#import <AppKit/AppKit.h>
#import "ThemeElement.h"

@class	TilesBox;

@interface ControlElement : ThemeElement
{
  NSDictionary	*images;
  TilesBox	*tiles;
  NSString	*className;
  NSString	*colorName;
  NSString	*tileName;
  NSDictionary	*classInfo;
  NSDictionary	*fragments;
  id codeDescription;
  id codeMenu;
  id colorsMenu;
  id colorsState;
  id colorsWell;
  id defsDescription;
  id defsMenu;
  id defsOption;
  id tilesHorizontal;
  id tilesImages;
  id tilesMenu;
  id tilesState;
  id tilesStyle;
  id tilesVertical;
  id tilesPreview;
}
- (NSString*) colorName;
- (NSString*) className;	// The name of the control class
- (NSString*) elementName;
- (GSThemeControlState) elementState;
- (NSString*) imageName;
- (int) style;
- (void) takeCodeDelete: (id)sender;
- (void) takeCodeEdit: (id)sender;
- (void) takeCodeMethod: (id)sender;
- (void) takeColorDelete: (id)sender;
- (void) takeColorName: (id)sender;
- (void) takeColorValue: (id)sender;
- (void) takeTileDelete: (id)sender;
- (void) takeDefsName: (id)sender;
- (void) takeDefsValue: (id)sender;
- (void) takeTileDelete: (id)sender;
- (void) takeTileImage: (id)sender;
- (void) takeTileName: (id)sender;
- (void) takeTilePosition: (id)sender;
- (void) takeTileStyle: (id)sender;
- (NSView*) tilesPreview;
@end
