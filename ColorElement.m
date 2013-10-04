/* ColorElement.m
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
#import <GNUstepGUI/GSHbox.h>
#import <GNUstepGUI/GSVbox.h>
#import <GNUstepGUI/GSTheme.h>
#import	"AppController.h"
#import	"ThemeDocument.h"
#import	"ColorElement.h"

@implementation ColorElement

/**
 * Basic set of 33 system colors; the default values are
 * defined inside NSColor in gnustep-gui.
 */
static NSArray *systemColorNames;

/**
 * Extra colors use by GSTheme. Each of these names
 * is associated with a normal color, a highlighted color, 
 * and a selected color.
 */
static NSArray *extraColorNames;

+ (void) initialize
{
  if (self == [ColorElement class])
    {
      // This list should not be changed
      systemColorNames = [[NSArray alloc] initWithObjects:
					    @"alternateRowBackgroundColor",
					  @"alternateSelectedControlColor",
					  @"alternateSelectedControlTextColor",
					  @"controlBackgroundColor",
					  @"controlColor",
					  @"controlDarkShadowColor",
					  @"controlHighlightColor",
					  @"controlLightHighlightColor",
					  @"controlShadowColor",
					  @"controlTextColor",
					  @"disabledControlTextColor",
					  @"gridColor",
					  @"headerColor",
					  @"headerTextColor",
					  @"highlightColor",
					  @"nameboardFocusIndicatorColor",
					  @"knobColor",
					  @"rowBackgroundColor",
					  @"scrollBarColor",
					  @"secondarySelectedControlColor",
					  @"selectedControlColor",
					  @"selectedControlTextColor",
					  @"selectedKnobColor",
					  @"selectedMenuItemColor",
					  @"selectedMenuItemTextColor",
					  @"selectedTextBackgroundColor",
					  @"selectedTextColor",
					  @"shadowColor",
					  @"textBackgroundColor",
					  @"textColor",
					  @"windowBackgroundColor",
					  @"windowFrameColor",
					  @"windowFrameTextColor",
					  nil];

      // Feel free to add extra colors here as they are added
      // in GSThemeDrawing.m
      extraColorNames = [[NSArray alloc] initWithObjects:
					   @"toolbarBackgroundColor",
					 @"toolbarBorderColor",
					 @"menuBackgroundColor",
					 @"menuItemBackgroundColor",
					 @"menuBorderColor",
					 @"menuBarBackgroundColor",
					 @"menuBarBorderColor",
					 @"menuSeparatorColor",
					 @"GSMenuBar",
					 @"GSMenuBarTitle",
					 @"tableHeaderTextColor",			  
					 @"keyWindowFrameTextColor",
					 @"normalWindowFrameTextColor",
					 @"mainWindowFrameTextColor",
					 @"windowBorderColor",
					 @"browserHeaderTextColor",
					 @"NSScrollView",
					 nil];
    }
}

- (NSTextField *) makeTextFieldWithLabel: (NSString *)aLabel
{
  NSTextField *text = [[[NSTextField alloc] init] autorelease];
  [text setEditable: NO];
  [text setBezeled: NO];
  [text setDrawsBackground: NO];
  [text setStringValue: aLabel];
  [text sizeToFit];
  [text setAutoresizingMask: (NSViewMinYMargin | NSViewMaxYMargin)];
  return text;
}

- (NSTextField *) makeBoldLabel: (NSString *)aLabel
{
  NSTextField *text = [self makeTextFieldWithLabel: aLabel];
  [text setFont: [NSFont boldSystemFontOfSize: 12.0]];
  [text setSelectable: NO];
  [text sizeToFit];
  return text;
}

- (NSColorWell *) makeColorWellWithTag: (NSInteger)aTag color: (NSColor *)aColor
{
  NSColorWell *color = [[[NSColorWell alloc] initWithFrame: NSMakeRect (0, 0, 50, 30)] autorelease];
  [color setTag: aTag];
  [color setTarget: self];
  [color setAction: @selector(takeColorFrom:)];
  [color setColor: aColor];
  [color setAutoresizingMask: NSViewMinXMargin];
  return color;
}

