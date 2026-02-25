#include "GACommon.h"

#if IS_IOS

#import "GADeviceiOS.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <sys/sysctl.h>

std::string getiOSVersion()
{
    NSString* v = [[UIDevice currentDevice] systemVersion];
    return [v UTF8String];
}

static SCNetworkReachabilityRef createReachabilityRef()
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(
        kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);

    return reachabilityRef;
}

std::string getiOSConnectionType()
{
    static SCNetworkReachabilityRef reachabilityRef = createReachabilityRef();

    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityGetFlags(reachabilityRef, &flags);

    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        return gameanalytics::CONNECTION_OFFLINE;
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0)
    {
        return gameanalytics::CONNECTION_WWAN;
    }

    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        return gameanalytics::CONNECTION_WIFI;
    }

    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            return gameanalytics::CONNECTION_WIFI;
        }
    }

    return gameanalytics::CONNECTION_LAN;
}

std::string getiOSDeviceModel()
{
    size_t len = 0;
    sysctlbyname("hw.machine", NULL, &len, NULL, 0);

    const size_t buffSize = len + 1;
    std::unique_ptr<char[]> buffer = std::make_unique<char[]>(buffSize);
    std::memset(buffer.get(), 0, buffSize);

    sysctlbyname("hw.machine", buffer.get(), &len, NULL, 0);

    return std::string(buffer.get());
}

int getiOSNumCpuCores()
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    return (int)info.activeProcessorCount;
}

int64_t getiOSTotalDeviceMemory()
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    return (uint64_t)info.physicalMemory;
}

std::string getiOSPersistentPath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *gaPath = [documentsDirectory stringByAppendingPathComponent:@"GameAnalytics"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:gaPath])
    {
        [fileManager createDirectoryAtPath:gaPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }

    return [gaPath UTF8String];
}

#endif
