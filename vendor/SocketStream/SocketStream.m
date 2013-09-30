//
//  SocketStream.m
//  port
//
//  Created by Kelly Martin on 4/8/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import "SocketStream.h"
#include <CFNetwork/CFSocketStream.h>

@implementation SocketStream

@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }

    return self;
}
-(id)initWithHost:(NSString *)hostString port:(int)port {
  self = [super init];
  if (self) {
    self.host = [NSHost hostWithName:hostString];
    self.port = port;
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
- (bool)open:(NSStream <NSStreamDelegate>*)inputDelegate output:(NSStream <NSStreamDelegate>*)outputDelegate {

    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;

    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)self.host.name, self.port, &readStream, &writeStream);

    self.inputStream = (NSInputStream *)readStream;
    self.outputStream = (NSOutputStream *)writeStream;

    delegate = inputDelegate;

    [self.inputStream setDelegate: inputDelegate];
    [self.outputStream setDelegate: outputDelegate];

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
    [delegate handleInput: eventCode];
  } else {
    [delegate handleOutput: eventCode];
  }
}
- (void) handleInputAndTriggerAction
{
  if ([[self inputStream] hasBytesAvailable]) {
    int len;
    uint8_t buf[2048];
    len = [[self inputStream] read: buf maxLength: 2048];
    if (len > 0) {
      NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
      NSString *data = [[NSString alloc] initWithBytes: buf length:len encoding:NSUTF8StringEncoding];
      NSArray *parts = [data componentsSeparatedByString: @":"];
      [delegate triggerAction: parts];
      [data release];
      [innerPool release];
    }
  }
  //return @"";

}
- (void) sendPing {
  [self sendData: @"\n" ];
}
- (void) sendData: (NSString *)data
{
  if ([self outputStream]) {
      NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
      unsigned char *cdata;
      cdata = [data cStringUsingEncoding:NSASCIIStringEncoding];
    [[self outputStream] write: cdata maxLength:[data length]];
      [innerPool release];
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
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    [self.inputStream close];
    [self.outputStream close];

    [self.inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSEventTrackingRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSEventTrackingRunLoopMode];
}

@end

