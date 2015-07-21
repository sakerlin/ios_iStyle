//
//  RootViewController.m
//  iStyle
//
//  Created by Bipo Tsai on 7/16/15.
//  Copyright (c) 2015 Bipo Tsai. All rights reserved.
//

#import "RootViewController.h"
#import "SXStackLayout.h"
#import "SXLineLayout.h"
#import "SXCircleLayout.h"
#import "SXImageCell.h"
#import "MWGridCell.h"
#import "MWPhoto.h"
#import "MWCommon.h"



#define LAYOUT_TYPE_LINE 1
#define LAYOUT_TYPE_CIRCLE 2
#define LAYOUT_TYPE_STACK 3

@interface RootViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UITabBarDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UINavigationBar *naviBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backBtnItem;
@property (nonatomic, strong) NSMutableArray *photos;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet UITabBarItem *lineBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *circleBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *stackBarItem;
@end

@implementation RootViewController

static NSString *const ID = @"image";

- (NSMutableArray *)photos
{
    if (!_photos) {
        self.photos = [[NSMutableArray alloc] init];
        NSFileManager *fm=[NSFileManager defaultManager];
        
        //Document Path
        NSArray *docDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = [NSString stringWithFormat:@"%@/screenshot/",[docDirectory objectAtIndex:0]];
        
        NSArray *info=[fm contentsOfDirectoryAtPath:documentPath error:nil];
        for (NSString *path in info) {
            NSString *imgPath = [NSString stringWithFormat:@"file://%@/%@", documentPath, path];
            MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:imgPath]];
             photo.caption = path;
            [self.photos addObject:photo];
        }
       
    }
    return _photos;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    //SXCircleLayout *layout = [[SXCircleLayout alloc] init];
    SXLineLayout *layout = [[SXLineLayout alloc] init];
    //SXStackLayout *layout = [[SXStackLayout alloc] init];
    
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, self.view.frame.size.height-90) collectionViewLayout:layout];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor clearColor];
    
    //image cell
    //[collectionView registerNib:[UINib nibWithNibName:@"SXImageCell" bundle:nil] forCellWithReuseIdentifier:ID];
    
    //another grid view
    [collectionView registerClass:[MWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    collectionView.alwaysBounceVertical = YES;
    collectionView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    
    self.tabBar.delegate = self;
    self.lineBarItem.tag = LAYOUT_TYPE_LINE;
    self.circleBarItem.tag = LAYOUT_TYPE_CIRCLE;
    self.stackBarItem.tag = LAYOUT_TYPE_STACK;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    //return self.images.count;
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //    SXImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
    //    //cell.image = self.images[indexPath.item];
    //    MWPhoto *photo = (MWPhoto*)self.photos[indexPath.item];
    //    [photo loadUnderlyingImageAndNotify];
    //    cell.image = photo;
    
    MWGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[MWGridCell alloc] init];
    }
    MWPhoto *photo = (MWPhoto*)self.photos[indexPath.item];
    cell.photo = photo;
    
    //cell.gridController = self;
    //cell.selectionMode = _selectionMode;
    //cell.isSelected = [_browser photoIsSelectedAtIndex:indexPath.row];
    cell.index = indexPath.row;
    [photo loadUnderlyingImageAndNotify];
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 删除图片名
    //[self.images removeObjectAtIndex:indexPath.item];
    [self.photos removeObjectAtIndex:indexPath.item];
    
    // 刷新数据
    //    [self.collectionView reloadData];
    
    // 直接将cell删除
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
}
- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    UICollectionViewLayout *layout;
    if(item.tag==LAYOUT_TYPE_CIRCLE)
    {
        layout = [[SXCircleLayout alloc] init];
        
        
    }
    else if(item.tag==LAYOUT_TYPE_STACK)
    {
        layout = [[SXStackLayout alloc] init];
        
    }else{
        layout = [[SXLineLayout alloc] init];
        
    }
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 235) collectionViewLayout:layout];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor clearColor];
    
    [collectionView registerClass:[MWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    collectionView.alwaysBounceVertical = YES;
    collectionView.backgroundColor = [UIColor blackColor];
    
    
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    self.collectionView.reloadData;
    
}

@end
