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
#import	<ThemeDocument.h>
#import	<ThemeElement.h>
#import	<ControlElement.h>

@class	ColorElement;
@class	ImageElement;
@class	MenusElement;
@class	MiscElement;
@class	WindowsElement;

@interface	TestTheme : GSTheme
@end

@implementation	TestTheme
/*
 * Method to bypass NSBundle's caching of infoDictionary so that changes
 * to the theme will be reflected immediately.
 */
- (NSDictionary*) infoDictionary
{
  NSString	*path;

  path = [[self bundle] pathForResource: @"Info-gnustep" ofType: @"plist"];
  return [NSDictionary dictionaryWithContentsOfFile: path];
}

/* Method to bypass normal name display so we don't see the temporary
 * work directory name.
 */
- (NSString*) name
{
  return [[[[AppController sharedController] selectedDocument] name]
    stringByDeletingPathExtension];
}
@end


static GSTheme		*initialTheme = nil;
static NSMutableSet	*untitledName = nil;

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
- (unsigned) draggingEntered: (id<NSDraggingInfo>)sender
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

  if ([self superview] != nil)
    {
      mousePoint = [[self superview] convertPoint: mousePoint fromView: nil];
    }
  view = [super hitTest: mousePoint];
  if (view == self)
    {
      view = nil;
    }
  /* Make sure we've found the proper control and not a subview of a 
   * control (like the contentView of an NSBox) */
  while (view != nil && [view superview] != self)
    {
      view = [view superview];
    }

  if (view != nil)
    {
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
  initialTheme = RETAIN([GSTheme theme]);
  untitledName = [NSMutableSet new];
}

- (void) activate
{
  /* Tell the system that our theme is now active.
   * If we are already active, we deactivate first so that the
   * new activation can take effect cleanly.
   */
  if ([GSTheme theme] == _theme)
    {
      [_theme deactivate];
    }
  [GSTheme setTheme: _theme];
  [_theme activate];

  [_selected selectAt: _selectionPoint];
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
      if (e == _selected)
        {
	}
      else
        {
	  [_selected deselect];
	  _selected = e;
	  _selectionPoint = mousePoint;
          [e selectAt: _selectionPoint];
	}
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

  /* Stop our theme being the active theme.
   */
  [GSTheme setTheme: nil];
  DESTROY(_theme);

  /* Remove our temporary work area.
   */
  if (_work != nil)
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];

      [mgr removeFileAtPath: _work handler: nil];
      DESTROY(_work);
    }

  /* Remove self from app controller ... this should deallocate us.
   */
  [[AppController sharedController] removeDocument: self];
}

