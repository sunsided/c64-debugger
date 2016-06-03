#import <Cocoa/Cocoa.h>

@class Texture;

@interface Scene : NSObject {
}

- (id)init;
- (void)initGL:(NSRect)bounds;

- (void)setViewportRect:(NSRect)bounds;
- (void)render;

- (void)advanceTimeBy:(float)seconds;


@end
