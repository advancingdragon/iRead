#import <math.h>
#import <stdlib.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BookView : UIView
{
    CGPDFDocumentRef book;
    CGPDFPageRef currentPage;
    CGRect currentRect;
    CGRect theFrame;
    CGLayerRef pdfLayer;

    UITouch *touch1;
    UITouch *touch2;

    IBOutlet UIView *navControls;

    IBOutlet UITextField *pdfPath;
    IBOutlet UITextField *pageNumber;
}

- (BookView *)initWithFrame:(CGRect)frame;
- (void)dealloc;
- (void)loadBook:(const char *)filename;
- (void)loadPage:(int)page;
- (void)touchesBegan:(NSSet *)touches withEvent:(id)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(id)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(id)event;
- (void)drawPDFToLayerWithFrame:(CGRect)layerRect;
- (void)drawRect:(CGRect)rect;
- (BOOL)isMultipleTouchEnabled;

- (void)showNavControls;
- (IBAction)endEditingAction;
- (IBAction)back;
- (IBAction)forward;
- (IBAction)goToPage;
- (IBAction)goToFile;

@end

