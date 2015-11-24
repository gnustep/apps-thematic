/* ThemeDocument.m
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
#import <GNUstepGUI/GSTheme.h>
#import	<AppController.h>
#import	"ThemeDocument.h"
#import	"ThemeElement.h"
#import	"ControlElement.h"
#import	"ColorElement.h"
#import	"ImageElement.h"
#import	"MenuItemElement.h"
#import	"MenusElement.h"
#import	"MiscElement.h"
#import	"PreviewElement.h"
#import	"WindowsElement.h"

@interface	GSTheme (TestTheme)
@end

@implementation	GSTheme (TestTheme)
/*
 * Method to prevent the current theme being set from the defaults system
 * because we ant to set it directly from the current document.
 * However, if there are no documents, we do want to use the correc theme.
 */
+ (void) defaultsDidChange: (NSNotification*)n
{
  if ([[[AppController sharedController] documents] count] == 0)
    {
      NSUserDefaults	*defs;
      NSString		*name;

      defs = [NSUserDefaults standardUserDefaults];
      name = [defs stringForKey: @"GSTheme"];
      if ([name isEqual: [[GSTheme theme] name]] == NO)
	{
	  [GSTheme setTheme: [GSTheme loadThemeNamed: name]];
	}
    }
}
/*
 * Method to bypass NSBundle's caching of infoDictionary so that changes
 * to the theme will be reflected immediately.
 */
- (NSDictionary*) infoDictionary
{
  ThemeDocument	*doc = [thematicController selectedDocument];

  if ([doc testTheme] == self)
    {
      NSString	*path;

      path = [[self bundle] pathForResource: @"Info-gnustep" ofType: @"plist"];
      return [NSDictionary dictionaryWithContentsOfFile: path];
    }
  else
    {
      return [[self bundle] infoDictionary];
    }
}
@end


static NSMutableSet	*untitledName = nil;
static NSColorList	*systemColorList = nil;

@interface	ThemeDocumentView : NSView
{
  ThemeDocument	*owner;	// Not retained
}
- (void) setOwner: (ThemeDocument*)o;
@end



@implementation	ThemeDocumentView

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent
{
  return YES;	/* Ensure we get initial mouse down event.	*/
}

/*
 * Initialisation - register to receive DnD for colors and images.
 */
- (id) initWithFrame: (NSRect)aFrame
{
  self = [super initWithFrame: aFrame];
  if (self != nil)
    {
      [self registerForDraggedTypes: [NSArray arrayWithObjects:
	NSColorPboardType,
	NSFileContentsPboardType,
	NSFilenamesPboardType,
	nil]];
    }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

/*
 *	Dragging destination protocol implementation
 */
- (NSDragOperation) draggingEntered: (id<NSDraggingInfo>)sender
{
  return NSDragOperationCopy;;
}
- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}
- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  return YES;
}

- (void) helpRequested: (NSEvent*)theEvent
{
  NSPoint	loc = [theEvent locationInWindow];
  NSView	*hit = [super hitTest: loc];

  if (hit != nil)
    {
      while (hit != self)
        {
	  if ([[NSHelpManager sharedHelpManager]
	    showContextHelpForObject: hit
	    locationHint: loc] == YES)
	    {
	      return;	// Found/
	    }
	  hit = [hit superview];
        }
    }
  [super helpRequested: theEvent];
}


/*
 *	Intercepting events in the view and handling them
 */
- (NSView*) hitTest: (NSPoint)loc
{
  /*
   * Stop the subviews receiving events - we grab them all.
   */
  if ([super hitTest: loc] != nil)
    return self;
  return nil;
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSPoint	mousePoint = [theEvent locationInWindow];
  NSView	*view;

  view = [super hitTest: mousePoint];
  if (view == self)
    {
      view = nil;
    }
  /* Make sure we've found the proper control and not a subview of a 
   * control (like the contentView of an NSBox)
   * However, sometimes we want to make special cases like finding a
   * scroller in a scrollview.
   */
  while (view != nil && [view superview] != self)
    {
      if ([view isKindOfClass: [NSScroller class]]
	&& [[view superview] isKindOfClass: [NSScrollView class]])
	{
	  break;	// Handle scrollers separately from scrollview
	}
      view = [view superview];
    }

  if (view != nil)
    {
      mousePoint = [view convertPoint: mousePoint fromView: nil];
      [owner changeSelection: view at: mousePoint];
    }
}

- (void) setOwner: (ThemeDocument*)o
{
  owner = o;
}

@end


@implementation ThemeDocument

+ (void) initialize
{
  untitledName = [NSMutableSet new];
  systemColorList = RETAIN([NSColorList colorListNamed: @"System"]);
}

- (void) activate
{
  /* Tell the system that our theme is now active as the current theme.
   * If we are already active, we deactivate first so that the new
   * activation can take effect cleanly. If we are not the current
   * theme, we just need to set ourselves to be it.
   */
  if ([GSTheme theme] == _theme)
    {
      [_theme deactivate];
      [_theme activate];
    }
  else
    {
      [GSTheme setTheme: _theme];
    }

  [_selected selectAt: _selectionPoint];
}

- (NSDictionary*) applicationImageNames
{
  NSFileManager	        *mgr;
  NSString              *pathOfTI;
  NSString              *path1;
  NSEnumerator          *enumerator1;
  NSMutableDictionary   *images;

  /*
    We may have top-level images in ThemeImages. These are common images.
    We may have then subdirectories with bundle identifieres.
    We loop twice and scan only subdirectories.
    We want to avoid hidden subdirs (like those created by version control systems).
   */
  
  mgr = [NSFileManager defaultManager];
  pathOfTI = [_rsrc stringByAppendingPathComponent: @"ThemeImages"];
  enumerator1 = [[mgr directoryContentsAtPath: pathOfTI] objectEnumerator];
  images = [NSMutableDictionary dictionary];

  while ((path1 = [enumerator1 nextObject]) != nil)
    {
      BOOL isDir1;
      NSString  *fileOrDir1;


      fileOrDir1 = [pathOfTI stringByAppendingPathComponent:path1];
      if (![path1 hasPrefix:@"."])
        {
          if ([mgr fileExistsAtPath:fileOrDir1 isDirectory:&isDir1] && isDir1)
            {
              NSString              *path2;
              NSEnumerator          *enumerator2;
              NSMutableArray        *array;

              array = [NSMutableArray array];
              [images setObject: array forKey:path1];
              enumerator2 = [[mgr directoryContentsAtPath: fileOrDir1] objectEnumerator];
              while ((path2 = [enumerator2 nextObject]) != nil)
                {
                  BOOL isDir2;
                  NSString  *fileOrDir2;

                  fileOrDir2 = [fileOrDir1 stringByAppendingPathComponent:path2];        
                  if (![path2 hasPrefix:@"."])
                    {
                      if ([mgr fileExistsAtPath:fileOrDir2 isDirectory:&isDir2] && !isDir2)
                        {
                          [array addObject: path2];
                        }
                    }
                }
            }
          else
            {
              // Here we would have images in the root (common)      
            }
        }
    }
  return images;
}

