//
//  ViewController.m
//  BNTextField-Limit
//
//  Created by BackNotGod on 2018/9/6.
//  Copyright © 2018年 Mubai. All rights reserved.
//

#import "ViewController.h"
#import "UITextField+Limit.h"
@interface ViewController ()<UITextFieldDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UITextField *testField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    testField.center = self.view.center;
    testField.backgroundColor = [UIColor grayColor];
    testField.delegate = self;
    [self.view addSubview:testField];
    
    __weak typeof(self) weakself = self;
    __weak typeof(testField) weaktext = testField;
    [testField limitCondition:^BOOL(NSString *inputStr){
        return ![weaktext.text isEqualToString:@"12321321321"];
    } action:^{
        NSLog(@"limit action");
        [weakself dismissViewControllerAnimated:true completion:nil];
    }];
    
    [testField limitNums:4 action:^{
        NSLog(@"num limit action");
        [weakself presentViewController:[ViewController new] animated:true completion:nil];
    }];
    
    [testField observeValueWithCondition:^BOOL(NSString *inputStr) {
        return weaktext.text.length%2 == 1;
    } action:^{
        NSLog(@"vlaue is conformed");
    }];
    
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
