/* ColorElement.h
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

#import "ThemeElement.h"

@interface ColorElement : ThemeElement
{
  BOOL ignoreSelectAt;
}

/** Handle color setting from color well in inspector
 */
- (void) takeColorFrom: (id)sender;

- (NSColor *) colorForName: (NSString *)aName
                  isSystem: (BOOL)system
                     state: (GSThemeControlState)state;
- (void) setColor: (NSColor *)aColor
          forName: (NSString *)aName
         isSystem: (BOOL)system
            state: (GSThemeControlState)state;

- (NSInteger) tagForName: (NSString *)aName
                isSystem: (BOOL)system
                   state: (GSThemeControlState)state;
- (NSString *) nameForTag: (NSInteger)tag;
- (BOOL) tagIsSystem: (NSInteger)tag;
- (GSThemeControlState) themeControlStateForTag: (NSInteger)tag;

@end