- (NSString*) buildDirectory
{
  return _build;
}

- (void) changeSelection: (NSView*)aView at: (NSPoint)mousePoint
{
  ThemeElement	*e = [self elementForView: aView];
  AppController	*c = [AppController sharedController];

  /*
   * Make sure that this is the 'selected' document and that the theme it
   * is editing is active for preview purposes.
   */
  [c selectDocument: self];

  if (aView == nil)
    {
      [_selected deselect];
      _selected = nil;
      _selectionPoint = NSZeroPoint;
    }
  else
    {
      if (e != _selected)
        {
	  /* Change selected view.
	   */
	  [_selected deselect];
	  _selected = e;
	}
      /* Change selection point in view.
       */
      _selectionPoint = mousePoint;
      [e selectAt: _selectionPoint];

      [[c inspector] orderFront: self];
    }
}

- (void) close
{
  /* Remove our information from the inspector
   */
  [_selected deselect];
  _selected = nil;
  _selectionPoint = NSZeroPoint;

  /* Remove our temporary work area.
   */
  if (_work != nil)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];

      [mgr removeFileAtPath: _work handler: nil];
      DESTROY(_work);
    }

  /* Remove self from app controller
   */
  [self retain];
  [[AppController sharedController] removeDocument: self];
  if (_theme != nil)
    {
      if ([GSTheme theme] == _theme
	&& [[[AppController sharedController] documents] count] == 0)
	{
	  [GSTheme setTheme: nil];
	}
      DESTROY(_theme);
    }
  [self release];
}

- (NSString*) codeForKey: (NSString*)key since: (NSDate**)since
{
  NSFileManager	*mgr;
  NSString	*code = nil;
  NSString	*file;

  key = [key stringByReplacingString: @":" withString: @"_"];
  if (since != 0)
    {
      *since = [_modified objectForKey: key];
    }
  file = [_rsrc stringByAppendingPathComponent: @"ThemeCode"];
  file = [file stringByAppendingPathComponent: key];
  mgr = [NSFileManager defaultManager];
  if ([mgr isReadableFileAtPath: file] == YES)
    {
      code = [NSString stringWithContentsOfFile: file];
    }
  return code;
}

- (NSColor*) colorForKey: (NSString*)aName
{
  return [_colors colorWithKey: aName];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [self close];
  [window setDelegate: nil];
  RELEASE(_modified);
  RELEASE(_elements);
  RELEASE(_colors);
  RELEASE(_extraColors[GSThemeNormalState]);
  RELEASE(_extraColors[GSThemeHighlightedState]);
  RELEASE(_extraColors[GSThemeSelectedState]);
  if (_name != nil)
    {
      [untitledName removeObject: _name];
      RELEASE(_name);
    }
  RELEASE(_path);
  RELEASE(_work);
  RELEASE(_rsrc);
  RELEASE(_info);
  [super dealloc];
}

- (NSString*) defaultForKey: (NSString*)key
{
  return [_defs objectForKey: key];
}

- (ThemeElement*) elementForView: (NSView*)aView
{
  ThemeElement	*e;
  unsigned	i;

  if (aView == nil)
    {
      return nil;
    }

  /* Look through the existing elements and if we already have one for this
   * view, return it.
   */
  i = [_elements count];
  while (i-- > 0)
    {
      e = [_elements objectAtIndex: i];
      if (aView == [e view])
        {
	  return e;
	}
    }
  e = nil;
  
  if ([aView isKindOfClass: [NSImageView class]] == YES)
    {
      /* This should be one of the images at the top of the main panel ...
       * We allocate a specific element depending on which image it is.
       */
      if (aView == colorsView)
        {
	  e = [[ColorElement alloc] initWithView: aView owner: self];
	}
      else if (aView == imagesView)
        {
	  e = [[ImageElement alloc] initWithView: aView owner: self];
	}
      else if (aView == menusView)
        {
	  e = [[MenusElement alloc] initWithView: aView owner: self];
	}
      else if (aView == extraView)
        {
	  e = [[MiscElement alloc] initWithView: aView owner: self];
	}
      else if (aView == previewView)
        {
	  e = [[PreviewElement alloc] initWithView: aView owner: self];
	}
      else if (aView == windowsView)
        {
	  e = [[WindowsElement alloc] initWithView: aView owner: self];
	}
      else if (aView == menuItemView)
        {
	  e = [[MenuItemElement alloc] initWithView: aView owner: self];
	}
      else
        {
	  NSLog(@"Unknown image view found");
	}
    }
  else
    {
      /* Here we create an element for a specific class of control.
       */
      if ([aView isKindOfClass: [NSButton class]])
        {
	  /* We could have a subclass of ControlElement to handle button
	   * specific details, but as a button is a simple gui element
	   * we can get away with using the ControlElement class directly
	   */
	  e = [[ControlElement alloc] initWithView: aView
					     owner: self];
	}
      else if ([aView isKindOfClass: [NSScroller class]])
        {
	  /* Perhaps this is worth a subclass, but we just have a hack in
	   * the -selectAt: method to do all we need.
	   */
	  e = [[ControlElement alloc] initWithView: aView
					     owner: self];
	}
      else
	{
	  /* At this point we just assume that the ControlElement class is
	   * able to handle whatever class we actually have in a generic
 	   * manner using information from the Resources/CodeInfo.plist
	   * definitions.  If there's no data in there, we will raise an
	   * alert panel later.
	   */
	  e = [[ControlElement alloc] initWithView: aView
					     owner: self];
	}
    }

  if (e != nil)
    {
      [_elements addObject: e];
      RELEASE(e);
    }

  return e;
}

