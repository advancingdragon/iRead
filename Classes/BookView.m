#import "BookView.h"

float fsqr(float x)
{
    return x*x;
}

@implementation UITouch (TouchSorting)
- (NSComparisonResult)compareAddress:(id)obj {
    if ((void *)self < (void *)obj) return NSOrderedAscending;
    else if ((void *)self == (void *)obj) return NSOrderedSame;
    else return NSOrderedDescending;
}
@end

@implementation BookView

- (BookView *)initWithFrame:(CGRect)frame
{
    [super initWithFrame: frame];
    theFrame = frame; // save for future reference

    // create nav controls
    [[NSBundle mainBundle] 
        loadNibNamed: @"NavControlsView" owner: self options: nil];
    navControls.center = CGPointMake(320.0-20.0-navControls.bounds.size.height/2.0, navControls.bounds.size.width/2.0);
    navControls.transform = CGAffineTransformMake(0.0, 1.0, -1.0, 0.0, 0.0, 0.0);
    pageNumber.keyboardType = UIKeyboardTypeNumberPad;
    [self addSubview: navControls];
    // initialize touch data
    touch1 = nil;
    touch2 = nil;

    return self;
}

- (void)dealloc
{
    CGPDFDocumentRelease(book);
    CGLayerRelease(pdfLayer);
    [touch1 release];
    [touch2 release];
    // is this necessary?
    //[navControls release];
}

- (void)loadBook:(const char *)filename
{
    CFStringRef path;
    CFURLRef url;

    // release old one; won't crash if null
    CGPDFDocumentRelease(book);

    // Open eBook
    path = CFStringCreateWithCString(NULL, 
                                     filename, 
                                     kCFStringEncodingUTF8);
    url = CFURLCreateWithFileSystemPath(NULL, 
                                        path, 
                                        kCFURLPOSIXPathStyle, 
                                        0);
    CFRelease(path);
    book = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);

    [self loadPage: 1];
}

