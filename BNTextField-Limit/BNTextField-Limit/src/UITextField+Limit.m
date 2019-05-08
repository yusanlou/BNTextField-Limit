//
//  UITextField+Limit.m
//  PickWord
//
//  Created by BackNotGod on 2018/9/6.
//  Copyright © 2018年 Mubai. All rights reserved.
//

#import "UITextField+Limit.h"
#import <pthread/pthread.h>
#import <objc/runtime.h>

@interface _LimitInfo : NSObject

@property(nonatomic,weak)id<UITextFieldDelegate> pinocchio;

@property(nonatomic,assign)NSInteger num;
@property(nonatomic,copy)void (^action)(void);

@property(nonatomic,copy)BNConditionBlock condition;
@property(nonatomic,copy)void (^conditionAction)(void);

@property(nonatomic,copy)BNConditionBlock response;
@property(nonatomic,copy)void (^responseAction)(void);


@end

@interface UITextFieldDelegateManager : NSObject<UITextFieldDelegate> {
    NSMapTable<id,_LimitInfo *> *_infos;
    pthread_mutex_t _mutex;
}

+ (instancetype)sharedInstance;

- (void)addLimitNums:(NSInteger)num key:(id)key target:(id<UITextFieldDelegate>)target action:(void(^)(void))action;

- (void)addLimitCondition:(BNConditionBlock)condition key:(id)key target:(id<UITextFieldDelegate>)target action:(void(^)(void))action;

- (void)observeValueWithCondition:(BNConditionBlock)condition key:(id)key target:(id<UITextFieldDelegate>)target action:(void (^)(void))action;

- (void)removeLimitForKey:(id)key;

@end

@implementation UITextField (Limit)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(removeFromSuperview);
        SEL swizzledSelector = @selector(bn_removeFromSuperview);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)bn_removeFromSuperview{
    [UITextFieldDelegateManager.sharedInstance removeLimitForKey:self];
    return [self bn_removeFromSuperview];
}

- (void)limitNums:(NSInteger)num action:(void (^)(void))action{
    
    [[UITextFieldDelegateManager sharedInstance] addLimitNums:num
                                                          key:self
                                                       target:self.delegate
                                                       action:action];
    self.delegate =  UITextFieldDelegateManager.sharedInstance;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self addTarget:UITextFieldDelegateManager.sharedInstance action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
#pragma clang diagnostic pop

}

- (void)limitCondition:(BNConditionBlock)condition action:(void (^)(void))action{
    [[UITextFieldDelegateManager sharedInstance] addLimitCondition:condition
                                                               key:self
                                                            target:self.delegate
                                                            action:action];
    self.delegate =  UITextFieldDelegateManager.sharedInstance;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self addTarget:UITextFieldDelegateManager.sharedInstance action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];
#pragma clang diagnostic pop
}

- (void)observeValueWithCondition:(BNConditionBlock)condition action:(void(^)(void))action{
    [[UITextFieldDelegateManager sharedInstance] observeValueWithCondition:condition
                                                                       key:self
                                                                    target:self.delegate
                                                                    action:action];
}


- (void)setPlaceholder:(NSString *)placeholder color:(UIColor *)color font:(UIFont *)font{
    NSMutableAttributedString *placeholderAttstr = [[NSMutableAttributedString alloc] initWithString:placeholder];
    
    if (color) {
        [placeholderAttstr addAttribute:NSForegroundColorAttributeName
                                  value:color
                                  range:NSMakeRange(0, placeholder.length)];

    }
    
    if (font) {
        [placeholderAttstr addAttribute:NSFontAttributeName
                                  value:font
                                  range:NSMakeRange(0, placeholder.length)];
    }
    self.attributedPlaceholder = placeholderAttstr;
}

@end


@implementation UITextFieldDelegateManager

+ (instancetype)sharedInstance{
    static dispatch_once_t __singletonToken;
    static id __singleton__;
    dispatch_once( &__singletonToken, ^{ __singleton__ = [[self alloc] init]; } );
    return __singleton__;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_mutex, NULL);
        NSPointerFunctionsOptions keyOptions =  NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality;
        _infos = [[NSMapTable alloc] initWithKeyOptions:keyOptions valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality capacity:0];
    }
    return self;
}

- (void)addLimitNums:(NSInteger)num key:(id)key target:(id<UITextFieldDelegate>)target action:(void(^)(void))action{
    [self addLimitWithDisturb:YES andCondition:nil andNums:num key:key target:target action:action];
}

- (void)addLimitCondition:(BNConditionBlock)condition key:(id)key target:(id<UITextFieldDelegate>)target action:(void (^)(void))action{
    [self addLimitWithDisturb:YES andCondition:condition andNums:0 key:key target:target action:action];
}