- (NSColor*) extraColorForKey: (NSString*)aName
{
  GSThemeControlState	state = GSThemeNormalState;

  if ([aName hasSuffix: @"Highlighted"] == YES)
    {
      state = GSThemeHighlightedState;
      aName = [aName substringToIndex: [aName length] - 11];
    }
  else if ([aName hasSuffix: @"Selected"] == YES)
    {
      state = GSThemeSelectedState;
      aName = [aName substringToIndex: [aName length] - 8];
    }
  return [_extraColors[state] colorWithKey: aName];
}

- (NSImage*) imageForKey: (NSString*)aKey
{
  NSImage       *image;
  NSString      *path;

  path = [_rsrc stringByAppendingPathComponent: @"ThemeImages"];
  path = [path stringByAppendingPathComponent: aKey];
  image = AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
  return image;
}

- (NSDictionary*) infoDictionary
{
  return AUTORELEASE([_info copy]);
}

- (id) init
{
  return [self initWithPath: nil];
}

- (id) initWithPath: (NSString*)path
{
  CREATE_AUTORELEASE_POOL(pool);
  NSFileManager		*mgr = [NSFileManager defaultManager];
  static int		sequence = 0;
  NSRect		frame;
  NSView		*old;
  NSEnumerator		*enumerator;
  ThemeDocumentView	*view;
  NSArray		*keys;
  NSString		*pi;
  NSString		*s;
  unsigned		i;
  BOOL			isDir;

  /* Timestamps of modified code fragments.
   */
  _modified = [NSMutableDictionary new];

  /*
   * Create a working directory for temporary storage.
   */
  pi = [NSString stringWithFormat: @"%d_%d_0",
    [[NSProcessInfo processInfo] processIdentifier], ++sequence];
  pi = [pi stringByAppendingPathExtension: @"theme"];

  _work = RETAIN([NSTemporaryDirectory() stringByAppendingPathComponent: pi]);
  if (path != nil)
    {
      if ([mgr copyPath: path toPath: _work handler: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to load theme into work area from %@"),
	    nil, nil, nil, path);
	  return nil;
	}
    }

  if ([mgr fileExistsAtPath: _work isDirectory: &isDir] == NO || isDir == NO)
    {
      if ([mgr createDirectoryAtPath: _work attributes: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to create working directory for theme"),
	    _(@"OK"), nil, nil);
	  DESTROY(self);
	  return nil;
	}
    }

  _build = RETAIN([_work stringByAppendingPathComponent: @"Build"]);
  if ([mgr fileExistsAtPath: _build isDirectory: &isDir] == YES)
    {
      if ([mgr removeFileAtPath: _build handler: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to remove old Build directory for theme"),
	    _(@"OK"), nil, nil);
	  DESTROY(self);
	  return nil;
	}
    }
  if ([mgr createDirectoryAtPath: _build attributes: nil] == NO)
    {
      NSRunAlertPanel(_(@"Alert"),
	_(@"Unable to create Build directory for theme"),
	_(@"OK"), nil, nil);
      DESTROY(self);
      return nil;
    }

  _rsrc = RETAIN([_work stringByAppendingPathComponent: @"Resources"]);
  if ([mgr fileExistsAtPath: _rsrc isDirectory: &isDir] == NO || isDir == NO)
    {
      if ([mgr createDirectoryAtPath: _rsrc attributes: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to create Resources directory for theme"),
	    _(@"OK"), nil, nil);
	  DESTROY(self);
	  return nil;
	}
    }

  s = [_rsrc stringByAppendingPathComponent: @"ThemeImages"];
  if ([mgr fileExistsAtPath: s isDirectory: &isDir] == NO || isDir == NO)
    {
      if ([mgr createDirectoryAtPath: s attributes: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to create working images subdirectory for theme"),
	    _(@"OK"), nil, nil);
	  DESTROY(self);
	  return nil;
	}
    }

  s = [_rsrc stringByAppendingPathComponent: @"ThemeCode"];
  if ([mgr fileExistsAtPath: s isDirectory: &isDir] == NO || isDir == NO)
    {
      if ([mgr createDirectoryAtPath: s attributes: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to create source code subdirectory for theme"),
	    _(@"OK"), nil, nil);
	  DESTROY(self);
	  return nil;
	}
    }

  s = [_rsrc stringByAppendingPathComponent: @"ThemeTiles"];
  if ([mgr fileExistsAtPath: s isDirectory: &isDir] == NO || isDir == NO)
    {
      if ([mgr createDirectoryAtPath: s attributes: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to create working tiles subdirectory for theme"),
	    _(@"OK"), nil, nil);
	  DESTROY(self);
	  return nil;
	}
    }

  _elements = [NSMutableArray new];
  if (path != nil)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*file;

      file = [path stringByAppendingPathComponent: @"Resources"];
      file = [file stringByAppendingPathComponent: @"ThemeColors.clr"];
      if ([mgr isReadableFileAtPath: file] == YES)
	{
	  _colors = [[NSColorList alloc] initWithName: @"System"
					     fromFile: file];
	}

      file = [path stringByAppendingPathComponent: @"Resources"];
      file = [file stringByAppendingPathComponent: @"ThemeExtraColors.clr"];
      if ([mgr isReadableFileAtPath: file] == YES)
	{
	  _extraColors[GSThemeNormalState]
	    = [[NSColorList alloc] initWithName: @"ThemeExtra"
				       fromFile: file];
	}
      
      file = [path stringByAppendingPathComponent: @"Resources"];
      file = [file stringByAppendingPathComponent:
	@"ThemeExtraHighlightedColors.clr"];
      if ([mgr isReadableFileAtPath: file] == YES)
	{
	  _extraColors[GSThemeHighlightedState]
	    = [[NSColorList alloc] initWithName: @"ThemeExtraHighlighted"
				       fromFile: file];
	}
      
      file = [path stringByAppendingPathComponent: @"Resources"];
      file = [file stringByAppendingPathComponent:
	@"ThemeExtraSelectedColors.clr"];
      if ([mgr isReadableFileAtPath: file] == YES)
	{
	  _extraColors[GSThemeSelectedState]
	    = [[NSColorList alloc] initWithName: @"ThemeExtraSelected"
				       fromFile: file];
	}
      
      file = [path stringByAppendingPathComponent: @"Resources"];
      file = [file stringByAppendingPathComponent: @"Info-gnustep.plist"];
      if ([mgr isReadableFileAtPath: file] == YES)
	{
	  _info = [[NSMutableDictionary alloc] initWithContentsOfFile: file];
	}
    }

  if (_colors == nil)
    {
      _colors = [[NSColorList alloc] initWithName: @"System"
					 fromFile: nil];
    }
  if (_extraColors[GSThemeNormalState] == nil)
    {
      _extraColors[GSThemeNormalState]
	= [[NSColorList alloc] initWithName: @"ThemeExtra"
				   fromFile: nil];
    }
  if (_extraColors[GSThemeHighlightedState] == nil)
    {
      _extraColors[GSThemeHighlightedState]
	= [[NSColorList alloc] initWithName: @"ThemeExtraHighlighted"
				   fromFile: nil];
    }
  if (_extraColors[GSThemeSelectedState] == nil)
    {
      _extraColors[GSThemeSelectedState]
	= [[NSColorList alloc] initWithName: @"ThemeExtraSelected"
				   fromFile: nil];
    }
  if (_info == nil)
    {
      _info = [NSMutableDictionary new];
    }

  /*
   * Make sure the info plist contains a GSThemeDomain dictionary and
   * it is mutable so we can alter it.
   */
  _defs = [_info objectForKey: @"GSThemeDomain"];
  if (_defs == nil)
    {
      _defs = [NSDictionary dictionary];
    }
  _defs = [_defs mutableCopy];
  [_info setObject: _defs forKey: @"GSThemeDomain"];
  RELEASE(_defs);

  /* Ensure that the loaded color list has the full set of system colors.
   */
  keys = [systemColorList allKeys];
  for (i = 0; i < [keys count]; i++)
    {
      NSString	*key = [keys objectAtIndex: i];

      if ([_colors colorWithKey: key] == nil)
        {
	  [_colors setColor: [systemColorList colorWithKey: key] forKey: key];
        }
    }
  /* Store in working directory.
   */
  [_colors writeToFile:
    [_rsrc stringByAppendingPathComponent: @"ThemeColors.clr"]];
  [_extraColors[GSThemeNormalState] writeToFile:
    [_rsrc stringByAppendingPathComponent: @"ThemeExtraColors.clr"]];
  [_extraColors[GSThemeHighlightedState] writeToFile:
    [_rsrc stringByAppendingPathComponent: @"ThemeExtraHighlightedColors.clr"]];
  [_extraColors[GSThemeSelectedState] writeToFile:
    [_rsrc stringByAppendingPathComponent: @"ThemeExtraSelectedColors.clr"]];
  [_info writeToFile: [_rsrc stringByAppendingPathComponent:
    @"Info-gnustep.plist"] atomically: NO];

  /* If there is no icon for the theme, set a default one.
   */
  if ([_info objectForKey: @"GSThemeIcon"] == nil)
    {
      NSString	*s;
      
      s = [[NSBundle mainBundle] pathForResource: @"Thematic" ofType: @"png"];
      [self setResource: s forKey: @"GSThemeIcon"];
      [window setDocumentEdited: NO];
    }

  _theme = [[GSTheme alloc] initWithBundle: [NSBundle bundleWithPath: _work]];
  [_theme setName: [[self name] stringByDeletingPathExtension]];

  [NSBundle loadNibNamed: @"ThemeDocument" owner: self];
  [window setFrameUsingName: @"Document"];
  [window setFrameAutosaveName: @"Document"];
  [[NSNotificationCenter defaultCenter] addObserver: self
					   selector: @selector(notified:)
					       name: nil
					     object: window];
  [window setDelegate: self];

  /* Move all the subviews from the Gorm file content view to our
   * document view, and replace the original content view with it.
   */
  frame = [[window contentView] frame];
  frame.origin = NSZeroPoint;
  view = [[ThemeDocumentView alloc] initWithFrame: frame];
  [view setOwner: self];
  enumerator = [[[window contentView] subviews] objectEnumerator];
  while ((old = [enumerator nextObject]) != nil)
    {
      [view addSubview: old];
    }
  [window setContentView: view];
  RELEASE(view);

  [self setPath: path];

