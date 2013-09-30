#import "Sock.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

@implementation Sock

@synthesize port;
@synthesize delegate;

-(id)init {
  self = [super init];
  return self;
}

-(id) initWithHost:(NSString *)hostname port:(int)portnum {
  self = [super init];
  if (self) {
    //NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
    host = [hostname copy];
    port = portnum;
    //[innerPool release];
  }
  return self;
}

-(void) setHost:(NSString *)hostname {
  //NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
  [host release];
  host = [hostname copy];
  //[hostname getCString: host maxLength: ([hostname length]+1) encoding:NSASCIIStringEncoding];
  //strncpy(hostname, [hostname UTF8String], 32);
  //[innerPool release];
}

+(bool)connect:(NSString *)hostname port:(int)port {
  Sock *s = [[[self alloc] init] autorelease];
  [s setHost: hostname];
  [s setPort: port];
  return [s connect];
}
-(bool)connect {

   struct addrinfo hints, *res, *res0;
   struct sockaddr_in *ipv4;
   struct sockaddr_in6 *ipv6;
   struct timeval time;
   int error;
   int s;
   NSAutoreleasePool *innerPool = [NSAutoreleasePool new];

   memset(&time, 0, sizeof(time));
   memset(&hints, 0, sizeof(hints));
   time.tv_sec = 5;
   hints.ai_family = AF_UNSPEC;
   hints.ai_socktype = SOCK_STREAM;
   error = getaddrinfo((const char *)[host cStringUsingEncoding:NSASCIIStringEncoding], nil, &hints, &res0);
   if (error) {
     //freeaddrinfo(res0);
     [innerPool release];
     return false;
           /*NOTREACHED*/
   }
   s = -1;
   for (res = res0; res; res = res->ai_next) {
           s = socket(res->ai_family, res->ai_socktype,
               res->ai_protocol);
           if (s < 0) {
                   continue;
           }
           setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, (char *)&time, sizeof(time));
           setsockopt(s, SOL_SOCKET, SO_SNDTIMEO, (char *)&time, sizeof(time));
           if (res->ai_family == AF_INET) {
             struct sockaddr_in *ipv4 = (struct sockaddr_in *)res->ai_addr;
             ipv4->sin_port = htons((int)port);
             if (connect(s, (struct sockaddr *)ipv4, res->ai_addrlen) < 0) {
                     close(s);
                     s = -1;
                     continue;
             }
           } else{
             struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)res->ai_addr;
             ipv6->sin6_port = htons((int)port);
             if (connect(s, (struct sockaddr *)ipv6, res->ai_addrlen) < 0) {
                     close(s);
                     s = -1;
                     continue;
             }
           }


           break;  /* okay we got one */
   }
   if (s < 0) {
           /*NOTREACHED*/
   }
   freeaddrinfo(res0);
   [innerPool release];
   if (error || s < 0) {

     return false;
   } else {
     close(s);
     return true;
   }
}


-(void)receivedPing:(NSNotification *)notif
{
  NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
  NSFileHandle *fh = [notif object];
  NSString * data = [[NSString alloc] initWithData:[fh availableData] encoding:NSUTF8StringEncoding];
  [delegate resetTimeout];
  if ([data rangeOfString:@"TIMEOUT"].location == 0) {
    NSLog(@"DISCONNECT DUE TO FREE TIMEOUT");
    [delegate disableReconnect];
    [delegate disconnect: false];
  }
  if ([delegate isRunning]) {
    [fh waitForDataInBackgroundAndNotifyForModes:[[[NSArray alloc] initWithObjects: NSEventTrackingRunLoopMode, NSDefaultRunLoopMode, nil] autorelease]];
  }
  [data release];
  [innerPool release];
}
@end
