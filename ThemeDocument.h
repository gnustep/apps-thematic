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
#import <GNUstepGUI/GSTheme.h>

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
  NSPoint		_selectionPoint;
  NSMutableDictionary	*_info;
  NSMutableDictionary	*_defs;		// Not retained
  NSMutableDictionary	*_modified;
  NSMutableArray	*_elements;
  NSColorList		*_colors;
  NSColorList		*_extraColors[GSThemeSelectedState+1];
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

/** Returns the code fragment for the specified key, or nil if none is
 * available. Places the last modifiecation date of the code in *since
 * if it is not zero.
 */
- (NSString*) codeForKey: (NSString*)key since: (NSDate**)since;

- (NSColor*) colorForKey: (NSString*)aName;

/** Returns the specified default string if one has been set for this
 * theme, nil otherwise.
 */
- (NSString*) defaultForKey: (NSString*)key;

- (ThemeElement*) elementForView: (NSView*)aView;

- (NSColor*) extraColorForKey: (NSString*)aName;
/**
 * Returns the current info dictionary for the document.
 */
- (NSDictionary*) infoDictionary;

- (id) initWithPath: (NSString*)path;

- (NSString*) name;

/** Generates a new version number for the theme binary (and returns it).
 */
- (NSString*) newVersion;

- (void) notified: (NSNotification*)n;

/**
 * Return the path from which this theme was loaded or saved.
 */
- (NSString*) path;

/**
 * Save to specified path.
 */
- (BOOL) saveToPath: (NSString*)path;

- (void) saveDocument: (id)sender;
- (void) saveDocumentAs: (id)sender;
- (void) saveDocumentTo: (id)sender;

/**
 * Returns the current selection in the main theme window.
 */
- (ThemeElement*) selected;

/**
 * Copies the binary bundle into place after deleting any existing version.
 * If path is nil, this just deletes the existing binary bundle.
 */
- (void) setBinaryBundle: (NSString*)path;

/**
 * Informs the document that a change has been made to a
 * code fragment whose name is key.<br />
 * If the path is nil, this means that the code fragment
 * needs to be removed.
 */
- (void) setCode: (NSString*)path forKey: (NSString*)key;

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
 * Informs the document that a change has been made to a
 * extra color whose name is key.
 */
- (void) setExtraColor: (NSColor*)color forKey: (NSString*)key;

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
- (void) setInfo: (id)value forKey: (NSString*)key;

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

/**
 * Set the tiling image (from the image in the file at path) and
 * division points for the named tiles.
 */
- (void) setTiles: (NSString*)name
	 withPath: (NSString*)path
	hDivision: (int)h
	vDivision: (int)v;

/** Return the current testTheme being edited.
 */
- (GSTheme*) testTheme;

/**
 * Return the tiling image (if known) and the division points for the
 * named tiles.
 */
- (NSImage*) tiles: (NSString*)name
	 hDivision: (int*)h
	 vDivision: (int*)v;

@end