{
  NSAttributedString *s;

  s = [[NSAttributedString alloc] initWithString: @"This raises the theme images inspector, which displays all the images used in drawing standard GUI elements (excluding images used for tiling), double-clicking any image will oproduce an open panel, allowing you to specify a replacement image to be used by your theme."];
  [[NSHelpManager sharedHelpManager] setContextHelp: s forObject: imagesView];
  RELEASE(s);

}
  [colorsView setToolTip: _(@"system colors")];
  [imagesView setToolTip: _(@"system images")];
  [menusView setToolTip: _(@"menu settings")];
  [windowsView setToolTip: _(@"window settings")];
  [extraView setToolTip: _(@"general information")];
  [previewView setToolTip: _(@"preview image")];

  [window makeKeyAndOrderFront: self];

  /* Here we can perform any extra setup needed for the different views
   */
  enumerator = [[view subviews] objectEnumerator];
  while ((old = [enumerator nextObject]) != nil)
    {
      if ([old isKindOfClass: [NSScrollView class]])
	{
	  NSEnumerator	*e = [[old subviews] objectEnumerator];
	  NSScrollView	*sv = (NSScrollView*)old;
	  NSTextView	*tv = [sv documentView];
	  NSSize	sz = [[sv contentView] bounds].size;

	  /* This next horrible code is to ensure that the document inside
	   * the scroll view is big enough so that the scrollers display.
	   */
	  sz.width *= 5;
	  sz.height *= 5;
	  [tv setHorizontallyResizable: NO];
	  [tv setVerticallyResizable: NO];
	  [tv setFrameSize: sz];
	  [sv setAutohidesScrollers: NO];
	  [sv setHasHorizontalScroller: YES];
	  [sv setHasVerticalScroller: YES];
	  
	  while ((old = [e nextObject]) != nil)
	    {
              if ([old isKindOfClass: [NSScroller class]])
		{
	  	  [(NSScroller*)old setEnabled: YES];
		}
	    }
	}
      else if ([old isKindOfClass: [NSScroller class]])
        {
	  [(NSScroller*)old setEnabled: YES];
	}
    }
  RELEASE(pool);
  return self;
}

