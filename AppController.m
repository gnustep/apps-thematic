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

AppController	*thematicController = nil;

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

  /* Support clear button background.
   */
  [NSColor setIgnoresAlpha: NO];
}

+ (AppController*) sharedController
{
  if (thematicController == nil)
    {
      [self new];
    }
  return thematicController;
}

- (id) init
{
  if (thematicController == nil)
    {
      if ((self = [super init]))
	{
	  thematicController = self;
	  documents = [NSMutableArray new];
	  /* Load the property list which defines the API for the code
	   * fragments for each control.  For each control name, this
	   * dictionary should contain another dictionary mapping method
	   * names to their help text.
	   */
	  codeInfo = [[NSDictionary alloc] initWithContentsOfFile:
	    [[NSBundle mainBundle] pathForResource: @"CodeInfo"
					    ofType: @"plist"]];
	}
    }
  else
    {
      RELEASE(self);
      thematicController = RETAIN(thematicController);
    }
  return self;
}

- (void) dealloc
{
  if (thematicController == self)
    {
      thematicController = nil;
    }
  RELEASE(currentDocument);
  RELEASE(documents);
  RELEASE(codeInfo);
  [super dealloc];
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
  ThemeDocument	*doc;
  unsigned	i = [documents count];

  /* Check to see if we already have it open.
   */
  while (i-- > 0)
    {
      doc = [documents objectAtIndex: i];
      if ([[doc path] isEqual: fileName] == YES)
        {
	  /* Already open ... select it
	   */
	  [self selectDocument: doc];
	  return YES;
	}
    }

  /* Not open ... open it
   */
  doc = [[ThemeDocument alloc] initWithPath: fileName];
  if (doc != nil)
    {
      [documents addObject: doc];
      RELEASE(doc);
      [self selectDocument: doc];
    }
  return YES;
}

- (NSDictionary*) codeInfo
{
  return codeInfo;
}

- (NSArray*) documents
{
  return [[documents copy] autorelease];
}

- (NSWindow*) inspector
{
  if (inspector == nil)
    {
      [NSBundle loadNibNamed: @"ThemeInspector" owner: self];
      [inspector setFrameUsingName: @"Inspector"];
      [inspector setFrameAutosaveName: @"Inspector"];
    }
  return (NSWindow*)inspector;
}

- (void) newDocument: (id)sender
{
  ThemeDocument	*doc = [ThemeDocument new];

  if (doc != nil)
    {
      [documents addObject: doc];
      RELEASE(doc);
      [self selectDocument: doc];
    }
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
	  [self application: NSApp openFile: path];
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
  if (currentDocument == sender)
    {
      [self selectDocument: [documents lastObject]];
    }
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
      currentDocument = sender;
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
