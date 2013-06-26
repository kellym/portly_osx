//
//  Connector.h
//  port
//
//  Created by Kelly Martin on 3/26/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Connector : NSManagedObject

@property (nonatomic, retain) NSString * auth_type;
@property (nonatomic, retain) NSString * cname;
@property (nonatomic, retain) NSNumber * connector_id;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * start_on_boot;
@property (nonatomic, retain) NSString * subdomain;
@property (nonatomic, retain) NSNumber * reference;

@end