- (NSString*) name
{
  return _name;
}

- (void) notified: (NSNotification*)n
{
  NSString	*name = [n name];

  if ([name isEqualToString: NSWindowDidBecomeMainNotification]
    || [name isEqualToString: NSWindowDidBecomeKeyNotification])
    {
      [[AppController sharedController] selectDocument: self];
    }
  else if ([name isEqualToString: NSWindowWillCloseNotification])
    {
      [self close];
    }
  // NSLog(@"Received %@ from %@", name, [n object]);
}

- (NSString*) path
{
  return _path;
}

- (void) saveDocument: (id)sender
{
  /* Make the document window the key windoe so that any unsaved changes in
   * the inspector are saved too.
   */
  [window makeKeyWindow];

  if ([window isDocumentEdited] == YES)
    {
      if (_path == nil)
	{
	  [self saveDocumentAs: (id)sender];
	}
      else
        {
	  [self saveToPath: _path];
	  [window setDocumentEdited: NO];
	}
    }
}

- (NSString*) saveDirectory
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  BOOL		isDir;
  NSString	*base;

  base = [NSSearchPathForDirectoriesInDomains
    (NSAllLibrariesDirectory, NSUserDomainMask, YES) lastObject];
  if (base != nil)
    {
      base = [base stringByAppendingPathComponent: @"Themes"];
      if ([mgr fileExistsAtPath: base isDirectory: &isDir] == NO
	|| isDir == NO)
	{
	  int	ret;

	  ret = NSRunAlertPanel(_(@"Warning"),
	    _(@"Your personal theme directory (%@) does not exist"),
	    _(@"Create it"), _(@"Ignore"), nil, base);
	  if (ret == 1)
	    {
	      if ([mgr createDirectoryAtPath: base attributes: nil] == NO)
		{
		  NSRunAlertPanel(_(@"Alert"),
		    _(@"Unable to create directory at %@"),
		    _(@"OK"), nil, nil, base);
		  base = nil;
		}
	    }
	  else
	    {
	      base = nil;
	    }
	}
    }
  if (base == nil)
    {
      base = NSHomeDirectory();
    }
  return base;
}

- (void) saveDocumentAs: (id)sender
{
  NSSavePanel	*sp;
  int		result;

  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: @"theme"];
  [sp setTitle: _(@"Save theme as...")];
  result = [sp runModalForDirectory: [self saveDirectory] file: [self name]];
  if (result == NSOKButton)
    {
      [self setPath: [sp filename]];
      [self saveToPath: _path];
      [window setDocumentEdited: NO];
    }
}

- (void) saveDocumentTo: (id)sender
{
  NSSavePanel		*sp;
  int			result;

  sp = [NSSavePanel savePanel];
  [sp setRequiredFileType: @"theme"];
  [sp setTitle: _(@"Save theme to...")];
  result = [sp runModalForDirectory: [self saveDirectory] file: [self name]];
  if (result == NSOKButton)
    {
      NSString *path = [sp filename];

      [self saveToPath: path];
    }
}

- (BOOL) saveToPath: (NSString*)path
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSString	*backup;
  const char	*name;
  BOOL		isDirectory;

  name = [[[path lastPathComponent] stringByDeletingPathExtension] UTF8String];
  while (name && *name)
    {
      if (!isalnum(*name))
	{
          NSRunAlertPanel(_(@"Problem saving document"),
	    _(@"Only alphanumeric characters are permitted in the name"),
	    nil, nil, nil);
	}
      name++;
    }
  if ([_info writeToFile: [_rsrc stringByAppendingPathComponent:
    @"Info-gnustep.plist"] atomically: NO] == NO)
    {
      NSRunAlertPanel(_(@"Problem updating version"),
	_(@"Could not save Info-gnustep.plist into theme"),
	nil, nil, nil);
    }
  backup = [path stringByDeletingPathExtension];
  backup = [backup stringByAppendingPathExtension: @"backup"];
  backup = [backup stringByAppendingPathExtension: @"theme"];
  if ([mgr fileExistsAtPath: path isDirectory: &isDirectory] == YES)
    {
      if (isDirectory == NO)
        {
	  NSRunAlertPanel(_(@"Problem saving theme"),
	    _(@"A file already exists at %@"),
	    nil, nil, nil, path);
	  return NO;
	}
      
      if ([mgr fileExistsAtPath: backup] == YES)
        {
	  if ([mgr removeFileAtPath: backup handler: nil] == NO)
	    {
	      NSRunAlertPanel(_(@"Problem saving theme"),
		_(@"Unable to remove old backup at %@"),
		nil, nil, nil, backup);
	      return NO;
	    }
	}
      if ([mgr movePath: path toPath: backup handler: nil] == NO)
        {
	  NSRunAlertPanel(_(@"Problem saving theme"),
	    _(@"Unable to move backup theme to %@"),
	    nil, nil, nil, backup);
	  return NO;
	}
    }

  if ([mgr copyPath: _work toPath: path handler: nil] == NO)
    {
      NSRunAlertPanel(_(@"Problem saving theme"),
	_(@"Unable to copy work area to %@"),
	nil, nil, nil, path);
      return NO;
    }
  /* Don't want a copy of the build directory in the saved theme.
   */
  [mgr removeFileAtPath: [path stringByAppendingPathComponent: @"Build"]
		handler: nil];
  return YES;
}

- (ThemeElement*) selected
{
  return _selected;
}

