//
//  URLValidator.m
//  port
//
//  Created by Kelly Martin on 5/5/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import "URLValidator.h"

@implementation URLValidator

+(void) send:(NSString *)request delegate:(NSResponder *)delegate
{
  NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString: request]];
  [req setHTTPMethod: @"GET"];
  [req setValue: @"application/html" forHTTPHeaderField: @"content-type"];
  [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
      [delegate handleValidationResponse: response data:data error:error];
  }];
  [req release];

}
@end

