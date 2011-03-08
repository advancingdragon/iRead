#import "IReadApp.h"

int main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int returnCode = UIApplicationMain(argc, argv, @"IReadApp", @"IReadApp");
    [pool release];
    return returnCode;
}
