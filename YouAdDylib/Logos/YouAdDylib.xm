// See http://iphonedevwiki.net/index.php/Logos

#import <UIKit/UIKit.h>
#include <dlfcn.h>


NSString *_realBundleID = @"com.google.ios.youtube";
NSString *_bundleIDKey = @"CFBundleIdentifier";

BOOL IsCallFromSystem();
BOOL IsCallFromSystem() {
    NSArray *address = [NSThread callStackReturnAddresses];
    Dl_info info = {0};
    BOOL result = NO;
    if(dladdr((void *)[address[2] longLongValue], &info) == 0) {
        NSLog(@"IsCallFromSystem error");
    } else {
        NSString *path = [NSString stringWithUTF8String:info.dli_fname];
        //    NSLog(@"IsCallFromSystem path: %@", path);
        if (![path hasPrefix:NSBundle.mainBundle.bundlePath]) {
            result = YES;
        }
    }
    // NSLog(@"IsCallFromSystem result: %@", @(result));
    return result;
}


%hook NSBundle
- (NSString *)bundleIdentifier {
    if (IsCallFromSystem()) {
        return %orig;
    }
    return _realBundleID;
}

- (id)objectForInfoDictionaryKey:(NSString *)key {
    if (IsCallFromSystem()) {
        return %orig;
    }
    if ([key isKindOfClass:[NSString class]] && [key isEqualToString:_bundleIDKey]) {
        return _realBundleID;
    }
    return %orig;
}
- (NSDictionary *)infoDictionary {
    if (IsCallFromSystem()) {
        return  %orig;
    }
    NSDictionary *oriDict = %orig;
    NSMutableDictionary *info = [oriDict mutableCopy];
    info[_bundleIDKey] = _realBundleID;
    return info;
}
%end

// 后台播放

%hook YTSingleVideo
- (BOOL)isPlayableInBackground {
    return YES;
}
%end

%hook YTPlaybackData
- (BOOL)isPlayableInBackground {
    return YES;
}
%end

%hook YTPlaybackBackgroundTaskController
- (BOOL)isContentPlayableInBackground {
    return YES;
}

%end

%hook YTIPlayerResponse
- (BOOL)isPlayableInBackground {
    return YES;
}
%end

%hook YTIPlayabilityStatus
- (BOOL)isPlayableInBackground {
    return YES;
}

%end

%hook YTPlaybackBackgroundTaskController
- (void)setContentPlayableInBackground: (BOOL)arg {
    %orig(YES);
}
%end

// 去广告
@interface YTAdsControlFlowPlaybackCoordinator
- (void)adSlotDidComplete;
@end
%hook YTAdsControlFlowPlaybackCoordinator
- (void)startOverlay {
    [self adSlotDidComplete];
}
%end

%hook YTIPlayerResponse

%new
- (unsigned long long)playerAdsArray_Count {
    return 0;
}
%new
- (NSMutableArray *)playerAdsArray {
    return nil;
}

%end

/*
利用 ldid 将应用程序的 code sign 导出，可以查看对应entitlements信息
ldid -e Youtube.app/Youtube >> Youtube.xml
添加keychains，使账号登录信息保存
com.google.common.SSO
com.google.ios.youtube
参考资料：
使用 Xcode 调试第三方应用 https://iosre.com/t/xcode/8567
iOS 多开检测，反多开检测，反反多开检测 https://iosre.com/t/ios/11611
https://github.com/LHBosssss/Youtube-Tools
*/
