//
//  SocketStream.m
//  port
//
//  Created by Kelly Martin on 4/8/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import "SocketStream.h"
#import "Sock.h"
#include <CFNetwork/CFSocketStream.h>

@implementation SocketStream

@synthesize delegate;
@synthesize sock;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }

    return self;
}
-(id)initWithHost:(NSString *)hostString port:(int)port delegate:(Stream *)aDelegate {
  self = [super init];
  if (self) {
    self.host = [NSHost hostWithName:hostString];
    self.port = port;
    self.delegate = aDelegate;
    self.sock = [[Sock alloc] initWithHost: hostString port: port];
    isInitialized = NO;
    timeout = 0;
    queue = dispatch_queue_create("com.fully.portly.stream", 0);
  }
  return self;
}
-(id)initWithAddress:(NSString *)addressString port:(int)port {
  self = [super init];
  if (self) {
    self.host = [NSHost hostWithAddress:addressString];
    self.port = port;
  }
  return self;
}

-(void)start
{
  [self open];
  timer = [NSTimer scheduledTimerWithTimeInterval: 5.0f target: self selector:@selector(queuePing) userInfo: nil repeats: YES];
}

-(void) queuePing
{
  //NSLog(@"Ping queued but not yet sent.");
  if([self outputStream]) {
    [self sendPing];
    timeout += 1;
    if (timeout > 2) {
      NSLog(@"Timeout expired. Retrying.");
      [self retrySocket];
    }
  }
}

-(BOOL) isInitialized
{
  return isInitialized;
}

- (bool)open
{

    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;

    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)self.host.name, self.port, &readStream, &writeStream);

    self.inputStream = (NSInputStream *)readStream;
    self.outputStream = (NSOutputStream *)writeStream;

    //delegate = inputDelegate;

    [self.inputStream setDelegate: self];
    [self.outputStream setDelegate: self];

    [self.inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                        forMode:NSDefaultRunLoopMode];

    [self.inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                        forMode:NSEventTrackingRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop]
                        forMode:NSEventTrackingRunLoopMode];

    [self.inputStream open];
    [self.outputStream open];

    [self.inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL
                   forKey:NSStreamSocketSecurityLevelKey];
    [self.outputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL
                    forKey:NSStreamSocketSecurityLevelKey];

    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"app.getportly.com",kCFStreamSSLPeerName,
                              nil];

    CFReadStreamSetProperty((CFReadStreamRef)self.inputStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);
    CFWriteStreamSetProperty((CFWriteStreamRef)self.outputStream, kCFStreamPropertySSLSettings, (CFTypeRef)settings);

    //CFRelease(readStream);
    //CFRelease(readStream);
    [settings release];
    if(self.inputStream.streamStatus == NSStreamStatusOpening ) {
      NSLog(@"Opening connection.");
      return true;
    } else {
      return false;
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
  if(aStream == [self inputStream]) {
    //NSLog(@"HANDLING INPUT");
    timeout = 0;
    switch(eventCode) {
      //case NSStreamEventOpenCompleted:
      //  [[self delegate] setup_input];
      //  break;
      case NSStreamEventHasBytesAvailable:
        //[[self delegate] resetTimeout];
        [self handleInputAndTriggerAction];
        break;
      case NSStreamEventErrorOccurred:
        //NSLog(@"End on output.");
      case NSStreamEventEndEncountered:
        //NSLog(@"Error on output.");
        [self retrySocket];
        break;
    }
  } else {
    //NSLog(@"HANDLING OUTPUT");
    switch(eventCode) {
      //case NSStreamEventOpenCompleted:
      //  [[self delegate] setup_output];
      //  break;
      case NSStreamEventHasSpaceAvailable:
        if (isInitialized == NO) {
          [self keepOutputAlive];
          [[self delegate] publish_as_online];
          isInitialized = YES;
        }
        break;
      case NSStreamEventErrorOccurred:
        //NSLog(@"Error on input.");
        [self retrySocket];
        break;
    }

  }
}
- (void) retrySocket
{
  if ([self inputStream] && [self outputStream]) {
    [self close];
    dispatch_async(queue, ^{
      while([[self sock] connect] != true) {
        [NSThread sleepForTimeInterval: 1.0f];
      }
      [self start];
    });
  }

}
- (void) handleInputAndTriggerAction
{
  if ([[self inputStream] hasBytesAvailable]) {
    int len;
    uint8_t buf[2048];
    len = [[self inputStream] read: buf maxLength: 2048];
    if (len > 0) {
      //NSLog(@"Handling the input.");
      NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
      NSString *unformatted_data = [[NSString alloc] initWithBytes: buf length:len encoding:NSUTF8StringEncoding];
      NSString *data = [unformatted_data stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      [unformatted_data release];
      NSArray *parts;
      int location;
      location = [data rangeOfString:@":"].location;
      if (location != -1) {
        parts = [ [NSArray alloc] initWithObjects: [data substringToIndex:location], [data substringFromIndex: location + 1], nil];
      } else {
        parts = [ [NSArray alloc] initWithObjects: data, nil];
      }
      //NSArray *parts = [data componentsSeparatedByString: @":"];
      [delegate triggerAction: parts];
      //[data release];
      [innerPool release];
    }
  }
  //return @"";

}
- (void) sendPing {
  NSLog(@"Sending ping.");
  [self sendData: @"\n" ];
}
- (void) sendData: (NSString *)data
{
  if ([self outputStream]) {
    //NSLog(data);
//      NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
      unsigned char *cdata;
      NSString *data_copy = [data copy];
      cdata = [data_copy cStringUsingEncoding:NSASCIIStringEncoding];
    [[self outputStream] write: cdata maxLength:[data length]];
    [data_copy release];
//      [innerPool release];
  }
}

- (bool)keepInputAlive {

    CFDataRef socketData = CFReadStreamCopyProperty((CFReadStreamRef)(self.inputStream), kCFStreamPropertySocketNativeHandle);
    CFSocketNativeHandle socket;
    CFDataGetBytes(socketData, CFRangeMake(0, sizeof(CFSocketNativeHandle)), (UInt8 *)&socket);
    //CFRelease(socketData);

    int on = 1;
    if (setsockopt(socket, SOL_SOCKET, SO_KEEPALIVE, &on, sizeof(on)) == -1) {
        NSLog(@"setsockopt failed: %s", strerror(errno));
        return false;
    }
    return true;

}
- (bool)keepOutputAlive {

    CFDataRef socketData = CFReadStreamCopyProperty((CFReadStreamRef)(self.outputStream), kCFStreamPropertySocketNativeHandle);
    CFSocketNativeHandle socket;
    CFDataGetBytes(socketData, CFRangeMake(0, sizeof(CFSocketNativeHandle)), (UInt8 *)&socket);
    //CFRelease(socketData);

    int on = 1;
    if (setsockopt(socket, SOL_SOCKET, SO_KEEPALIVE, &on, sizeof(on)) == -1) {
        NSLog(@"setsockopt failed: %s", strerror(errno));
        return false;
    }
    return true;
}

-(void)close {
  isInitialized = NO;
    [self.inputStream close];
    [self.outputStream close];

    // CFRunLoopSourceInvalidate
    //[self.inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    //[self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    //[self.inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSEventTrackingRunLoopMode];
    //[self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSEventTrackingRunLoopMode];

    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    self.inputStream = nil;
    self.outputStream = nil;
}

@end

