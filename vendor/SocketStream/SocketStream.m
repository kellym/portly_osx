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

    NSLog(self.host.name);
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)self.host.name, self.port, &readStream, &writeStream);

    self.inputStream = (NSInputStream *)readStream;
    self.outputStream = (NSOutputStream *)writeStream;

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

    NSLog(@"SSL Settings enabled.");
    if(self.inputStream.streamStatus == NSStreamStatusOpening ) {
      NSLog(@"Opening connection.");
      return true;
    } else {
      return false;
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

