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
- (void)open:(NSStream <NSStreamDelegate>*)inputDelegate output:(NSStream <NSStreamDelegate>*)outputDelegate {

    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;

    NSLog(self.host.name);
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)self.host.name, self.port, &readStream, &writeStream);

    self.inputStream = (NSInputStream *)readStream;
    self.outputStream = (NSOutputStream *)writeStream;

    [self.inputStream setDelegate: self];
    [self.outputStream setDelegate: outputDelegate];

    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                        forMode:NSDefaultRunLoopMode];

    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                        forMode:NSEventTrackingRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
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
    if(self.inputStream.streamStatus ==NSStreamStatusOpening ) {
      NSLog(@"Opening connection.");
    }
}

// Both streams call this when events happen
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
  NSLog(@"DATA RECEIVED");
    if (theStream == self.inputStream) {
        [self handleInputStreamEvent:streamEvent];
    } else if (theStream == self.outputStream) {
        [self handleOutputStreamEvent:streamEvent];
    }
}
- (void)handleInputStreamEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
            //if ([inputStream hasBytesAvailable]) {
            //  [self readBytes];
            //}
            //NSInteger       bytesRead;
            //static uint8_t  buffer[kBufferSize];
            /*
            if (firstPacket)
            {
                firstPacket = NO;*/
            /*    uint64_t lengthIn;
                bytesRead = [inputStream read:(unsigned char *)&lengthIn maxLength:sizeof(uint64_t)];
                if (bytesRead != sizeof(uint64_t))
                    NSLog(@"zoiks!");
                currentTargetLength = lengthIn;*/
            //}
            /*uint8_t buf[1024];
            NSInteger len;
            while((len = [(NSInputStream *)inputStream read:buf maxLength:1024])) {
                [data appendBytes:(const void *)buf length:len];
                // bytesRead is an instance variable of type NSNumber.
                //bytesRead = bytesRead + len;
            }*/
            NSLog(@"data available from input."); //[self readBytes];
            //NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            //NSLog(@"my ns string = %@", string);
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream Opened Successfully"); //[self readBytes];
            // Do Something
            break;
        default:
        case NSStreamEventErrorOccurred:
            NSLog(@"An error occurred on the input stream.");
            break;
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

- (void)readBytes {
    //uint8_t buf[1024];
    //NSInteger len;
   // while((len = [(NSInputStream *)inputStream read:buf maxLength:1024])) {
    //    [data appendBytes:(const void *)buf length:len];
        // bytesRead is an instance variable of type NSNumber.
        //bytesRead = bytesRead + len;
   // }
}

- (void)handleOutputStreamEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
            NSLog(@"data available to output."); //[self readBytes];
            break;
        case NSStreamEventOpenCompleted:
            // Do Something
            break;
        default:
        case NSStreamEventErrorOccurred:
            NSLog(@"An error occurred on the output stream.");
            break;
    }
}

-(void)close {
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    [self.inputStream close];
    [self.outputStream close];

    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSEventTrackingRunLoopMode];

    //self.inputStream = nil;
    //self.outputStream = nil;

}

@end

