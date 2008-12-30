/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "ThemeElement.h"

@class	TilesBox;

@interface ControlElement : ThemeElement
{
  NSDictionary	*images;
  TilesBox	*tiles;
  NSString	*className;
  id codeDescription;
  id colorsMenu;
  id colorsWell;
  id codeMenu;
  id tilesHorizontal;
  id tilesImages;
  id tilesMenu;
  id tilesStyle;
  id tilesVertical;
}
- (NSString*) imageName;
- (id) initWithView: (NSView*)aView
              owner: (ThemeDocument*)aDocument
	     images: (NSDictionary*)imageInfo;
- (int) style;
- (void) takeCodeDelete: (id)sender;
- (void) takeCodeEdit: (id)sender;
- (void) takeCodeMethod: (id)sender;
- (void) takeColorName: (id)sender;
- (void) takeColorValue: (id)sender;
- (void) takeTileImage: (id)sender;
- (void) takeTilePosition: (id)sender;
- (void) takeTileSelection: (id)sender;
- (void) takeTileStyle: (id)sender;
@end