- (NSColorWell *) makeColorWellWithName: (NSString *)aName isSystem: (BOOL)system state: (GSThemeControlState)state
{
  return [self makeColorWellWithTag: [self tagForName: aName isSystem: system state: state]
			      color: [self colorForName: aName isSystem: system state: state]];
}

- (GSVbox *) makeSystemColorListVbox
{
  GSVbox *vbox = [[GSVbox new] autorelease];
  int i;
  int count = [systemColorNames count];
  
  [vbox setDefaultMinYMargin: 2];
  [vbox setBorder: 2];

  for (i = 0; i < count; i++)
    {
      GSHbox *hbox = [[[GSHbox alloc] init] autorelease];
      NSString *name = [systemColorNames objectAtIndex: i];

      [hbox setDefaultMinXMargin: 10];

      [hbox addView: [self makeTextFieldWithLabel: name]
	    enablingXResizing: YES];
      [hbox addView: [self makeColorWellWithName: name isSystem: YES state: 0]
	    enablingXResizing: NO];
	    
      [hbox setAutoresizingMask: NSViewWidthSizable];
      [vbox addView: hbox];
    }
  
  return vbox;
}

- (GSVbox *) makeExtraColorListVbox
{
  GSVbox *vbox = [[GSVbox new] autorelease];
  int i;
  int count = [extraColorNames count];
  
  [vbox setDefaultMinYMargin: 2];
  [vbox setBorder: 2];
  
  for (i = 0; i < count; i++)
    {
      GSHbox *hbox = [[[GSHbox alloc] init] autorelease];
      NSString *name = [extraColorNames objectAtIndex: i];

      [hbox setDefaultMinXMargin: 10];

      [hbox addView: [self makeTextFieldWithLabel: name] enablingXResizing: YES];
      [hbox addView: [self makeColorWellWithName: name isSystem: NO state: GSThemeNormalState] enablingXResizing: NO];
      [hbox addView: [self makeColorWellWithName: name isSystem: NO state: GSThemeSelectedState] enablingXResizing: NO];
      [hbox addView: [self makeColorWellWithName: name isSystem: NO state: GSThemeHighlightedState] enablingXResizing: NO];
      
      [hbox setAutoresizingMask: NSViewWidthSizable];
      [vbox addView: hbox];
    }
  
  // Labels
  {
    GSHbox *hbox = [[[GSHbox alloc] init] autorelease];
    [hbox setDefaultMinXMargin: 10];
    [hbox addView: [self makeBoldLabel: @"Name"] enablingXResizing: YES];
    [hbox addView: [self makeBoldLabel: @"Normal"] enablingXResizing: NO];
    [hbox addView: [self makeBoldLabel: @"Selected"] enablingXResizing: NO];
    [hbox addView: [self makeBoldLabel: @"Highlighted"] enablingXResizing: NO];
    [hbox setAutoresizingMask: NSViewWidthSizable];
    [vbox addView: hbox];
  }

  return vbox;
}

- (NSScrollView *) makeScrollView
{
  NSScrollView *scrollView = [[[NSScrollView alloc] 
				initWithFrame: NSMakeRect (0, 0, 150, 300)] autorelease];
  GSVbox *vbox = [[[GSVbox alloc] init] autorelease];

  [vbox addView: [self makeExtraColorListVbox]];
  [vbox addView: [self makeBoldLabel: @"Extra Colors"]];

  [vbox addView: [self makeSystemColorListVbox]];
  [vbox addView: [self makeBoldLabel: @"System Colors"]];

  [scrollView setDocumentView: vbox];
  [scrollView setHasHorizontalScroller: NO];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];  
  return scrollView;
}

