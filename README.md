

# BNTextField-Limit

限制输入字数

# Installation with CocoaPods
  edit your podfile
 > pod 'BNTextField-Limit'

end

# Usage

## Creat Textfield 

`    UITextField *testField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];`

## Set limit 

```objective-c
[testField limitCondition:^BOOL(NSString *inputStr){
        return ![testField.text isEqualToString:@"111"];
    } action:^{
        NSLog(@"limit action");
}];
```

Or 

```objective-c
[testField limitNums:3 action:^{
	NSLog(@"num limit action");
}];
```

# ⚠️WARNNING

**if you want to set  the delegate , just ... set it before setting the limit.**

