/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface CodeEditor : NSObject
{
  id textView;
  id panel;
  NSString	*text;
  NSString	*control;
  NSString	*method;
}
+ (CodeEditor*) codeEditor;
- (void) codeDone: (id)sender;
- (void) codeRevert: (id)sender;
- (void) codeCancel: (id)sender;
- (void) editText: (NSString*)t control: (NSString*)c method: (NSString*)m;
- (void) endEdit;
- (NSTextView*) textView;
@end
