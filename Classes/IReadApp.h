#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BookView.h"

@interface IReadApp : UIApplication
{
    // user interface
    UIWindow *window;
    BookView *mainView;
}

- (void)statusBarMouseDown:(struct __GSEvent *)event;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@end

