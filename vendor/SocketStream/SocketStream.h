//
//  SocketStream.h
//  port
//
//  Created by Kelly Martin on 4/8/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>

@interface SocketStream : NSStream <NSStreamDelegate> {
  NSResponder *delegate;
}
-(id) init;
-(id) initWithHost:(NSString *)hostString port:(int)port;
-(id) initWithAddress:(NSString *)addressString port:(int)port;
- (bool)open:(NSStream <NSStreamDelegate>*)inputDelegate output:(NSStream <NSStreamDelegate>*)outputDelegate;
-(void) close;
- (bool)keepOutputAlive;
- (bool)keepInputAlive;
- (NSString *)handleInput;
- (void) sendData: (NSString *)data;

@property (nonatomic, retain) NSInputStream * inputStream;
@property (nonatomic, retain) NSOutputStream * outputStream;
@property (nonatomic, weak) NSResponder *delegate;
@property (retain)   NSHost * host;
@property int port;
@property (nonatomic, retain) NSDictionary * settings;

@end
