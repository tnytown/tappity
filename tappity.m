#import <AppKit/AppKit.h>

NSEventMask mask = NSEventMaskGesture|NSEventMaskSwipe;

CGEventRef onEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef ref, void *ctx) {
  NSEvent *ev = [NSEvent eventWithCGEvent:ref];
  if(!(mask & NSEventMaskFromType([ev type])))
    return ref;
  
  NSLog(@"onEvent: type = %lu, num = %lu", [ev type], [[ev allTouches] count]);
  if([[ev allTouches] count] < 1)
    return ref;
  NSTouch *touch = [[ev allTouches] anyObject];
  NSPoint pos = [touch normalizedPosition];
  NSLog(@"onEvent: touch = (%f, %f)", pos.x, pos.y);

  CGDirectDisplayID disp = CGMainDisplayID();
  size_t w = CGDisplayPixelsWide(disp);
  size_t h = CGDisplayPixelsHigh(disp);
  CGDisplayMoveCursorToPoint(disp, NSMakePoint(pos.x * w, h - pos.y * h));

  return ref;
}

int main(int argc, char* argv[]) {
  CFMachPortRef tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault,
				       kCGEventMaskForAllEvents, onEvent, nil);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
		     kCFRunLoopCommonModes);
  CGEventTapEnable(tap, true);
  CFRunLoopRun();
}
