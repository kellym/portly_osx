#import <Foundation/Foundation.h>
@interface ConnectorMonitor

-(BOOL) isRunning;
@end

@interface Sock : NSObject {
  NSString *host;
  int port;
  ConnectorMonitor *delegate;
}
-(id)init;
-(id)initWithHost:(NSString *)hostname port:(int)portnum;
-(bool)connect;
+(bool)connect:(NSString *)hostname port:(int)port;
-(void)receivedPing:(NSNotification *)notif;
//@property (nonatomic, retain) NSString *host;
@property (nonatomic, assign) int port;
@property (nonatomic, weak) ConnectorMonitor *delegate;
@end
