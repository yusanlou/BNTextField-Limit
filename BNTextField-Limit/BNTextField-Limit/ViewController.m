//
//  ViewController.m
//  BNTextField-Limit
//
//  Created by BackNotGod on 2018/9/6.
//  Copyright © 2018年 Mubai. All rights reserved.
//

#import "ViewController.h"
#import "UITextField+Limit.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UITextField *testField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    testField.center = self.view.center;
    testField.backgroundColor = [UIColor grayColor];
    [self.view addSubview:testField];
    
    [testField limitCondition:^BOOL{
        return ![testField.text isEqualToString:@"111"];
    } action:^{
        NSLog(@"limit action");
    }];
    
    [testField limitNums:3 action:^{
        NSLog(@"num limit action");
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
