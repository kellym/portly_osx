#import "Sock.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

@implementation Sock
-(id)init {
  self = [super init];
  return self;
}
+(bool)connect:(const char *)hostname port:(int)port {

   struct addrinfo hints, *res, *res0;
   struct sockaddr_in *ipv4;
   struct sockaddr_in6 *ipv6;
   int error;
   int s;
   const char *cause = NULL;

   memset(&hints, 0, sizeof(hints));
   hints.ai_family = AF_UNSPEC;
   hints.ai_socktype = SOCK_STREAM;
   error = getaddrinfo(hostname, nil, &hints, &res0);
   if (error) {
           /*NOTREACHED*/
   }
   s = -1;
   for (res = res0; res; res = res->ai_next) {
           s = socket(res->ai_family, res->ai_socktype,
               res->ai_protocol);
           if (s < 0) {
                   cause = "socket";
                   continue;
           }
            //setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, time, sizeof(time));
            //setsockopt(s, SOL_SOCKET, SO_SNDTIMEO, time, sizeof(time));
           if (res->ai_family == AF_INET) {
             struct sockaddr_in *ipv4 = (struct sockaddr_in *)res->ai_addr;
             ipv4->sin_port = htons(port);
             if (connect(s, (struct sockaddr *)ipv4, res->ai_addrlen) < 0) {
                     cause = "connect";
                     close(s);
                     s = -1;
                     continue;
             }
           } else{
             struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)res->ai_addr;
             ipv6->sin6_port = htons(port);
             if (connect(s, (struct sockaddr *)ipv6, res->ai_addrlen) < 0) {
                     cause = "connect";
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
   if (error || s < 0) {
     return false;
   } else {
     close(s);
     return true;
   }
}
@end