- (void) setBinaryBundle: (NSString*)path
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSString	*file;
  BOOL		existed;
  NSString	*className = nil;

  file = [_work stringByAppendingPathComponent: @"Theme.bundle"];
  existed = [mgr fileExistsAtPath: file];
  /*
   * Remove any old file of the same name.
   */
  [mgr removeFileAtPath: file handler: nil];

  /* Now copy executable bundle into theme bundle if necessary,
   * and update theme bundle Info-gnustep.plist to reflect the
   * current theme executable.
   */
  if (path != nil)
    {
      if ([mgr copyPath: path toPath: file handler: nil] == NO)
	{
	  [_info removeObjectForKey: @"NSExecutable"];
	  [_info removeObjectForKey: @"NSPrincipalClass"];
	  NSRunAlertPanel(_(@"Problem copying binary"),
	    _(@"Could not copy file into theme"),
	    nil, nil, nil);
	}
      else
	{
	  NSBundle	*b = [NSBundle bundleWithPath: path];
	  NSDictionary	*i = [b infoDictionary];
	  NSString	*e = [i objectForKey: @"NSExecutable"];

	  /* Adjust our info dictionary to contain the location of the
	   * executable and the name of the principal class in the
	   * binary bundle.
	   */
	  e = [@"Theme.bundle" stringByAppendingPathComponent: e];
	  [_info setObject: e forKey: @"NSExecutable"];
	  className = [i objectForKey: @"NSPrincipalClass"];
	  [_info setObject: className forKey: @"NSPrincipalClass"];
	}
    }
  else if (existed == YES)
    {
      [_info removeObjectForKey: @"NSExecutable"];
      [_info removeObjectForKey: @"NSPrincipalClass"];
    }
  if ([_info writeToFile: [_rsrc stringByAppendingPathComponent:
    @"Info-gnustep.plist"] atomically: NO] == NO)
    {
      NSRunAlertPanel(_(@"Problem changing executable and principal class"),
	_(@"Could not save Info-gnustep.plist into theme"),
	nil, nil, nil);
    }

  [window setDocumentEdited: YES];

  /*
   * Ensure that the correct theme code is in use before activating.
   * That might mean we need to copy the working theme to another
   * directory so that NSBundle will load it rather than returning
   * a bundle already loaded.
   */
  if (className == nil)
    {
      className = NSStringFromClass([GSTheme class]);
    }
  if ([NSStringFromClass([_theme class]) isEqual: className] == NO)
    {
      NSString	*version = [_info objectForKey: @"GSThemeVersion"];
      NSString	*tmp;
      NSRange	r;

      tmp = _work;
      r = [tmp rangeOfString: @"_" options: NSBackwardsSearch];
      tmp = [tmp substringToIndex: NSMaxRange(r)];
      tmp = [tmp stringByAppendingString: version];
      tmp = [tmp stringByAppendingPathExtension: @"theme"];
      if ([mgr movePath: _work toPath: tmp handler: nil] == YES)
	{
	  NSBundle	*bundle;
	  Class		c;

          ASSIGN(_work, tmp);
          ASSIGN(_build, [_work stringByAppendingPathComponent: @"Build"]);
          ASSIGN(_rsrc, [_work stringByAppendingPathComponent: @"Resources"]);

          bundle = [NSBundle bundleWithPath: _work];
	  c = [bundle principalClass];
	  if (c == 0)
	    {
	      c = [GSTheme class];
	    }
          [_theme release];
          _theme = [[c alloc] initWithBundle: bundle];
          [_theme setName: [[self name] stringByDeletingPathExtension]];
	}
      else
	{
	  NSRunAlertPanel(_(@"Problem updating theme binary"),
	    _(@"Could not move theme file"),
	    nil, nil, nil);
	}
    }
  [self activate];
}

- (void) setCode: (NSString*)code forKey: (NSString*)key
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSString	*file;

  key = [key stringByReplacingString: @":" withString: @"_"];
  [_modified setObject: [NSDate date] forKey: key];
  file = [_rsrc stringByAppendingPathComponent: @"ThemeCode"];
  file = [file stringByAppendingPathComponent: key];

  /*
   * Remove any old file of the same name.
   */
  [mgr removeFileAtPath: file handler: nil];

  if (code != nil && [code writeToFile: file atomically: NO] == NO)
    {
      NSRunAlertPanel(_(@"Problem saving code"),
	_(@"Could not write file into theme"),
	nil, nil, nil);
    }
  else
    {
      [window setDocumentEdited: YES];
      [self activate];			// FIXME ... compile-load-preview
    }
}

- (void) setColor: (NSColor*)color forKey: (NSString*)key
{
  if (color == nil)
    {
      /* Remove old color  and revert to the one from the original system list.
       */
      [_colors removeColorWithKey: key];
      color = [systemColorList colorWithKey: key];
    }
  [_colors setColor: color forKey: key];
  if ([_colors writeToFile:
    [_rsrc stringByAppendingPathComponent: @"ThemeColors.clr"]] == NO)
    {
      NSRunAlertPanel(_(@"Problem changing color"),
	_(@"Could not save colors into theme"),
	nil, nil, nil);
    }
  else
    {
      [window setDocumentEdited: YES];
      [self activate];			// Preview
    }
}

- (void) setDefault: (NSString*)value forKey: (NSString*)key
{
  NSString	*old = [_defs objectForKey: key];
  BOOL		changed = NO;

  if (value == nil)
    {
      if (old != nil)
	{
          [_defs removeObjectForKey: key];
	  changed = YES;
	}
    }
  else if ([value isEqual: old] == NO)
    {
      [_defs setObject: value forKey: key];
      changed = YES;
    }
  if (changed == YES)
    {
      if ([_info writeToFile: [_rsrc stringByAppendingPathComponent:
	@"Info-gnustep.plist"] atomically: NO] == NO)
	{
	  NSRunAlertPanel(_(@"Problem changing setting"),
	    _(@"Could not save Info-gnustep.plist into theme"),
	    nil, nil, nil);
	}
      else
	{
	  [window setDocumentEdited: YES];
	  [self activate];			// Preview
	}
    }
}

- (void) setExtraColor: (NSColor*)color forKey: (NSString*)key
{
  GSThemeControlState	state = GSThemeNormalState;
  NSString		*file = @"ThemeExtraColors.clr";
  NSColorList		*list;

  if ([key hasSuffix: @"Highlighted"] == YES)
    {
      state = GSThemeHighlightedState;
      file = @"ThemeExtraHighlightedColors.clr";
      key = [key substringToIndex: [key length] - 11];
    }
  else if ([key hasSuffix: @"Selected"] == YES)
    {
      state = GSThemeSelectedState;
      file = @"ThemeExtraSelectedColors.clr";
      key = [key substringToIndex: [key length] - 8];
    }
  list = _extraColors[state];

  if (color == nil)
    {
      [list removeColorWithKey: key];
    }
  else
    {
      [list setColor: color forKey: key];
    }
  if ([_extraColors[state] writeToFile:
    [_rsrc stringByAppendingPathComponent: file]] == NO)
    {
      NSRunAlertPanel(_(@"Problem changing extra color"),
	_(@"Could not save extra colors into theme"),
	nil, nil, nil);
    }
  else
    {
      [window setDocumentEdited: YES];
      [self activate];			// Preview
    }
}

