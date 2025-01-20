/* MiscElement.m
 *
 * Copyright (C) 2006-2013 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <rfm@gnu.org>
 *              Riccardo Mottola <rm@gnu.org>
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

#import	"AppController.h"
#import "ThemeDocument.h"
#import	"MiscElement.h"

@implementation MiscElement

- (instancetype) init
{
  self = [super init];
  if (self != nil)
    {
    }
  return self;
}

- (void) loadValues
{
  AppController *ctl = [AppController sharedController];
  ThemeDocument *doc = [ctl selectedDocument];
  NSDictionary	*info = [doc infoDictionary];
  NSArray	*arr;
  NSString	*str;
  int		fsize = 32;

  NSLog(@"info = %@", info);
  arr = [info objectForKey: @"GSThemeAuthors"];
  if ([arr count] > 0)
    {
      str = [arr componentsJoinedByString: @"\n"];
      [authors setString: str];
    }
  str = [info objectForKey: @"GSThemeLicense"];
  if ([str length] > 0)
    {
      [license setString: str];
    }
  str = [info objectForKey: @"GSThemeDetails"];
  if ([str length] > 0)
    {
      [details setString: str];
    }
  str = [info objectForKey: @"GSThemeDarkMode"];
  if ([str length] > 0)
    {
      NSLog(@"DARKMODE = %@", str);
      NSLog(@"Button = %@", darkMode);
      [darkMode setState: ([str isEqualToString: @"YES"] ? NSOnState:NSOffState) ];
    }
  [iconView setImage: [[GSTheme theme] icon]];
  do
    {
      [themeName setFont: [NSFont boldSystemFontOfSize: fsize]];
      fsize -= 2;
      [themeName sizeToFit];
    }
  while ([themeName frame].size.width > 200 && fsize > 8);
  [themeName setStringValue: [[doc name] stringByDeletingPathExtension]];
  str = [doc versionIncrementMajor: NO incrementMinor: NO];
  [themeVersion setStringValue: str];
}

- (void) awakeFromNib
{
  [self loadValues];
}

- (void) any: (NSNotification*)o
{
  NSLog(@"Notified: %@", o);
}

- (void) didEndEditing: (id)o
{
  NSNotification	*n;

  /* We must record any editing changes because we have lost keyboard focus
   * or somesuch.
   */
  n = [NSNotification notificationWithName: @"dummy"
				    object: authors
				  userInfo: nil];
  [self textDidEndEditing: n];
  n = [NSNotification notificationWithName: @"dummy"
				    object: license
				  userInfo: nil];
  [self textDidEndEditing: n];
  n = [NSNotification notificationWithName: @"dummy"
				    object: details
				  userInfo: nil];
  [self textDidEndEditing: n];
}

- (void) dealloc
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];
  [super dealloc];
}

- (void) deselect
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  AppController 	*ctl = [AppController sharedController];

  [nc removeObserver: self
	        name: NSWindowDidResignKeyNotification
	      object: [ctl inspector]];
  [self didEndEditing: nil];
  [super deselect];
}

- (void) selectAt: (NSPoint)mouse
{
  NSNotificationCenter	*nc = [NSNotificationCenter defaultCenter];
  AppController *ctl = [AppController sharedController];
  
  [nc addObserver: self
	 selector: @selector(didEndEditing:)
	     name: NSWindowDidResignKeyNotification
	   object: [ctl inspector]];
  
  [self loadValues];
  [super selectAt: mouse];
}

- (void) newVersion: (id)sender
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSString	*ver = [doc versionIncrementMajor: YES incrementMinor: NO];

  [themeVersion setStringValue: ver];
}

- (void) takeIcon: (id)sender
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSArray	*fileTypes = [NSImage imageFileTypes];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: NSHomeDirectory()
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      NSString	*path = [oPanel filename];
      NSImage	*image = nil;

      NS_DURING
	{
	  image = [[NSImage alloc] initWithContentsOfFile: path];
	}
      NS_HANDLER
	{
	  NSString *message = [localException reason];
	  NSRunAlertPanel(_(@"Problem loading theme icon image"), 
	    message, nil, nil, nil);
	}
      NS_ENDHANDLER
      if (image != nil)
        {
	  NSSize	s = [image size];
	  float		scale = 1.0;

	  if (s.height > 48.0)
	    scale = 48.0 / s.height;
	  if (48.0 / s.width < scale)
	    scale = 48.0 / s.width;
	  if (scale != 1.0)
	    {
	      [image setScalesWhenResized: YES];
	      s.height *= scale;
	      s.width *= scale;
	      [image setSize: s];
	    }
	  [doc setResource: path forKey: @"GSThemeIcon"];
	  [iconView setImage: image];
	  RELEASE(image);
	}
    }
}

- (void) textDidEndEditing: (NSNotification*)aNotification
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSTextView	*sender = [aNotification object];
  NSString	*s = [[sender string] stringByTrimmingSpaces];

// NSLog(@"End editing %@", aNotification);
  if (sender == details)
    {
      [doc setInfo: s forKey: @"GSThemeDetails"];
    }
  else if (sender == license)
    {
      [doc setInfo: s forKey: @"GSThemeLicense"];
    }
  else if (sender == authors)
    {
      NSMutableArray    *a;
      unsigned		count;

      a = [[s componentsSeparatedByString: @"\n"] mutableCopy];
      count = [a count];
      while (count-- > 0)
        {
          NSString    *line = [a objectAtIndex: count];

          if ([[line stringByTrimmingSpaces] length] == 0)
            {
              [a removeObjectAtIndex: count];
	    }
        }
      [doc setInfo: a forKey: @"GSThemeAuthors"];
      RELEASE(a);
    }
}

- (IBAction) darkModeSwitch: (id)sender
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  [doc setInfo: ([sender state] == NSOnState) ? @"YES":@"NO"
	forKey: @"GSThemeDarkMode"];
}

- (NSString*) title
{
  return @"Miscellaneous";
}
@end

