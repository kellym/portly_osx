//
//  Token.h
//  port
//
//  Created by Kelly Martin on 5/13/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Token : NSManagedObject

@property (nonatomic, retain) NSNumber * allow_remote;
@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSString * suffix;

@end