- (void) setImage: (NSString*)path forKey: (NSString*)key
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSArray	*fileTypes;
  unsigned	count;
  NSString	*file;
  NSString	*ext;

  if (path != nil && [mgr isReadableFileAtPath: path] == NO)
    {
      NSRunAlertPanel(_(@"Problem loading image"),
	_(@"Could not read file to copy into theme"),
	nil, nil, nil);
      return;
    }

  file = [_rsrc stringByAppendingPathComponent: @"ThemeImages"];
  file = [file stringByAppendingPathComponent: key];

  /* If the key contains a bundle identifier subdirectory,
   * make sure that the subdirectory exists (or delete it
   * if this is only the bundle identifier and the path is nil).
   */
  if ([key rangeOfString: @"/"].length > 0)
    {
      if ([key hasSuffix: @"/"] && nil == path)
        {
          [mgr removeFileAtPath: path handler: nil];
        }
      else
        {
          NSString  *sub = [file stringByDeletingLastPathComponent];

          [mgr createDirectoryAtPath: sub
         withIntermediateDirectories: YES
                          attributes: nil
                               error: 0];
        }
    }

  /*
   * Remove any old image of the same name.
   */
  fileTypes = [NSImage imageFileTypes];
  count = [fileTypes count];
  while (count-- > 0)
    {
      NSString	*ext = [fileTypes objectAtIndex: count];

      [mgr removeFileAtPath: [file stringByAppendingPathExtension: ext]
		    handler: nil];
    }

  if (path != nil)
    {
      ext = [path pathExtension];
      file = [file stringByAppendingPathExtension: ext];
      if ([mgr copyPath: path toPath: file handler: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Problem loading image"),
	    _(@"Could not copy file into theme"),
	    nil, nil, nil);
	  return;
	}
    }

  [window setDocumentEdited: YES];
  [self activate];			// Preview
}

- (void) setInfo: (id)value forKey: (NSString*)key
{
  id	old = [_info objectForKey: key];
  BOOL	changed = NO;

  if (value == nil)
    {
      if (old != nil)
	{
          [_info removeObjectForKey: key];
	  changed = YES;
	}
    }
  else
    {
      if ([old isEqual: value] == NO)
	{
          [_info setObject: value forKey: key];
	  changed = YES;
	}
    }

  if (changed == YES)
    {
      if ([_info writeToFile: [_rsrc stringByAppendingPathComponent:
	@"Info-gnustep.plist"] atomically: NO] == NO)
	{
	  NSRunAlertPanel(_(@"Problem changing setting"),
	    _(@"Could not save Info-gnustep.plist into theme"),
	    nil, nil, nil);
	}
      else
	{
	  [window setDocumentEdited: YES];
	  [self activate];			// Preview
	}
    }
}

- (BOOL) windowShouldClose: (id)sender
{
  if ([window isDocumentEdited])
    {
      int ret;

      /* Deselect so that inspector window is cleareed and any editing in it
       * is completed.
       */
      [_selected deselect];
      _selected = nil;
      _selectionPoint = NSZeroPoint;

      [window makeKeyAndOrderFront: self];

      ret = NSRunAlertPanel(_(@"Close Theme"),
	_(@"Theme %@ has been modified"),
	_(@"Save and Close"), _(@"Don't save"), _(@"Cancel"), 
	[self name]);

      if (ret == 1)
	{
	  [self saveDocument: self];
	  if ([window isDocumentEdited])
	    {
	      NSRunAlertPanel(_(@"Alert"),
		_(@"Error when saving theme '%@'!"),
		_(@"OK"), nil, nil, [self name]);
	      return NO;
	    }
	  else
	    {
	      return YES;
	    }
	}
      else if (ret == 0) // Close but don't save
	{
	  return YES;
	}
      else               // Cancel closing
	{
	  return NO;
	}
    }
  return YES;
}

- (void) setPath: (NSString*)path
{
  if ([path isEqual: _path] == YES)
    {
      return;
    }
  if ([path length] > 0)
    {
      ASSIGN(_path, path);
      ASSIGN(_name, [path lastPathComponent]);
    }
  else if (_name == nil)
    {
      int	i = 0;
      NSString	*trial;

      do
        {
	  trial = [NSString stringWithFormat: @"Untitled%d.theme", ++i];
	}
      while ([untitledName member: trial] != nil);
      [untitledName addObject: trial];
      ASSIGN(_name, trial);
     /* New document ... start with zero version number.
      */
     [_info setObject: @"0.0" forKey: @"GSThemeVersion"];
    }
  [window setTitle: [self name]];
  [_theme setName: [[self name] stringByDeletingPathExtension]];
}

- (void) setResource: (NSString*)path forKey: (NSString*)key
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSString	*name;
  NSString	*file;
  
  name = [_info objectForKey: key];
  if (name != nil)
    {
      file = [_rsrc stringByAppendingPathComponent: name];
      [mgr removeFileAtPath: file handler: nil];
      [_info removeObjectForKey: key];
    }

  if (path != nil)
    {
      int	count = 0;

      name = [path lastPathComponent];
      file = [_rsrc stringByAppendingPathComponent: name];
      while ([mgr fileExistsAtPath: file] == YES)
        {
	  NSString	*tmp = [name stringByDeletingPathExtension];

	  tmp = [NSString stringWithFormat: @"%@%d", tmp, ++count];
	  tmp = [tmp stringByAppendingPathExtension: [name pathExtension]];
	  file = [_rsrc stringByAppendingPathComponent: tmp];
	}
      name = [file lastPathComponent];
      if ([mgr copyPath: path toPath: file handler: nil] == NO)
        {
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Error copying '%@' into work area!"),
	    _(@"OK"), nil, nil, [self name]);
	}
      else
        {
	  [_info setObject: name forKey: key];
	}
    }
  if ([_info writeToFile: [_rsrc stringByAppendingPathComponent:
    @"Info-gnustep.plist"] atomically: NO] == NO)
    {
      NSRunAlertPanel(_(@"Problem changing setting"),
	_(@"Could not save Info-gnustep.plist into theme"),
	nil, nil, nil);
    }
  [window setDocumentEdited: YES];
  [self activate];			// Preview
}

