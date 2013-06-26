//
//  SocketStream.h
//  port
//
//  Created by Kelly Martin on 4/8/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>

@interface SocketStream : NSStream <NSStreamDelegate>
-(id) init;
-(id) initWithHost:(NSString *)hostString port:(int)port;
-(id) initWithAddress:(NSString *)addressString port:(int)port;
- (void)open:(NSStream <NSStreamDelegate>*)inputDelegate output:(NSStream <NSStreamDelegate>*)outputDelegate;
-(void) close;
- (void)readBytes;
-(void) handleOutputStreamEvent:(NSStreamEvent)eventCode;
- (void)handleInputStreamEvent:(NSStreamEvent)eventCode;
- (void)keepOutputAlive;
- (void)keepInputAlive;

@property (retain) NSInputStream * inputStream;
@property (retain) NSOutputStream * outputStream;
@property (retain)   NSHost * host;
@property int port;
@property (nonatomic, retain) NSDictionary * settings;

@end
