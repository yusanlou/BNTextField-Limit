//
//  UITextField+Limit.h
//  PickWord
//
//  Created by BackNotGod on 2018/9/6.
//  Copyright © 2018年 Mubai. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL(^BNConditionBlock)(NSString* inputStr);
@interface UITextField (Limit)

- (void)limitNums:(NSInteger)num action:(void(^)(void))action;

- (void)limitCondition:(BNConditionBlock)condition action:(void (^)(void))action;

- (void)setPlaceholder:(NSString *)placeholder color:(UIColor*)color font:(UIFont*)font;

@end
