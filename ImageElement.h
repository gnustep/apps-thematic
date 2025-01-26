/* ImageElement.h
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

@class	ImagesView;

@interface ImageElement : ThemeElement
{
  NSInteger             selectedTag;
  NSMutableArray        *texts;
  NSMutableArray        *views;
  ImagesView            *imagesView;
  ImagesView            *systemView;    // Tag -1
  NSTextView            *textView;      // Tag -2
  id		        scrollView;
  id		        description;
  id		        deleteButton;
  id		        importButton;
  id                    collectionMenu;
}
- (void) deleteImage: (id)sender;
- (void) importImage: (id)sender;
- (void) switchCollection: (id)sender;
@end

