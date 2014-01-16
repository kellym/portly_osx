//
//  Computer.m
//  port
//
//  Created by Kelly Martin on 5/5/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import "Computer.h"
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation Computer

+(NSString *) machineModel
{
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    
    if (len)
    {
        char *model = malloc(len*sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    
    return @"Apple Computer"; //incase model name can't be read
}
@end
