//
//  SocketStream.h
//  port
//
//  Created by Kelly Martin on 4/8/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import "Sock.h"

@interface Stream

-(void) handleInput:(NSStreamEvent)aStream;
-(void) handleOutput:(NSStreamEvent)aStream;

@end

@interface SocketStream : NSStream <NSStreamDelegate> {
  Stream *delegate;
  Sock *sock;
  BOOL isInitialized;
  NSTimer *timer;
  dispatch_queue_t queue;
  int timeout;
}
-(id) init;
-(id) initWithHost:(NSString *)hostString port:(int)port delegate:(Stream *)aDelegate;
-(id) initWithAddress:(NSString *)addressString port:(int)port;
- (bool)open;
-(void) close;
- (bool)keepOutputAlive;
- (bool)keepInputAlive;
- (NSString *)handleInput;
- (void) sendData: (NSString *)data;

@property (nonatomic, retain) NSInputStream * inputStream;
@property (nonatomic, retain) NSOutputStream * outputStream;
@property (nonatomic, weak) Stream *delegate;
@property (retain)   NSHost * host;
@property int port;
@property (nonatomic, retain) Sock * sock;
@property (nonatomic, retain) NSDictionary * settings;

@end
