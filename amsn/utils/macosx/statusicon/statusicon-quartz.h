
#import <Cocoa/Cocoa.h>

@interface QuartzStatusIcon : NSObject
{
  void          *callback;
  NSStatusBar   *ns_bar;
  NSStatusItem  *ns_item;
  NSImage       *current_image;
  NSString      *ns_tooltip;
}
- (id) initWithCallback:(void *)callback;
- (void) ensureItem;
- (void) actionCb:(NSObject *)button;
- (void) setImagePath:(const char *)imagePath;
- (void) setVisible:(int)visible;
- (void) setToolTip:(const char *)tooltip_text;
- (float) getWidth;
- (float) getHeight;
@end
