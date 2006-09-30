/* 
   Project:  Thematic

   Copyright (C) 2006 Free Software Foundation

   Author:  richard,,,

   Created:  2006-09-18 14:00:14 +0100 by richard
   
   Application Controller

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA  02110-1301, USA
*/

#import "AppController.h"
#import "ThemeDocument.h"

@implementation AppController

static AppController	*shared = nil;

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject: anObject forKey: keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (AppController*) sharedController
{
  if (shared == nil)
    {
      [self new];
    }
  return shared;
}

- (id) init
{
  if (shared == nil)
    {
      if ((self = [super init]))
	{
	  shared = self;
	  documents = [NSMutableArray new];
	}
    }
  else
    {
      RELEASE(self);
      shared = RETAIN(shared);
    }
  return self;
}

- (void) dealloc
{
  if (shared == self)
    {
      shared = nil;
    }
  RELEASE(currentDocument);
  RELEASE(documents);
  [super dealloc];
}

- (void) addDocument: (ThemeDocument*)sender
{
  if ([documents indexOfObjectIdenticalTo: sender] == NSNotFound)
    {
      [documents addObject: sender];
    }
}

- (void) awakeFromNib
{
  [[NSApp mainMenu] setTitle: @"Thematic"];
  [NSApp setDelegate: self];
}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
}

- (BOOL) applicationShouldTerminate: (id)sender
{
  return YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName
{
  return YES;
}

- (NSWindow*) inspector
{
  if (inspector == nil)
    {
      [NSBundle loadNibNamed: @"ThemeInspector" owner: self];
    }
  return (NSWindow*)inspector;
}

- (void) newDocument: (id)sender
{
  [ThemeDocument new];
}

- (void) openDocument: (id)sender
{
  NSArray	*fileTypes = [NSArray arrayWithObject: @"theme"];
  NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
  int		result;
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
	  base = nil;
	}
    }
  if (base == nil)
    {
      base = NSHomeDirectory();
    }

  [oPanel setAllowsMultipleSelection: NO];
  [oPanel setCanChooseFiles: YES];
  [oPanel setCanChooseDirectories: NO];
  result = [oPanel runModalForDirectory: base
				   file: nil
				  types: fileTypes];
  if (result == NSOKButton)
    {
      NSString *path = [oPanel filename];

      NS_DURING
	{
	  [[ThemeDocument alloc] initWithPath: path];
	}
      NS_HANDLER
	{
	  NSString *message = [localException reason];
	  NSRunAlertPanel(_(@"Problem parsing class"), 
			  message,
			  nil, nil, nil);
	}
      NS_ENDHANDLER
    }
}

- (void) openInspector: (id)sender
{
  [[self inspector] makeKeyAndOrderFront: self];
}

- (void) removeDocument: (ThemeDocument*)sender
{
  [documents removeObjectIdenticalTo: sender];
}

- (void) saveAllDocuments: (id)sender
{
  NSArray	*docs = AUTORELEASE([documents copy]);
  unsigned	i = [docs count];

  while (i-- > 0)
    {
      ThemeDocument	*doc = [docs objectAtIndex: i];

      if ([documents indexOfObjectIdenticalTo: doc] != NSNotFound)
        {
	  [doc saveDocument: sender];
	}
    }
}

- (void) selectDocument: (ThemeDocument*)sender
{
  if (currentDocument != sender)
    {
      ASSIGN(currentDocument, sender);
      [currentDocument activate];
    }
}

- (ThemeDocument*) selectedDocument
{
  return currentDocument;
}

- (void) showPrefPanel: (id)sender
{
}

@end
