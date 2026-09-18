#pragma once

__attribute__((visibility("default")))
@interface UnityAppController : NSObject<UIApplicationDelegate> {}

@property(readonly, copy, nonatomic) UIView *rootView;

@end