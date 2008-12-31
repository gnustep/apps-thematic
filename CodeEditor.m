/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "CodeEditor.h"

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
