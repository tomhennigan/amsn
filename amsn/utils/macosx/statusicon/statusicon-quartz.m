/* statusicon-quartz.c:
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

#include "statusicon-quartz.h"

@implementation QuartzStatusIcon : NSObject
- (id) initWithCallback:(void *)cb andUserData:(void *)data;
{
  [super init];
  ns_bar = [NSStatusBar systemStatusBar];

  [ns_bar retain];

  callback = cb;
  user_data = data;

  return self;
}

- (void) ensureItem
{
  if (ns_item != nil)
    return;

  ns_item = [ns_bar statusItemWithLength:NSVariableStatusItemLength];
  [ns_item setAction:@selector(actionCb:)];
  [ns_item setDoubleAction:@selector(doubleActionCb:)];
  [ns_item setTarget:self];
  [ns_item retain];
}

- (void) dealloc
{
  [ns_bar removeStatusItem:ns_item];
  [image release];
  [alternate_image release];
  [tooltip release];
  [title release];
  [ns_item release];
  [ns_bar release];

  [super dealloc];
}

- (void) actionCb:(NSObject *)button
{
  void (*cb)(QuartzStatusIcon *, void *, int) = callback;
  cb(self, user_data, 0);
}

- (void) doubleActionCb:(NSObject *)button
{
  void (*cb)(QuartzStatusIcon *, void *, int) = callback;
  cb(self, user_data, 1);
}

- (void) setImagePath:(const char *)imagePath
{
  /* Support NULL */
  [self ensureItem];

  if (image != nil) {
    [image release];
    image = nil;
  }
  
  if (imagePath) {
    image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:imagePath]];
    if (image) {
      [image setSize:NSMakeSize([self getWidth], [self getHeight])];
      [image retain];
    }
  }

  [ns_item setImage:image];
}

- (void) setAlternateImagePath:(const char *)alternate_imagePath
{
  /* Support NULL */
  [self ensureItem];

  if (alternate_image != nil) {
    [alternate_image release];
    alternate_image = nil;
  }

  if (alternate_imagePath) {
    alternate_image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:alternate_imagePath]];
    if (alternate_image) {
      [alternate_image setSize:NSMakeSize([self getWidth], [self getHeight])];
      [alternate_image retain];
    }
  }

  [ns_item setAlternateImage:alternate_image];
}

- (void) setVisible:(int)visible
{
  if (visible) {
    [self ensureItem];
    if (image != nil)
      [ns_item setImage:image];
    if (alternate_image != nil)
      [ns_item setAlternateImage:alternate_image];
    if (tooltip != nil)
      [ns_item setToolTip:tooltip];
    if (title != nil)
      [ns_item setTitle:title];
    [ns_item setHighlightMode:highlighted];
  } else {
    [ns_bar removeStatusItem:ns_item];
    [ns_item release];
    ns_item = nil;
  }
}

- (void) setToolTip:(const char *)tooltip_text
{
  [self ensureItem];

  if (tooltip != nil)
    [tooltip release];
  tooltip = nil;

  /* if tooltip_text is nil, raises an exception */
  if (tooltip_text)
    tooltip = [[NSString stringWithUTF8String:tooltip_text] retain];

  [ns_item setToolTip:tooltip];
}

- (void) setTitle:(const char *)title_text
{
  [self ensureItem];

  if (title != nil)
    [title release];
  title = nil;

  /* if title_text is nil, raises an exception */
  if (title_text)
    title = [[NSString stringWithUTF8String:title_text] retain];

  [ns_item setTitle:title];
}

- (void) setHighlightMode:(int)highlightMode
{
  highlighted = highlightMode;
  [ns_item setHighlightMode:highlighted];
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



