/* CodeEditor.h
 *
 * Copyright (C) 2008-2010 Free Software Foundation, Inc.
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
  NSProcessInfo		*pi = [NSProcessInfo processInfo];
  NSDictionary		*codeInfo;
  NSMutableSet		*methods;
  NSString		*methodName;
  NSEnumerator		*enumerator;
  NSDictionary		*generic;
  NSString		*path;
  NSString		*fullName;
  NSMutableString	*codeText;
  NSMutableString	*makeText;
  NSString		*launchPath;
  NSTask		*task;
  NSString		*string;
  NSString		*logFile;
  NSFileHandle		*logHandle;
  int			status;

  string = [[pi environment] objectForKey: @"GNUSTEP_MAKEFILES"];
  if (string == nil && [NSTask launchPathForTool: @"gnustep-install"] == nil)
    {
      NSRunAlertPanel(_(@"Problem building theme"),
	_(@"Can't locate gnustep-make (no GNUSTEP_MAKEFILES in environment)"),
		nil, nil, nil, nil);
      [document setBinaryBundle: nil];
    }

  fullName = [NSString stringWithFormat: @"%@_%@",
    [[document name] stringByDeletingPathExtension],
    [[document versionIncrementMajor: NO incrementMinor: YES]
      stringByReplacingString: @"." withString: @"_"]];
  
  codeInfo = [app codeInfo];
  /* The items in the generic dictionary are handled specially rather
   * than being treated as methods.
   */
  generic = [codeInfo objectForKey: @"Generic"];
  if (singleMethod != nil && [generic objectForKey: singleMethod] != nil)
    {
      singleMethod = nil;
    }

  makeText = [NSMutableString string];
  [makeText appendString: @"ifeq ($(GNUSTEP_MAKEFILES),)\n"];
  [makeText appendString: @"  GNUSTEP_MAKEFILES := $(shell gnustep-config "];
  [makeText appendString: @" --variable=GNUSTEP_MAKEFILES 2>/dev/null)\n"];
  [makeText appendString: @"endif\n"];
  [makeText appendString: @"include $(GNUSTEP_MAKEFILES)/common.make\n"];
  [makeText appendString: @"BUNDLE_NAME=Theme\n"];
  string = [document codeForKey: @"MakeAdditions" since: 0];
  if ([string length] > 0)
    {
      [makeText appendString: @"\n"];
      [makeText appendString: string];
      [makeText appendString: @"\n"];
    }
  [makeText appendString: @"Theme_OBJC_FILES=Theme.m\n"];
  [makeText appendFormat: @"Theme_PRINCIPAL_CLASS=%@\n", fullName];
  [makeText appendString: @"include $(GNUSTEP_MAKEFILES)/bundle.make\n"];

  codeText = [NSMutableString string];
  [codeText appendString: @"#import <AppKit/AppKit.h>\n"];
  [codeText appendString: @"#import <GNUstepGUI/GSTheme.h>\n"];
  string = [document codeForKey: @"IncludeHeaders" since: 0];
  if ([string length] > 0)
    {
      [codeText appendString: @"\n"];
      [codeText appendString: string];
      [codeText appendString: @"\n"];
    }

  /* Write out the main theme interface document.
   */
  [codeText appendFormat: @"@interface %@ : GSTheme\n", fullName];
  string = [document codeForKey: @"VariableDeclarations" since: 0];
  if ([string length] > 0)
    {
      [codeText appendString: @"\n"];
      [codeText appendString: string];
      [codeText appendString: @"\n"];
    }
  [codeText appendString: @"@end\n"];

  /* Write out the common code.
   */
  [codeText appendFormat: @"@implementation %@\n", fullName];
  string = [document codeForKey: @"CommonMethods" since: 0];
  if ([string length] > 0)
    {
      [codeText appendString: @"\n"];
      [codeText appendString: string];
      [codeText appendString: @"\n"];
    }
  [codeText appendString: @"@end\n"];

  methods = [[NSMutableSet alloc] autorelease];
  if (singleMethod == nil)
    {
      NSDictionary	*controlInfo;

      /* Build with all methods.
       */
      enumerator = [codeInfo objectEnumerator];
      while ((controlInfo = [enumerator nextObject]) != nil)
        {
	  if (controlInfo != generic)
	    {
              [methods addObjectsFromArray: [controlInfo allKeys]];
	    }
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
      NSString	*code = [document codeForKey: methodName since: 0];

      if (code != nil)
	{
          [codeText appendFormat: @"@implementation %@ (%@)\n", fullName,
	    [methodName stringByReplacingString: @":" withString: @"_"]];
	  [codeText appendString: @"\n"];
	  [codeText appendString: code];
	  [codeText appendString: @"@end\n"];
	}
    }

  path = [document buildDirectory];

  [makeText writeToFile: [path stringByAppendingPathComponent: @"GNUmakefile"]
	     atomically: NO];
  [codeText writeToFile: [path stringByAppendingPathComponent: @"Theme.m"]
	     atomically: NO];
  logFile = [path stringByAppendingPathComponent: @"make.log"];
  [mgr createFileAtPath: logFile contents: nil attributes: nil];
  logHandle = [NSFileHandle fileHandleForWritingAtPath: logFile];

  [mgr createDirectoryAtPath: path attributes: nil];
  launchPath = [NSTask launchPathForTool: @"gmake"];
  if (launchPath == nil)
    {
      launchPath = [NSTask launchPathForTool: @"gmake"];
      if (launchPath == nil)
	{
          [mgr removeFileAtPath: path handler: nil];
	  NSRunAlertPanel(_(@"Problem building theme"),
	    _(@"Unable to locate 'make' program"),
		    nil, nil, nil, nil);
	  [document setBinaryBundle: nil];
	}
    }
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
