#import <AppKit/AppKit.h>

#include <stdlib.h>
#include <math.h>

#define CLIP(x, y) copysignf(fabs(x) <= y ? x : y, x);

NSEventMask mask = NSEventMaskGesture|NSEventMaskSwipe;

typedef struct params {
  float bound;
} params;

CGEventRef onEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef ref, void *ctx) {
  float bound = ((params*) ctx)->bound;
  
  NSEvent *ev = [NSEvent eventWithCGEvent:ref];
  if(!(mask & NSEventMaskFromType([ev type])))
    return ref;
  
  NSLog(@"onEvent: type = %lu, num = %lu", [ev type], [[ev allTouches] count]);
  if([[ev allTouches] count] < 1)
    return ref;
  
  NSTouch *touch = [[ev allTouches] anyObject];
  NSPoint pos = [touch normalizedPosition];
  NSLog(@"onEvent: touch = (%f, %f)", pos.x, pos.y);

  // convert [0, 1] to [-1, 1] range
  pos.x -= 0.5; pos.y -= 0.5;
  pos.x *= 2; pos.y *= 2;

  // flip y axis
  pos.y = -pos.y;

  // clip to boundaries
  pos.x = CLIP(pos.x, bound);
  pos.y = CLIP(pos.y, bound);

  // rescale [-bound, bound] to [-1, 1] 
  pos.x /= bound; pos.y /= bound;

  // convert [-1, 1] to [0, 1]
  pos.x += 1; pos.y += 1;
  pos.x /= 2; pos.y /= 2;

  // scale [0, 1] to pixel count
  CGDirectDisplayID disp = CGMainDisplayID();
  size_t w = CGDisplayPixelsWide(disp), h = CGDisplayPixelsHigh(disp);
  pos.x *= w; pos.y *= h;
  
  CGDisplayMoveCursorToPoint(disp, pos);
  return ref;
}

int main(int argc, char* argv[]) {
  params *p = malloc(sizeof(params));
  if(argc < 2) {
    p->bound = 1.0;
  } else {
    p->bound = strtof(argv[1], NULL);

    if(p->bound <= 0.0 || p->bound > 1.0) {
      NSLog(@"%s: invalid bound %s given, expected float E (0.0, 1.0]", argv[0], argv[1]);
      return -1;
    }
    
    if(p->bound == 0.0) {
      NSLog(@"%s: invalid bound %s given, expected numeric non-zero float", argv[0], argv[1]);
      return -1;
    }
  }
  
  CFMachPortRef tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault,
				       kCGEventMaskForAllEvents, onEvent, p);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
		     kCFRunLoopCommonModes);
  CGEventTapEnable(tap, true);
  CFRunLoopRun();
  
  free(p);
  return 0;
}