- (void)observeValueWithCondition:(BNConditionBlock)condition key:(id)key target:(id<UITextFieldDelegate>)target action:(void (^)(void))action{
    [self addLimitWithDisturb:NO andCondition:condition andNums:0 key:key target:target action:action];
}

- (void)addLimitWithDisturb:(BOOL)disturb andCondition:(BNConditionBlock)condition andNums:(NSInteger)num key:(id)key target:(id<UITextFieldDelegate>)target action:(void (^)(void))action{
    
    if (!key) {
        return;
    }
    
    pthread_mutex_lock(&_mutex);
    _LimitInfo *info = [_infos objectForKey:key];
    
    if (!info) {
        info = [_LimitInfo new];
        info.pinocchio = target;
    }
    if (disturb) {
        if (condition) {
            info.condition = condition;
            [info setConditionAction:action];
        }
        if (num != 0) {
            info.num = num;
            [info setAction:action];
        }
    }else{
        info.response = condition;
        [info setResponseAction:action];
    }
    
    [_infos setObject:info forKey:key];
    pthread_mutex_unlock(&_mutex);
    
}

- (void)removeLimitForKey:(id)key{
    if (!key) {
        return;
    }
    pthread_mutex_lock(&_mutex);
    _LimitInfo* info = [_infos objectForKey:key];
    ((UITextField*)key).delegate = info.pinocchio;
    [_infos removeObjectForKey:key];
    pthread_mutex_unlock(&_mutex);
}


- (_LimitInfo*)safeReadForKey:(id)key{
    if (!key) {
        return nil;
    }
    pthread_mutex_lock(&_mutex);
    _LimitInfo *info = [_infos objectForKey:key];
    pthread_mutex_unlock(&_mutex);
    return info;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_mutex);
}

- (void)textFieldDidChanged:(UITextField *)textField {
    
    UITextRange *selectedRange = textField.markedTextRange;
    BOOL checkPosition = [textField positionFromPosition:selectedRange.start offset:0];
    
    if (checkPosition) {
        return;
    }
    _LimitInfo *info = [self safeReadForKey:textField];
    if (info.num != 0) {
        if (info && textField.text.length >= info.num > 0) {
            textField.text = [textField.text substringToIndex:info.num];
            info.action();
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    // check markedTextRange
    UITextRange *selectedRange = textField.markedTextRange;
    BOOL checkPosition = [textField positionFromPosition:selectedRange.start offset:0];
    if (checkPosition) {
        return YES;
    }
    BOOL checkInLimit = NO;
    
    _LimitInfo *info = [self safeReadForKey:textField];
    
    if (info.response && !info.response(string) && string.length > 0) {
        info.responseAction();
    }
    
    if (info.condition && !info.condition(string) && string.length > 0) {
        info.conditionAction();
        checkInLimit = YES;
    }
    
    if (info.num != 0) {
        if (info && textField.text.length == info.num && string.length > 0) {
            info.action();
            checkInLimit = YES;
        }
    }
    
    if (checkInLimit) {
        return NO;
    }
    
    if (!info.pinocchio) {
        return YES;
    }
    
    if (![info.pinocchio respondsToSelector:_cmd]) {
        return YES;
    }
    
    return [info.pinocchio textField:textField shouldChangeCharactersInRange:range replacementString:string];
}



- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _LimitInfo *info = [self safeReadForKey:textField];
    if (!info.pinocchio) {
        return YES;
    }
    if ([info.pinocchio respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        return [info.pinocchio textFieldShouldBeginEditing:textField];
    }
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    _LimitInfo *info = [self safeReadForKey:textField];
    if ([info.pinocchio respondsToSelector:_cmd]) {
        return [info.pinocchio textFieldDidBeginEditing:textField];
    }
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    _LimitInfo *info = [self safeReadForKey:textField];
    if (!info.pinocchio || ![info.pinocchio respondsToSelector:_cmd]) {
        return YES;
    }
    return [info.pinocchio textFieldShouldEndEditing:textField];
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    _LimitInfo *info = [self safeReadForKey:textField];
    if ([info.pinocchio respondsToSelector:_cmd]) {
        return [info.pinocchio textFieldDidEndEditing:textField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason  API_AVAILABLE(ios(10.0)){
    _LimitInfo *info = [self safeReadForKey:textField];
    if ([info.pinocchio respondsToSelector:_cmd]) {
        return [info.pinocchio textFieldDidEndEditing:textField reason:reason];
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField{
    _LimitInfo *info = [self safeReadForKey:textField];
    if (!info.pinocchio || ![info.pinocchio respondsToSelector:_cmd]) {
        return YES;
    }
    return [info.pinocchio textFieldShouldClear:textField];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    _LimitInfo *info = [self safeReadForKey:textField];
    if (!info.pinocchio || ![info.pinocchio respondsToSelector:_cmd]) {
        return YES;
    }
    return [info.pinocchio textFieldShouldReturn:textField];
}


@end

@implementation _LimitInfo


@end
