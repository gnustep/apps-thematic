/* PreviewElement.m
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

#import	"AppController.h"
#import "ThemeDocument.h"
#import	"PreviewElement.h"

@implementation PreviewElement

- (NSImage*) image
{
  NSString	*path;
  NSImage	*image;

  path = [[[GSTheme theme] infoDictionary] objectForKey: @"GSThemePreview"];
  path = [[[GSTheme theme] bundle] pathForResource: path ofType: nil]; 
  image = [[NSImage alloc] initWithContentsOfFile: path];
  return [image autorelease];
}

- (void) selectAt: (NSPoint)mouse
{
  [previewImage setImage: [self image]];
  [super selectAt: mouse];
}

- (void) setPreview: (id)sender
{
  ThemeDocument *doc = [[AppController sharedController] selectedDocument];
  NSImage	*image = [sender image];

  if (image != nil)
    {
      NSSize	s = [image size];
      float	scale = 1.0;
      NSString	*path;

      if (s.height > 128.0)
	scale = 128.0 / s.height;
      if (128.0 / s.width < scale)
	scale = 128.0 / s.width;
      if (scale != 1.0)
	{
	  [image setScalesWhenResized: YES];
	  s.height *= scale;
	  s.width *= scale;
	  [image setSize: s];
	}
// FIXME ... store image to a temporary file to copy into theme
      [doc setResource: path forKey: @"GSThemePreview"];
      RELEASE(image);
      [previewImage setImage: [self image]];
    }
}

- (void) takePreview: (id)sender
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
	  NSRunAlertPanel(_(@"Problem loading theme preview image"), 
	    message, nil, nil, nil);
	}
      NS_ENDHANDLER
      if (image != nil)
        {
	  NSSize	s = [image size];
	  float		scale = 1.0;

	  if (s.height > 128.0)
	    scale = 128.0 / s.height;
	  if (128.0 / s.width < scale)
	    scale = 128.0 / s.width;
	  if (scale != 1.0)
	    {
	      [image setScalesWhenResized: YES];
	      s.height *= scale;
	      s.width *= scale;
	      [image setSize: s];
	    }
	  [doc setResource: path forKey: @"GSThemePreview"];
	  RELEASE(image);
	  [previewImage setImage: [self image]];
	}
    }
}

- (NSString*) title
{
  return @"Preview";
}
@end