- (void) selectAt: (NSPoint)mouse
{
  if (ignoreSelectAt)
    return;

  ASSIGN(inspector, [self makeScrollView]);
  [super selectAt: mouse];
}

- (NSString*) title
{
  return @"Colors";
}

- (void) takeColorFrom: (id)sender
{
  NSInteger tag = [sender tag];
  NSColor *color = [(NSColorWell*)sender color];

  if (color != nil)
    {
      NSString	*name = [self nameForTag: tag];
      BOOL system = [self tagIsSystem: tag];
      GSThemeControlState state = [self themeControlStateForTag: tag];

      ignoreSelectAt = YES;
      [self setColor: color forName: name isSystem: system state: state];
      ignoreSelectAt = NO;
    }
 }
	    
- (NSColor *) colorForName: (NSString *)aName isSystem: (BOOL)system state: (GSThemeControlState)state
{
  NSColor *result = nil;
  if (system)
    {
      result = [owner colorForKey: aName];
    }
  else
    {
      if (state == GSThemeNormalState)
	{
	  // do nothing
	}
      else if (state == GSThemeHighlightedState)
	{
	  aName = [aName stringByAppendingString: @"Highlighted"];
	}
      else if (state == GSThemeSelectedState)
	{
	  aName = [aName stringByAppendingString: @"Selected"];
	}
      else
	{
	  NSLog(@"Unsupported theme state");
	}
      result = [owner extraColorForKey: aName];
    }

  if (result == nil)
    {
      //NSLog(@"Theme does not currently define %@", aName);

      // FIXME: Show a "set color" button rather than pretending the color is set to clear 
      result = [NSColor clearColor];
    }
  return result;
}

- (void) setColor: (NSColor *)aColor forName: (NSString *)aName isSystem: (BOOL)system state: (GSThemeControlState)state
{
  if (system)
    {
      [owner setColor: aColor forKey: aName];
    }
  else
    {
      if (state == GSThemeNormalState)
	{
	  // do nothing
	}
      else if (state == GSThemeHighlightedState)
	{
	  aName = [aName stringByAppendingString: @"Highlighted"];
	}
      else if (state == GSThemeSelectedState)
	{
	  aName = [aName stringByAppendingString: @"Selected"];
	}
      else
	{
	  NSLog(@"Unsupported theme state");
	}
      [owner setExtraColor: aColor forKey: aName];
    }
}

// Ugly: map (name, isSystem, state) tuple to an integer and back

- (NSInteger) tagForName: (NSString *)aName isSystem: (BOOL)system state: (GSThemeControlState)state
{
  const NSUInteger systemCount = [systemColorNames count];
  const NSUInteger extraCount = [extraColorNames count];

  NSInteger result = 0;

  if (system) 
    {
      result = [systemColorNames indexOfObject: aName];
    }
  else
    {
      NSInteger indexInExtraArray = [extraColorNames indexOfObject: aName];
      result += (state * extraCount);
      result += indexInExtraArray;
      result += systemCount;      
    }
  return result;
}

- (NSString *) nameForTag: (NSInteger)tag
{
  const NSUInteger systemCount = [systemColorNames count];
  const NSUInteger extraCount = [extraColorNames count];

  if (tag < systemCount)
    {
      return [systemColorNames objectAtIndex: tag];
    }
  else
    {
      tag -= systemCount;
      tag = tag % extraCount;
      return [extraColorNames objectAtIndex: tag];
    }
}

- (BOOL) tagIsSystem: (NSInteger)tag
{
  const NSUInteger systemCount = [systemColorNames count];
  return tag < systemCount;
}

- (GSThemeControlState) themeControlStateForTag: (NSInteger)tag
{
  const NSUInteger systemCount = [systemColorNames count];
  const NSUInteger extraCount = [extraColorNames count];

  if (tag < systemCount)
    {
      return GSThemeNormalState;
    }
  else
    {
      tag -= systemCount;
      return tag / extraCount;
    }
}

@end

