#
# GNUmakefile - Generated by ProjectCenter
#
ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif
ifeq ($(GNUSTEP_MAKEFILES),)
 $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.2
PACKAGE_NAME = Thematic
APP_NAME = Thematic
Thematic_APPLICATION_ICON = Thematic.png


#
# Resource files
#
Thematic_RESOURCE_FILES = \
Resources/Thematic.gorm \
Resources/ThemeInspector.gorm \
Resources/ColorElement.gorm \
Resources/ThemeDocument.gorm \
Resources/ImageAdd.png \
Resources/ImageElement.gorm \
Resources/WindowsElement.gorm \
Resources/MenusElement.gorm \
Resources/MiscElement.gorm \
Resources/ControlElement.gorm \
Resources/CodeEditor.gorm \
Resources/Thematic.png \
Resources/ThematicHelp.rtf \
Resources/CodeInfo.plist \
Resources/drawButton_in_view_style_state_.txt \
Resources/CommonMethods.txt \
Resources/IncludeHeaders.txt \
Resources/MakeAdditions.txt \
Resources/VariableDeclarations.txt 


#
# Header files
#
Thematic_HEADER_FILES = \
AppController.h \
ThemeDocument.h \
ThemeElement.h \
ColorElement.h \
ImageElement.h \
MenusElement.h \
WindowsElement.h \
MiscElement.h \
ControlElement.h \
TilesBox.h \
CodeEditor.h \
MenuItemElement.h \
PreviewElement.h

#
# Class files
#
Thematic_OBJC_FILES = \
AppController.m \
ThemeDocument.m \
ThemeElement.m \
ImageElement.m \
MenusElement.m \
WindowsElement.m \
MiscElement.m \
ControlElement.m \
ColorElement.m \
TilesBox.m \
CodeEditor.m \
MenuItemElement.m \
PreviewElement.m

#
# Other sources
#
Thematic_OBJC_FILES += \
main.m 

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
include $(GNUSTEP_MAKEFILES)/Master/nsis.make
