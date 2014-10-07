//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by Krzysztof Kula on 01.09.2014.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;

@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;

@property (nonatomic, weak) BNRLine *selectedLine;

@end

@implementation BNRDrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        self.linesInProgress = [[NSMutableDictionary alloc] init];
        self.finishedLines = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor grayColor];
        self.multipleTouchEnabled = YES;
        
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan = YES;
        
        [self addGestureRecognizer:doubleTapRecognizer];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan = YES;
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        [self addGestureRecognizer:tapRecognizer];
        
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [self addGestureRecognizer:pressRecognizer];
        
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        self.moveRecognizer.delegate = self;
        self.moveRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:self.moveRecognizer];
    }
    return self;
}

- (void)strokeLine:(BNRLine *)line
{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

- (void)drawRect:(CGRect)rect
{
    //draw finished lines in black
    [[UIColor blackColor] set];
    for (BNRLine *line in self.finishedLines) {
        [self strokeLine:line];
    }
    
    [[UIColor redColor] set];
    for (NSValue *key in self.linesInProgress) {
        [self strokeLine:self.linesInProgress[key]];
    }
    
    if (self.selectedLine) {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
    
    float f = 0.0;
    for (int i = 0; i < 1000000; i++) {
        f = f + sin(sin(sin(time(NULL) + i)));
    }
    NSLog(@"f = %f", f);
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        CGPoint location = [t locationInView:self];
        BNRLine *line = [[BNRLine alloc] init];
        line.begin = location;
        line.end = location;
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        self.linesInProgress[key] = line;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t  in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];
        
        line.end = [t locationInView:self];
    }
    
    [self setNeedsDisplay];
}


- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];
        
        if (line) {
            [self.finishedLines addObject:line];
            [self.linesInProgress removeObjectForKey:key];
        }
        
        
    }
    
    [self setNeedsDisplay];
}

- (void)doubleTap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized Double Tap");
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

- (BNRLine *)lineAtPoint:(CGPoint)p
{
    //find a line close to p
    for (BNRLine *l in self.finishedLines) {
        CGPoint start = l.begin;
        CGPoint end   = l.end;
        
        //check a few points on the line
        for (float t = 0.0; t <= 1.0; t += 0.05) {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            
            //if a tapped point is within 20 points, let's return this line
            if (hypot(x - p.x, y - p.y) < 20) {
                return l;
            }
        }
    }
    
    //if nothing is close enough to the tapped point, then we did not select a line
    return nil;
}

- (void)tap:(UITapGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");
    
    CGPoint point = [gr locationInView:self];
    self.selectedLine = [self lineAtPoint:point];
    
    if (self.selectedLine) {
        //make ourselves the target of menu item action message
        [self becomeFirstResponder];
        
        //grab the menu conroller
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        //create a new 'delete' UIMenuItem
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        
        menu.menuItems = @[deleteItem];
        
        //tell the menu where it should come from and show it
        [menu setTargetRect:CGRectMake(point.x, point.x, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    }else{
        //hide the menu if no line is selected
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)deleteLine:(id)sender
{
    //remove the selected line from the list of _finishedLines
    [self.finishedLines removeObject:self.selectedLine];
    
    //redraw everything
    [self setNeedsDisplay];
}

- (void)longPress:(UIGestureRecognizer *)gr
{
    NSLog(@"LongPress");
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        }
    }else if (gr.state == UIGestureRecognizerStateEnded){
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.moveRecognizer) {
        return YES;
    }
    return NO;
}

- (void)moveLine:(UIPanGestureRecognizer *)gr
{
    //if we have not selected a line, we do not do anything here
    if (!self.selectedLine) {
        return;
    }
    //if move is far away from selected line then it should be drawing new line
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gr locationInView:self];
        if(self.selectedLine != [self lineAtPoint:point]){
            //closes line is different than selected. stop move
            self.selectedLine = nil;
            //hide the menu if no line is selected
            [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
            return;
        }
    }
    //when the pan recognizer changes its position
    if (gr.state == UIGestureRecognizerStateChanged) {
        //how far has the pan moved?
        CGPoint translation = [gr translationInView:self];
        
        //add a translation to the current beginning and end points of the line
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;
        
        //set the new beginning and end points of the line
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
        
        //redraw the screen
        [self setNeedsDisplay];
        
        //make translation 0,0 again
        [gr setTranslation:CGPointZero inView:self];
        
        [self.linesInProgress removeAllObjects];
    }
}

@end
