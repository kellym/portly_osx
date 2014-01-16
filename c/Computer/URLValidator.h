//
//  URLValidator.h
//  port
//
//  Created by Kelly Martin on 5/5/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLValidator : NSObject
+(void) send:(NSString *)request delegate:(NSResponder *)delegate;
@end

