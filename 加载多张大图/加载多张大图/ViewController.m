//
//  ViewController.m
//  加载多张大图
//
//  Created by zzyyd on 2018/9/28.
//  Copyright © 2018年 zzyyd. All rights reserved.
//

#import "ViewController.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

static NSString*TIDENTIFY = @"TIDENTIFY";
static CGFloat PICRATIO = 1.5;//图片的比例（宽：高）
static CGFloat PERCELLPICNUMBER = 3;//每排有多少张图片
static CGFloat PICGAP = 5.0;//图片之间的间隙
static CGFloat TITLELABELHEIGHT = 20.0;//标题label的高度

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    CGFloat perPicWidth;//每张图片宽度
    CGFloat perPicHeight;//每张图片高度
    CGFloat cellHeight;//cell的高度
}

@property(nonatomic,strong)UITableView*myTableView;

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
    [self addCellImgs:cell];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
