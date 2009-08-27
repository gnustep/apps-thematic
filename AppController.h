/* 
   Project: Thematic

   Copyright (C) 2006 Free Software Foundation

   Author: richard,,,

   Created: 2006-09-18 14:00:14 +0100 by richard
   
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
   Boston, MA 02111 USA.
*/

#import <AppKit/AppKit.h>


@class	ThemeDocument;

@interface AppController : NSObject
{
  id			inspector;
  NSMutableArray	*documents;
  ThemeDocument		*currentDocument;	// Not retained
  NSDictionary		*codeInfo;
}

+ (void) initialize;
+ (AppController*) sharedController;

- (id) init;
- (void) dealloc;

- (void) awakeFromNib;
- (NSDictionary*) codeInfo;

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif;
- (BOOL) applicationShouldTerminate: (id)sender;
- (void) applicationWillTerminate: (NSNotification *)aNotif;
- (BOOL) application: (NSApplication *)application
            openFile: (NSString *)fileName;

- (NSArray*) documents;
- (NSWindow*) inspector;
- (void) newDocument: (id)sender;
- (void) openDocument: (id)sender;
- (void) openInspector: (id)sender;
/** Remove the sender from the array of documents */
- (void) removeDocument: (ThemeDocument*)sender;
- (void) saveAllDocuments: (id)sender;
/** Select the sender as the current document */
- (void) selectDocument: (ThemeDocument*)sender;
/** Return the currently selected document or nil if noe is selected */
- (ThemeDocument*) selectedDocument;
- (void) showPrefPanel: (id)sender;

@end

extern AppController	*thematicController;
