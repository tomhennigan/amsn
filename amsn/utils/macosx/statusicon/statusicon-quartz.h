
#import <Cocoa/Cocoa.h>

@interface QuartzStatusIcon : NSObject
{
  void          *callback;
  void          *user_data;
  NSStatusBar   *ns_bar;
  NSStatusItem  *ns_item;
  NSImage       *image;
  NSImage       *alternate_image;
  NSString      *tooltip;
  NSString      *title;
  int           highlighted;
}
- (id) initWithCallback:(void *)callback;
- (void) ensureItem;
- (void) actionCb:(NSObject *)button;
- (void) doubleActionCb:(NSObject *)button;
- (void) setImagePath:(const char *)imagePath;
- (void) setAlternateImagePath:(const char *)alternate_imagePath;
- (void) setVisible:(int)visible;
- (void) setToolTip:(const char *)tooltip_text;
- (void) setTitle:(const char *)title_text;
- (void) setHighlightMode:(const char *)highlightMode;
- (float) getWidth;
- (float) getHeight;
@end
