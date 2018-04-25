//
//  ViewController.m
//  GDCDemo
//
//  Created by Xuzixiang on 2018/4/25.
//  Copyright © 2018年 frankxzx. All rights reserved.
//

#import "ViewController.h"

static void longRunning(NSString *c) {
    for (int i = 0; i < 200; i++) {
        NSLog(@"current thread %@, === %d === %@",[NSThread currentThread], i, c);
    }
}

@interface ViewController ()

@property(nonatomic, strong) dispatch_group_t g;
@property(nonatomic, strong) dispatch_queue_t q;
@property(nonatomic, strong) dispatch_queue_t lowQueue;
@property(nonatomic, strong) dispatch_queue_t highQueue;

@end

@implementation ViewController

- (void)tryNsOperationQueue {
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 1;
    QSOperation *operation1 = [[QSOperation alloc]init];
    QSOperation *operation2 = [[QSOperation alloc]init];
    QSOperation *operation3 = [[QSOperation alloc]init];
    QSOperation *operation4 = [[QSOperation alloc]init];
    
    [queue addOperation:operation1];
    [queue addOperation:operation2];
    [queue addOperation:operation3];
    [queue addOperation:operation4];
    
    [operation2 addDependency:operation1];
    [operation3 addDependency:operation2];
    [operation4 addDependency:operation3];
}

- (void)tryDelay {
    [self performSelector:@selector(greetWithString:) withObject:@"frankxzx" afterDelay:5];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self greetWithString:@"xuzixiang"];
    });
}

- (void)tryDispatchGroup {
    for (int i = 0; i < 4; i++) {
        dispatch_group_async(_g, _q, ^{
            longRunning(nil);
        });
    }
    //会阻塞线程
    dispatch_group_wait(_g, DISPATCH_TIME_FOREVER);
    //不会阻塞
    dispatch_group_notify(_g, dispatch_get_main_queue(), ^{
        NSLog(@"dispatch group finished");
    });
}

-(void)tryDiffPriortyQueueInGroup {
    for (int i = 0; i < 4; i++) {
        dispatch_group_async(_g, _lowQueue, ^{
            longRunning(@"low");
        });
    }
    
    for (int i = 0; i < 4; i++) {
        dispatch_group_async(_g, _highQueue, ^{
            longRunning(@"hight");
        });
    }
    dispatch_group_notify(_g, dispatch_get_main_queue(), ^{
        NSLog(@"tryDiffPriortyQueueInGroup finished");
    });
}

-(void) tryDispatchAply {
    dispatch_apply(10, _q, ^(size_t i) {
        longRunning(nil);
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _g = dispatch_group_create();
    _q = dispatch_queue_create("com.qs.group", DISPATCH_QUEUE_CONCURRENT);
    _lowQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    _highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    //延迟执行
    [self tryDelay];
    
    //操作队列
    //[self tryNsOperationQueue];
    
    //Dispatch Group 调度任务
    //[self tryDispatchGroup];
    
    //不同优先等级的 dispatch group 调度
    //[self tryDiffPriortyQueueInGroup];
    
    //dispatch 并发遍历
    [self tryDispatchAply];
}


-(void)greetWithString:(NSString *)string {
    NSString *s = [NSString stringWithFormat:@"hello world %@", string];
    NSLog(@"%@", s);
}

@end

@interface QSOperation()

@end

@implementation QSOperation

//-(void)start {}

-(void)main {
    longRunning(@"op");
}

@end