- (NSColor*) colorNamed: (NSString*)aName
{
  return [_colors colorWithKey: aName];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [self close];
  RELEASE(_elements);
  RELEASE(_colors);
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
  i = [_elements count];
  while (i-- > 0)
    {
      e = [_elements objectAtIndex: i];
      if (aView == [e view])
        {
	  return e;
	}
    }
  
  if ([aView isKindOfClass: [NSImageView class]] == YES)
    {
      if (aView == colorsView)
        {
	  e = [[ColorElement alloc] initWithView: aView owner: self];
	  [_elements addObject: e];
	  RELEASE(e);
	  return e;
	}
      else if (aView == imagesView)
        {
	  e = [[ImageElement alloc] initWithView: aView owner: self];
	  [_elements addObject: e];
	  RELEASE(e);
	  return e;
	}
      else if (aView == menusView)
        {
	  e = [[MenusElement alloc] initWithView: aView owner: self];
	  [_elements addObject: e];
	  RELEASE(e);
	  return e;
	}
      else if (aView == extraView)
        {
	  e = [[MiscElement alloc] initWithView: aView owner: self];
	  [_elements addObject: e];
	  RELEASE(e);
	  return e;
	}
      else if (aView == windowsView)
        {
	  e = [[WindowsElement alloc] initWithView: aView owner: self];
	  [_elements addObject: e];
	  RELEASE(e);
	  return e;
	}
      else
        {
	  NSLog(@"Not known image");
	}
    }
  else
    {
      if ([aView isKindOfClass: [NSButton class]])
        {
	  NSDictionary	*d;

	  /* We could have a subclass of ControlElement to handle button
	   * specific details, but as a button is a simple gui element
	   * we can get away with using the ControlElement class directly
	   * and just configuring it to manage the images needed for
	   * normal, highlighted, and pushed button cells.
	   */
	  d = [NSDictionary dictionaryWithObjectsAndKeys:
	    @"NSButtonNormal", @"normal button mage",
	    @"NSButtonHighlighted", @"highlighted button image",
	    @"NSButtonPushed", @"pushed button image",
	    nil];
	  e = [[ControlElement alloc] initWithView: aView
					     owner: self
					    images: d];
	  [_elements addObject: e];
	  RELEASE(e);
	  return e;
	}
      NSLog(@"Not handled");
    }
  return nil;
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
  NSColorList		*systemColorList;
  NSArray		*keys;
  NSString		*pi;
  NSString		*s;
  unsigned		i;
  BOOL			isDir;

  /*
   * Create a working directory for temporary storage.
   */
  pi = [NSString stringWithFormat: @"%d_%d",
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
	  return NO;
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

  [GSTheme setTheme: initialTheme];

  _elements = [NSMutableArray new];
  if (path != nil)
    {
      NSString	*file;

      file = [path stringByAppendingPathComponent: @"Resources"];
      file = [file stringByAppendingPathComponent: @"ThemeColors.clr"];
      _colors = [[NSColorList alloc] initWithName: @"System"
					 fromFile: file];
      
      file = [path stringByAppendingPathComponent: @"Resources"];
      file = [file stringByAppendingPathComponent: @"Info-gnustep.plist"];
      _info = [[NSMutableDictionary alloc] initWithContentsOfFile: file];
    }
   else
    {
      _colors = [[NSColorList alloc] initWithName: @"System"
					 fromFile: nil];
    }

  /*
   * Make sure the info plist contains a GSThemeDomain dictionary and
   * it is mutable so we can alter it.
   */
  if (_info == nil)
    {
      _info = [NSMutableDictionary new];
    }
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
  systemColorList = [NSColorList colorListNamed: @"System"];
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

  _theme = [[TestTheme alloc] initWithBundle: [NSBundle bundleWithPath: _work]];
  [GSTheme setTheme: _theme];

  [NSBundle loadNibNamed: @"ThemeDocument" owner: self];

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

  [self activate];
  [window orderFront: self];
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
  NSString	*version = [_info objectForKey: @"GSThemeVersion"];
  BOOL		isDirectory;

  /* Increment the version number when we save.
   */
  version = [NSString stringWithFormat: @"%d", [version intValue] + 1];
  [_info setObject: version forKey: @"GSThemeVersion"];
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
  return YES;
}

- (ThemeElement*) selected
{
  return _selected;
}

- (void) setColor: (NSColor*)color forKey: (NSString*)key
{
  NSLog(@"Set %@ for %@", color, key);
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
  if (value == nil)
    {
      [_defs removeObjectForKey: key];
    }
  else
    {
      [_defs setObject: value forKey: key];
    }
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

- (void) setImage: (NSString*)path forKey: (NSString*)key
{
  NSFileManager	*mgr = [NSFileManager defaultManager];
  NSArray	*fileTypes = [NSImage imageFileTypes];
  unsigned	count = [fileTypes count];
  NSString	*file;
  NSString	*name;
  NSString	*ext;

  name = [@"common_" stringByAppendingString: key];
  file = [_rsrc stringByAppendingPathComponent: @"ThemeImages"];
  file = [file stringByAppendingPathComponent: name];

  /*
   * Remove any old image of the same name.
   */
  while (count-- > 0)
    {
      NSString	*ext = [fileTypes objectAtIndex: count];

      [mgr removeFileAtPath: [file stringByAppendingPathExtension: ext]
		    handler: nil];
    }

  ext = [path pathExtension];
  file = [file stringByAppendingPathExtension: ext];
  if ([mgr copyPath: path toPath: file handler: nil] == NO)
    {
      NSRunAlertPanel(_(@"Problem loading image"),
	_(@"Could not copy file into theme"),
	nil, nil, nil);
    }
  else
    {
      [window setDocumentEdited: YES];
      [self activate];			// Preview
    }
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
    }
  [window setTitle: [self name]];
  /* New document ... start with no version number.
   */
  [_info removeObjectForKey: @"GSThemeVersion"];
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

- (void) setTiles: (NSString*)name
	 withPath: (NSString*)path
	hDivision: (int)h
	vDivision: (int)v
{
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
  if ([path length] > 0)
    {
      NSString	*oldFileName = [d objectForKey: @"FileName"];
      NSString	*ext;
      NSString	*nPath;

      ext = [path pathExtension];
      fileName = [name stringByAppendingPathExtension: ext];
      nPath = [_rsrc stringByAppendingPathComponent: @"ThemeTiles"];
      nPath = [nPath stringByAppendingPathComponent: fileName];

      if ([oldFileName length] > 0)
        {
	  NSString	*oPath;

	  oPath = [_rsrc stringByAppendingPathComponent: @"ThemeTiles"];
	  oPath = [oPath stringByAppendingPathComponent: oldFileName];
          [mgr removeFileAtPath: oPath handler: nil];
	}

      if ([mgr copyPath: path toPath: nPath handler: nil] == NO)
	{
	  NSRunAlertPanel(_(@"Alert"),
	    _(@"Unable to load tile image into work area from %@"),
	    nil, nil, nil, path);
	}
    }
  else
    {
      fileName = [d objectForKey: @"FileName"];
    }

  if (fileName != nil)
    {
      NSString	*hDiv = [d objectForKey: @"HorizontalDivision"];
      NSString	*vDiv = [d objectForKey: @"VerticalDivision"];

      if (h > 0)
        {
	  hDiv = [NSString stringWithFormat: @"%d", h];
	}
      if (v > 0)
        {
	  vDiv = [NSString stringWithFormat: @"%d", v];
	}
      d = [NSDictionary dictionaryWithObjectsAndKeys:
        fileName, @"FileName",
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
  [_theme tilesNamed: name cache: NO];
  [self activate];			// Preview
}

/**
 * Return the tiling image (if known) and the division points for the
 * named tiles.
 */
- (NSImage*) tiles: (NSString*)name
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
@end
