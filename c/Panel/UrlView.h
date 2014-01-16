//
//  URLView.h
//  Portly
//
//  Created by Kelly Martin on 9/15/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UrlView : NSTextField {
    NSTrackingArea *trackingArea;
    NSString * url;
    NSColor *color;
    NSColor *hoverColor;
    NSResponder *delegate;
}

@property (nonatomic, retain) NSColor * color;
@property (nonatomic, retain) NSColor * hoverColor;

- (id)initWithFrame:(NSRect)frame title:(NSString *)textValue url:(NSString *)urlValue delegate:(NSResponder *)delegateObject;
@end
