//
//  ViewController.m
//  加载多张大图_Runloop优化
//
//  Created by zzyyd on 2018/9/28.
//  Copyright © 2018年 zzyyd. All rights reserved.
//  1.监听runloop循环，runloop循环一次就加载一张图片
//  2.创建一个数组，用于装任务（block代码），runloop循环一次就取一个任务执行

#import "ViewController.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

static NSString*TIDENTIFY = @"TIDENTIFY";
static CGFloat PICRATIO = 1.5;//图片的比例（宽：高）
static CGFloat PERCELLPICNUMBER = 4;//每排有多少张图片
static CGFloat PICGAP = 5.0;//图片之间的间隙
static CGFloat TITLELABELHEIGHT = 20.0;//标题label的高度

typedef void(^RunloopBlock)(void);

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    CGFloat perPicWidth;//每张图片宽度
    CGFloat perPicHeight;//每张图片高度
    CGFloat cellHeight;//cell的高度
}

@property(nonatomic,strong)UITableView*myTableView;

@property(nonatomic,strong)NSMutableArray*tasksArr;//创建一个数组，用于装任务（block代码）

@property(nonatomic,assign)int maxTaksLength;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //计算图片的宽高和cell高度
    perPicWidth = (SCREEN_WIDTH - PICGAP*(PERCELLPICNUMBER+1))/PERCELLPICNUMBER;
    perPicHeight = perPicWidth/PICRATIO;
    cellHeight = perPicHeight + TITLELABELHEIGHT + 5.0;
    
    //初始化tableview
    [self.view addSubview:self.myTableView];
    
    _maxTaksLength = 32;//以iphone6为例，一排4张，屏幕最多显示8排，共32张。
    _tasksArr = [NSMutableArray new];
    
    //用timer让runloop不进入睡眠，解决不滑动时（主线程runloop不处理事件就会进入睡眠）图片不加载的问题。
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(unuselessMethod) userInfo:nil repeats:YES];
    
    //添加观察者
    [self addRunloopObserver];
}

-(void)unuselessMethod{
    //空事件什么都不做，目的是为了配合timer让runloop不进入睡眠
}

-(UITableView *)myTableView{
    if (!_myTableView) {
        self.myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44.0, SCREEN_WIDTH, SCREEN_HEIGHT-44.0) style:(UITableViewStylePlain)];
        [self.myTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TIDENTIFY];
        self.myTableView.delegate = self;
        self.myTableView.dataSource = self;
        self.myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _myTableView;
}


#pragma -- UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 120;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:TIDENTIFY];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //干掉cell上的子控件，节约内存
    for(UIView*v in cell.contentView.subviews){
        [v removeFromSuperview];
    }
    //添加标题
    [self addCellTitleLabel:cell andIndex:indexPath.row];
    
    //添加图片
    __weak typeof(self) weakSelf = self;
    [self addTask:^{
        [weakSelf addCellImgs:cell];
    }];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return cellHeight;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


/*
 加载cell的控件
 */
//加载标题
-(void)addCellTitleLabel:(UITableViewCell*)cell andIndex:(NSUInteger)index{
    UILabel*label = [[UILabel alloc]initWithFrame:CGRectMake(PICGAP, 0, SCREEN_WIDTH, TITLELABELHEIGHT)];
    label.tag = 0;
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:17.0];
    label.textColor = [UIColor greenColor];
    label.text = [NSString stringWithFormat:@"高清黄山风景图片--%d",(int)(index+1)];
    [cell.contentView addSubview:label];
}

//加载cell的图片
-(void)addCellImgs:(UITableViewCell*)cell{
    NSString*imgPath = [[NSBundle mainBundle]pathForResource:@"MYPIC" ofType:@"jpeg"];
    UIImage*img = [UIImage imageWithContentsOfFile:imgPath];
    
    for (int num = 0; num < PERCELLPICNUMBER; num++) {
        CGRect imgVFrame =CGRectMake((num+1)*PICGAP + num*perPicWidth, TITLELABELHEIGHT, perPicWidth, perPicHeight);
        UIImageView*imgView = [[UIImageView alloc]initWithFrame:imgVFrame];
        imgView.tag = num+1;
        imgView.image = img;
        [cell.contentView addSubview:imgView];
    }
}

#pragma mark -- Runloop

//添加任务
-(void)addTask:(RunloopBlock)block{
    [self.tasksArr addObject:block];
    //保证数组只放32个任务
    if (self.tasksArr.count > _maxTaksLength) {
        [self.tasksArr removeObjectAtIndex:0];
    }
}

//添加观察者
-(void)addRunloopObserver{
    //获取runloop
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    //定义观察者
    static CFRunLoopObserverRef defaultModeObserver;
    //创建上下文,由于CallBack是C函数不允许使用OC对象，所以要依靠上下文的传递来解决这个问题
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)(self),//OC对象转C
        &CFRetain,
        &CFRelease,
        NULL,
    };
    //创建
    defaultModeObserver = CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, YES, 0, &CallBack, &context);
    //添加到当前runloop中
    CFRunLoopAddObserver(runloop, defaultModeObserver, kCFRunLoopCommonModes);
}

/*
 CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info
 这三个参数是观察的时候上下文传递过来的
 */
static void CallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    //取出任务执行，一次runloop循环执行一个任务
    ViewController*self = (__bridge ViewController*)info;
    if (self.tasksArr.count == 0) {
        return;
    }
    RunloopBlock task = self.tasksArr.firstObject;
    task();
    //执行完毕移除任务
    [self.tasksArr removeObjectAtIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
