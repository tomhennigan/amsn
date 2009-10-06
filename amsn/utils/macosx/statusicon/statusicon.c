/* statusicon-quartz.c:
 *
 * Copyright (C) 2006 Imendio AB
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
 */

#import <Cocoa/Cocoa.h>

#define QUARTZ_POOL_ALLOC NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]
#define QUARTZ_POOL_RELEASE [pool release]

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
- (void) setImage:(NSImage *)image;
- (void) setVisible:(int)visible;
- (void) setToolTip:(const char *)tooltip_text;
- (float) getWidth;
- (float) getHeight;
@end

@implementation QuartzStatusIcon : NSObject
- (id) initWithCallback:(void *)callback;
{
  [super init];
  ns_bar = [NSStatusBar systemStatusBar];

  cb = callback

  return self;
}

- (void) ensureItem
{
  if (ns_item != nil)
    return;

  ns_item = [ns_bar statusItemWithLength:NSVariableStatusItemLength];
  [ns_item setAction:@selector(actionCb:)];
  [ns_item setTarget:self];
  [ns_item retain];
}

- (void) dealloc
{
  [current_image release];
  [ns_item release];
  [ns_bar release];

  [super dealloc];
}

- (void) actionCb:(NSObject *)button
{
  cb ();
}

- (void) setImage:(NSImage *)image
{
  /* Support NULL */
  [self ensureItem];

  if (current_image != nil) {
    [current_image release];
    current_image = nil;
  }

  if (!pixbuf) {
    [ns_item release];
    ns_item = nil;
    return;
  }

  current_image = image;
  [current_image retain];

  [ns_item setImage:current_image];
}

- (void) setVisible:(int)visible
{
  if (visible) {
    [self ensureItem];
    if (ns_item != nil)
      [ns_item setImage:current_image];
    if (ns_tooltip != nil)
      [ns_item setToolTip:ns_tooltip];
  } else {
    [ns_item release];
    ns_item = nil;
  }
}

- (void) setToolTip:(const char *)tooltip_text
{
  [ns_tooltip release];
  ns_tooltip = [[NSString stringWithUTF8String:tooltip_text] retain];

  [ns_item setToolTip:ns_tooltip];
}

- (float) getWidth
{
  return [ns_bar thickness];
}

- (float) getHeight
{
  return [ns_bar thickness];
}
@end



