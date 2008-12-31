/* CodeEditor.h
 *
 * Copyright (C) 2008 Free Software Foundation, Inc.
 *
 * Author:	Richard Frith-Macdonald <rfm@gnu.org>
 * Date:	2008
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
#import <AppKit/AppKit.h>
#import <GNUstepBase/NSTask+GS.h>
#import "AppController.h"
#import "ThemeDocument.h"
#import "CodeEditor.h"

@implementation CodeEditor

static CodeEditor *instance = nil;

+ (CodeEditor*) codeEditor
{
  if (instance == nil)
    {
      [self new];
    }
  return instance;
}


- (void) codeBuildFor: (ThemeDocument*)document method: (NSString*)singleMethod
{
  NSFileManager		*mgr = [NSFileManager defaultManager];
  AppController		*app = [AppController sharedController];
  NSDictionary		*codeInfo;
  NSMutableSet		*methods;
  NSString		*methodName;
  NSEnumerator		*enumerator;
  NSDictionary		*controlInfo;
  NSString		*path;
  NSString		*version;
  NSString		*fullName;
  NSMutableString	*codeText;
  NSMutableString	*makeText;
  NSString		*launchPath;
  NSTask		*task;
  NSString		*logFile;
  NSFileHandle		*logHandle;
  int			status;

  version = [[document infoDictionary] objectForKey: @"GSThemeVersion"];
  if (version == nil) version = @"0";
  fullName = [NSString stringWithFormat: @"%@_%@",
    [[document name] stringByDeletingPathExtension], version];
  
  makeText = [NSMutableString string];
  [makeText appendString: @"include $(GNUSTEP_MAKEFILES)/common.make\n"];
  [makeText appendString: @"BUNDLE_NAME=Theme\n"];
  //[makeText appendString: @"ADDITIONAL_LIB_DIRS=XXX\n"];
  [makeText appendString: @"Theme_OBJC_FILES=Theme.m\n"];
  [makeText appendFormat: @"Theme_PRINCIPAL_CLASS=%@\n", fullName];
  [makeText appendString: @"include $(GNUSTEP_MAKEFILES)/bundle.make\n"];

  codeText = [NSMutableString string];
  [codeText appendString: @"#import <AppKit/AppKit.h>\n"];
  [codeText appendString: @"#import <GNUstepGUI/GSTheme.h>\n"];
  [codeText appendFormat: @"@interface %@ : GSTheme\n", fullName];
  [codeText appendString: @"@end\n"];
  [codeText appendFormat: @"@implementation %@\n", fullName];

  methods = [[NSMutableSet alloc] autorelease];
  codeInfo = [app codeInfo];
  if (singleMethod == nil)
    {
      /* Build with all methods.
       */
      enumerator = [codeInfo objectEnumerator];
      while ((controlInfo = [enumerator nextObject]) != nil)
        {
          [methods addObjectsFromArray: [controlInfo allKeys]];
        }
    }
  else
    {
      /* Build a single method.
       */
      [methods addObject: singleMethod];
    }
  enumerator = [methods objectEnumerator];
  while ((methodName = [enumerator nextObject]) != nil)
    {
      NSString	*code = [document codeForKey: methodName];

      if (code != nil)
	{
	  [codeText appendString: @"\n"];
	  [codeText appendString: code];
	}
    }
  [codeText appendString: @"@end\n"];

  path = [NSTemporaryDirectory() stringByAppendingPathComponent:
    [NSString stringWithFormat: @"Thematic%d",
    [[NSProcessInfo processInfo] processIdentifier]]];
  [mgr createDirectoryAtPath: path attributes: nil];

  [makeText writeToFile: [path stringByAppendingPathComponent: @"GNUmakefile"]
	     atomically: NO];
  [codeText writeToFile: [path stringByAppendingPathComponent: @"Theme.m"]
	     atomically: NO];
  logFile = [path stringByAppendingPathComponent: @"make.log"];
  [mgr createFileAtPath: logFile contents: nil attributes: nil];
  logHandle = [NSFileHandle fileHandleForWritingAtPath: logFile];

  [mgr createDirectoryAtPath: path attributes: nil];
  launchPath = [NSTask launchPathForTool: @"make"];
  task = [NSTask new];
  [task setLaunchPath: launchPath];
  [task setCurrentDirectoryPath: path];
  [task setStandardError: logHandle];
  [task setStandardOutput: logHandle];
  [task launch];
  while ([task isRunning])
    {
      CREATE_AUTORELEASE_POOL(arp);
      [[NSRunLoop currentRunLoop] runUntilDate:
	[NSDate dateWithTimeIntervalSinceNow: 0.1]];
      RELEASE(arp);
    }
  status = [task terminationStatus];
  [task release];  
  if (status == 0)
    {
      [document setBinaryBundle:
	[path stringByAppendingPathComponent: @"Theme.bundle"]];
    }
  else
    {
      NSString	*output = [NSString stringWithContentsOfFile: logFile]; 

      NSRunAlertPanel(_(@"Problem building theme"),
	_(@"Build operation failed: %@"),
		nil, nil, nil, output);
      [document setBinaryBundle: nil];
    }
  [mgr removeFileAtPath: path handler: nil];
}

- (void) codeDone: (id)sender
{
  NSDictionary	*userInfo;

  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    [textView text], @"Text",
    control, @"Control",
    method, @"Method",
    nil];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: @"CodeEditDone"
    object: self
    userInfo: userInfo];

  [self endEdit];
}


- (void) codeRevert: (id)sender
{
  [textView setText: text];
}


- (void) codeCancel: (id)sender
{
  [self endEdit];
}


- (void) dealloc
{
  [text release];
  [control release];
  [method release];
  [super dealloc];
}


- (void) editText: (NSString*)t control: (NSString*)c method: (NSString*)m
{
  ASSIGNCOPY(text, t);
  ASSIGNCOPY(control, c);
  ASSIGNCOPY(method, m);
  [[self textView] setText: text];
  [panel setTitle: m];
  [panel makeKeyAndOrderFront: self];
}


- (void) endEdit
{
  [panel orderOut: self];
  [textView setText: @""];
  DESTROY(text);
  DESTROY(control);
  DESTROY(method);
}


- (id) init
{
  if (instance == nil)
    {
      instance = self;
    }
  else if (instance != self)
    {
      [self release];
      self = instance;
    }
  return self;
}


- (NSTextView*) textView
{
  if (textView == nil)
    {
      [NSBundle loadNibNamed: @"CodeEditor" owner: self];
    }
  return (NSTextView*)textView;
}

@end
