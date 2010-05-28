/* statusicon-quartz.h:
 *
 * Copyright (C) 2006 Imendio AB
 * Copyright (C) 2010 Youness Alaoui
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * GCC on Mac OS X handles inlined objective C in C-files.
 *
 * Authors:
 *  Mikael Hallendal <micke@imendio.com>
 *  Youness Alaoui
 */


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
