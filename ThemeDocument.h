/* ThemeDocument.h
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

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class	GSTheme;
@class	NSColor;
@class	NSColorList;
@class	NSDictionary;
@class	NSNotification;
@class	NSString;
@class	NSView;
@class	NSWindow;
@class	ThemeDocumentView;
@class	ThemeElement;

/**
 * <p>This works in conjunction with a window and the inspector panel to
 * manage loading, saving, and editing of a theme document.<br />
 * A theme document is a bundle containing the theme resources and
 * (perhaps) a loadable binary ... when we support it.
 * </p>
 * <p>Basically, the idea of the user interface is that the document window
 * provides a few icons you can click on to raise an inspector for editing.
 * </p>
 * <list>
 *   <item>System colors</item>
 *   <item>System images</item>
 *   <item>Menu settings</item>
 *   <item>Window settings</item>
 * </list>
 * <p>Everything else in the document window is a GUI element (NSControl)
 * and clicking on one of the elements should select it and activate the
 * inspector for it, which should let you change any NSInterfaceStyle keys for
 * the element and let you set an image/images for tiling over the rectangle
 * to draw it.
 * </p>
 * <p>For more complex GUI elements, it should be possible to click inside
 * the selected element to select a subsidiary element within int, and provide
 * theme info for that (eg. the knob inside a scroller).
 * </p>
 * <p>Any action to change part of the theme configuration should be
 * immediately made visible by changing the running application to effectively
 * use the modified theme.
 * </p>
 */
@interface	ThemeDocument : NSObject
{
  id			window;		// Not retained
  id			colorsView;	// Not retained
  id			imagesView;	// Not retained
  id			menusView;	// Not retained
  id			windowsView;	// Not retained
  id			extraView;	// Not retained
  id			_inspector;	// Not retained
  ThemeElement		*_selected;	// Not retained
  NSMutableDictionary	*_info;
  NSMutableDictionary	*_defs;		// Not retained
  NSMutableArray	*_elements;
  NSColorList		*_colors;
  NSString		*_name;
  NSString		*_path;
  NSString		*_work;
  NSString		*_rsrc;
  GSTheme		*_theme;
}

/** Try to make the theme we are editing active for preview purposes.
 */
- (void) activate;
- (void) changeSelection: (NSView*)aView at: (NSPoint)mousePoint;
- (NSColor*) colorNamed: (NSString*)aName;
- (ThemeElement*) elementForView: (NSView*)aView;

/**
 * Returns the current info dictionary for the document.
 */
- (NSDictionary*) infoDictionary;

- (id) initWithPath: (NSString*)path;
- (void) notified: (NSNotification*)n;
- (BOOL) saveToPath: (NSString*)path;

- (void) saveDocument: (id)sender;
- (void) saveDocumentAs: (id)sender;
- (void) saveDocumentTo: (id)sender;

/**
 * Returns the current selection in the main theme window.
 */
- (ThemeElement*) selected;

/**
 * Informs the document that a change has been made to a
 * system color whose name is key.
 */
- (void) setColor: (NSColor*)color forKey: (NSString*)key;

/**
 * Informs the document that a change has been made to a user default
 * which should be associated with the theme.
 */
- (void) setDefault: (NSString*)value forKey: (NSString*)key;

/**
 * Informs the document that a change has been made to the image
 * whose name is key.  The value of path is the location of the
 * file containing the new image.
 */
- (void) setImage: (NSString*)path forKey: (NSString*)key;

/**
 * Informs the document that a change has been made to information
 * to be stored in Info-gnustep.plist.
 */
- (void) setInfo: (NSString*)value forKey: (NSString*)key;

/**
 * Set the path this document should be saved to, and change its window
 * title to match.
 */
- (void) setPath: (NSString*)path;

/**
 * Asks the document to import a resource from the specified path.
 * The name of the resource will be the last component of the path
 * unless that would cause an existing resource to be overwritten.
 * The name will be stored in the Info-gnustep.plist file using key.
 */
- (void) setResource: (NSString*)path forKey: (NSString*)key;

@end


