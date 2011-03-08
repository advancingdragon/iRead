#import "IReadApp.h"

@implementation IReadApp

- (void)statusBarMouseDown:(struct __GSEvent *)event
{
    [mainView showNavControls];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Set up window
    CGRect rect = CGRectMake(0.0, 0.0, 300, 480); 
    [self setStatusBarMode: 3 orientation: 90 duration: 0];
    window = [[UIWindow alloc] initWithContentRect: rect];
    [window orderFront: self];
    [window makeKey: self];
    [window setHidden: NO];

    mainView = [[BookView alloc] initWithFrame: [window bounds]];
    [window setContentView: mainView];
    [mainView setHidden: NO];
    [mainView setNeedsDisplay];
}
 
@end