- (void)loadPage:(int)page
{
    float temp;

    // check if page number in bounds
    if (!(1 <= page && page <= CGPDFDocumentGetNumberOfPages(book)))
        return;

    CGLayerRelease(pdfLayer);

    currentPage = CGPDFDocumentGetPage(book, page);
    pdfLayer = nil;
    // setup display rect
    currentRect = CGPDFPageGetBoxRect(currentPage, kCGPDFMediaBox);
    // rotate the rect by 90 degrees
    temp = currentRect.size.width;
    currentRect.size.width = currentRect.size.height;
    currentRect.size.height = temp;
    // move the origin so that top left of document is top right of screen
    currentRect.origin.x = theFrame.size.width - currentRect.size.width;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(id)event
{
    NSArray *sortedTouches;

    sortedTouches = [[touches allObjects] sortedArrayUsingSelector: @selector(compareAddress:)];
    if ([sortedTouches count] == 1)
    {
        if (touch1 == nil)
        {
            touch1 = [sortedTouches objectAtIndex: 0];
            [touch1 retain];
        }
        else if (touch2 == nil) 
        {
            touch2 = [sortedTouches objectAtIndex: 0];
            [touch2 retain];
        }
    }
    else
    {
        touch1 = [sortedTouches objectAtIndex: 0];
        [touch1 retain];
        touch2 = [sortedTouches objectAtIndex: 1];
        [touch2 retain];
    }

}

- (void)touchesMoved:(NSSet *)touches withEvent:(id)event
{
    if (touch1 == nil || touch2 == nil)
    {
        // one finger down; move
        CGPoint loc;
        CGPoint prevLoc;
        if (touch1 != nil)
        {
            loc = [touch1 locationInView: self];
            prevLoc = [touch1 previousLocationInView: self];
        }
        else if (touch2 != nil)
        {
            loc = [touch2 locationInView: self];
            prevLoc = [touch2 previousLocationInView: self];
        }
        currentRect.origin.x += loc.x - prevLoc.x;
        currentRect.origin.y += loc.y - prevLoc.y;
    }
    else
    {
        // two fingers down; zoom
        CGPoint loc1, loc2;
        CGPoint prevLoc1, prevLoc2;
        float prevDistance, distance, ratio;

        // the zoom is proportional to the change in distance between the two fingers
        loc1 = [touch1 locationInView: self];
        prevLoc1 = [touch1 previousLocationInView: self];
        loc2 = [touch2 locationInView: self];
        prevLoc2 = [touch2 previousLocationInView: self];
        distance = sqrt(fsqr(loc2.x - loc1.x) + fsqr(loc2.y - loc1.y));
        prevDistance = sqrt(fsqr(prevLoc2.x - prevLoc1.x) + fsqr(prevLoc2.y - prevLoc1.y));
        ratio = currentRect.size.width / currentRect.size.height;
        currentRect.origin.x -= ratio*(distance - prevDistance);
        currentRect.origin.y -= distance - prevDistance;
        currentRect.size.width += 2.0*ratio*(distance - prevDistance);
        currentRect.size.height += 2.0*(distance - prevDistance);
    }
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(id)event
{
    NSArray *sortedTouches;

    // NOTE: calling endEditing: during touchesBegan:withEvent: causes touchesEnded:withEvent: later not to fire; probably a UIKit bug
    if (navControls.hidden != YES)
        [self endEditingAction];

    sortedTouches = [[touches allObjects] sortedArrayUsingSelector: @selector(compareAddress:)];
    if ([sortedTouches count] == 1)
    {
        UITouch *temp = [sortedTouches objectAtIndex: 0];
        if (temp == touch1)
        {
            [touch1 release];
            touch1 = nil;
        }
        else if (temp == touch2)
        {
            [touch2 release];
            touch2 = nil;
        }
    }
    else
    {
        [touch1 release];
        touch1 = nil;
        [touch2 release];
        touch2 = nil;
    }
}

- (void)drawPDFToLayerWithFrame:(CGRect)layerRect
{
    CGContextRef layerContext;
    CGAffineTransform m;
    layerContext = CGLayerGetContext(pdfLayer);

    // whiten screen
    CGContextSetGrayFillColor(layerContext, 1.0, 1.0);
    CGContextFillRect(layerContext, layerRect);

    // rotate and enlarge
    // Note: CGLayer seems to understand that iPhone's
    // CGContext's coordinate system is upside down.
    m = CGAffineTransformMake(0.0, 2.0, 2.0, 0.0, 0.0, 0.0);

    // draw PDF
    CGContextConcatCTM(layerContext, m);
    CGContextDrawPDFPage(layerContext, currentPage);
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context;

    context = (CGContextRef)UIGraphicsGetCurrentContext();

    if (pdfLayer == nil)
    {
        CGRect layerRect = currentRect;
        layerRect.origin = CGPointMake(0.0, 0.0);
        layerRect.size.width *= 2;
        layerRect.size.height *= 2;
        pdfLayer = CGLayerCreateWithContext(context, layerRect.size, NULL);
        [self drawPDFToLayerWithFrame: layerRect];
    }

    CGContextDrawLayerInRect(context, currentRect, pdfLayer);
}

- (BOOL)isMultipleTouchEnabled
{
    return YES;
}

- (void)showNavControls
{
    // Update page number in text field
    int page = CGPDFPageGetPageNumber(currentPage);
    //[pageNumber.text release];
    NSString *newPageString = [NSString stringWithFormat: @"%i", page];
    pageNumber.text = newPageString;

    navControls.hidden = NO;
}

- (IBAction)endEditingAction
{
    [navControls endEditing: NO];
    navControls.hidden = YES;
}

- (IBAction)back
{
    int page = CGPDFPageGetPageNumber(currentPage);
    [self loadPage: page-1];
    [self setNeedsDisplay];
}

- (IBAction)forward
{
    int page = CGPDFPageGetPageNumber(currentPage);
    [self loadPage: page+1];
    [self setNeedsDisplay];
}

- (IBAction)goToPage
{
    int page = [pageNumber.text intValue];
    [self loadPage: page];
    [self setNeedsDisplay];
}
- (IBAction)goToFile
{
    [self loadBook: [pdfPath.text UTF8String]];
}

@end