/* NB.
 * If path is nil, we set the positions but leave the file unchanged.
 * If path is @"", we remove the file from the theme.
 */
- (void) setTiles: (NSString*)name
	 withPath: (NSString*)path
	fillStyle: (NSString*)fill
	hDivision: (int)h
	vDivision: (int)v
{
  NSAutoreleasePool	*arp = [NSAutoreleasePool new];
  NSFileManager	*mgr = [NSFileManager defaultManager];
  id		allTiles = [_info objectForKey: @"GSThemeTiles"];
  NSDictionary	*d;
  NSString	*fileName;

  if (allTiles == nil)
    {
      allTiles = [NSMutableDictionary new];
      [_info setObject: allTiles forKey: @"GSThemeTiles"];
      RELEASE(allTiles);
    }
  else if ([allTiles isKindOfClass: [NSMutableDictionary class]] == NO)
    {
      allTiles = [allTiles mutableCopy];
      [_info setObject: allTiles forKey: @"GSThemeTiles"];
      RELEASE(allTiles);
    }

  d = [allTiles objectForKey: name];
  if (d == nil && path == nil)
    {
      return;	// No existing information, so we need to copy a file
    }
  fileName = [d objectForKey: @"FileName"];

  if (path != nil && [fileName length] > 0)
    {
      NSString	*oPath;

      oPath = [_rsrc stringByAppendingPathComponent: @"ThemeTiles"];
      oPath = [oPath stringByAppendingPathComponent: fileName];
      [mgr removeFileAtPath: oPath handler: nil];
    }

  if ([path isEqual: @""])
    {
      [allTiles removeObjectForKey: name];
    }
  else
    {
      NSString	*fSet = [d objectForKey: @"FillStyle"];
      NSString	*hDiv = [d objectForKey: @"HorizontalDivision"];
      NSString	*vDiv = [d objectForKey: @"VerticalDivision"];

      if (path != nil)
	{
          NSString	*ext = [path pathExtension];
          NSString	*nPath;

	  fileName = [name stringByAppendingPathExtension: ext];
	  nPath = [_rsrc stringByAppendingPathComponent: @"ThemeTiles"];
	  nPath = [nPath stringByAppendingPathComponent: fileName];

	  if ([mgr copyPath: path toPath: nPath handler: nil] == NO)
	    {
	      NSRunAlertPanel(_(@"Alert"),
		_(@"Unable to load tile image into work area from %@"),
		nil, nil, nil, path);
	      return;
	    }
	}

      if (fill != nil)
	{
	  fSet = fill;
	}
      if (h > 0)
        {
	  hDiv = [NSString stringWithFormat: @"%d", h];
	}
      if (v > 0)
        {
	  vDiv = [NSString stringWithFormat: @"%d", v];
	}

      if (fSet == nil) fSet = @"ScaleAll";
      if (hDiv == nil) hDiv = @"";
      if (vDiv == nil) vDiv = @"";

      d = [NSDictionary dictionaryWithObjectsAndKeys:
        fileName, @"FileName",
        fSet, @"FillStyle",
	hDiv, @"HorizontalDivision",
	vDiv, @"VerticalDivision",
        nil];

      [allTiles setObject: d forKey: name];
    }

  if ([_info writeToFile: [_rsrc stringByAppendingPathComponent:
    @"Info-gnustep.plist"] atomically: NO] == NO)
    {
      NSRunAlertPanel(_(@"Problem changing setting"),
	_(@"Could not save Info-gnustep.plist into theme"),
	nil, nil, nil);
    }
  [window setDocumentEdited: YES];
  // Refresh cache for this tile array
  [_theme tilesFlush: name state: -1];
  [self activate];			// Preview
  [arp release];
}

- (GSTheme*) testTheme
{
  return _theme;
}

- (NSImage*) tiles: (NSString*)name
	 fillStyle: (NSString**)f
	 hDivision: (int*)h
	 vDivision: (int*)v
{
  NSDictionary	*td = [_info objectForKey: @"GSThemeTiles"];
  NSString	*fileName;
  NSImage	*image = nil;

  td = [td objectForKey: name];
  fileName = [td objectForKey: @"FileName"];
  if (fileName != nil)
    {
      NSString	*path;

      path = [_rsrc stringByAppendingPathComponent: @"ThemeTiles"];
      path = [path stringByAppendingPathComponent: fileName];
      image = AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
    }
  if (f != 0)
    {
      *f = [td objectForKey: @"FillStyle"];
    }
  if (h != 0)
    {
      *h = [[td objectForKey: @"HorizontalDivision"] intValue];
    }
  if (v != 0)
    {
      *v = [[td objectForKey: @"VerticalDivision"] intValue];
    }
  return image;
}

- (NSString*) versionIncrementMajor: (BOOL)major incrementMinor: (BOOL)minor
{
  NSString	*version;
  NSRange	r;
  int		maj;
  int		min;

  version = [_info objectForKey: @"GSThemeVersion"];
  if ([version length] == 0) version = @"0.0";
  maj = [version intValue];
  if (maj < 0) maj = 0;
  r = [version rangeOfString: @"."];
  if (r.length > 0) version = [version substringFromIndex: NSMaxRange(r)];
  else version = @"0";
  min = [version intValue];
  if (min < 0) min = 0;

  if (major == YES)
    {
      maj++;
      min = 0;
    }
  else if (minor == YES)
    {
      min++;
    }

  version = [NSString stringWithFormat: @"%d.%d", maj, min]; 
  [_info setObject: version forKey: @"GSThemeVersion"];
  if (maj || min)
    {
      if ([_info writeToFile: [_rsrc stringByAppendingPathComponent:
	@"Info-gnustep.plist"] atomically: NO] == NO)
	{
	  NSRunAlertPanel(_(@"Problem changing setting"),
	    _(@"Could not save Info-gnustep.plist into theme"),
	    nil, nil, nil);
	}
      else
	{
	  [window setDocumentEdited: YES];
	}
    }

  return version;
}

@end
