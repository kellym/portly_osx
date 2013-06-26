@interface Sock : NSObject
-(id)init;
+(bool)connect:(const char *)hostname port:(int)port;
@end
