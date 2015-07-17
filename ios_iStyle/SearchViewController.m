//
//  SearchViewController.m
//  iStyle
//
//  Created by Taco Chang on 2015/7/13.
//  Copyright (c) 2015年 Taco Chang. All rights reserved.
//

#import "SearchViewController.h"
#import "ImageCell.h"
#import "SearchRecord.h"
#import <UIImageView+AFNetworking.h>
#import <QuartzCore/QuartzCore.h>
#import <SVPullToRefresh.h>
#import <SVProgressHUD.h>


#define SEARCH_TYPE_HAT 1
#define SEARCH_TYPE_TOP 2
#define SEARCH_TYPE_BOTTOM 3
#define SEARCH_TYPE_SHOES 4

#define RECORD_LIMIT 8

#define SEARCH_INTERFACE_YQL 1
#define SEARCH_INTERFACE_API 2

@interface SearchViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITabBarItem *topBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *bottomBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *hatBarItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *shoesBarItem;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet UIView *maskView;

@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, strong) NSMutableArray *records;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) NSInteger recordOffset;
@property (nonatomic, assign) NSInteger searchInterface;
@property (nonatomic, strong) NSMutableString *searchText;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, assign) CGSize iOSDeviceScreenSize;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.searchBar.delegate = (id)self;
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"ImageCell" bundle:nil] forCellWithReuseIdentifier:@"ImageCell"];
    
    self.iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    self.responseData = [[NSMutableData alloc] init];
    self.records = [NSMutableArray array];
    self.searchText = [[NSMutableString alloc] initWithString:@""];
    self.recordOffset = 1;
    self.type = SEARCH_TYPE_TOP;
    [self.tabBar setSelectedItem:self.topBarItem];
    self.tabBar.delegate = self;
    self.topBarItem.tag = SEARCH_TYPE_TOP;
    self.bottomBarItem.tag = SEARCH_TYPE_BOTTOM;
    self.hatBarItem.tag = SEARCH_TYPE_HAT;
    self.shoesBarItem.tag = SEARCH_TYPE_SHOES;
    self.maskView.hidden = YES;
    [SVProgressHUD setBackgroundColor:[UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.5]];
    
    [self didSearch];
    
    // setup infinite scrolling
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        [self insertRowAtBottom];
    }];
}

- (IBAction)onBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [self onCancel];
}

- (void)onCancel {
    self.maskView.hidden = YES;
    [self.searchBar resignFirstResponder];
}

- (void)resetDataWithSearchText:(NSString *)searchText {
    self.recordOffset = 1;
    [self.searchText setString:searchText];
    self.selectedIndexPath = nil;
    self.searchBar.text = searchText;
    [self.records removeAllObjects];
    [self.searchBar resignFirstResponder];
}

- (void)resetData {
    [self resetDataWithSearchText:@""];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    self.type = item.tag;
    [self resetData];
    [self didSearch];
}

- (IBAction)onTap:(UITapGestureRecognizer *)sender {
    [self onCancel];
}

- (void)didSearch {
    [SVProgressHUD show];
    NSMutableArray *keywords = [NSMutableArray array];
    switch (self.type) {
        case SEARCH_TYPE_TOP:
        default:
            [keywords addObject:@"上衣"];
            if (self.searchText.length > 0) {
                [keywords addObject:self.searchText];
            }
            
            [self searchWithCluster:keywords clusterName:nil offset:self.recordOffset limit:RECORD_LIMIT];
            break;
        case SEARCH_TYPE_BOTTOM:
            if (self.searchText.length > 0) {
                [keywords addObject:self.searchText];
            }
            
            [self searchWithCluster:keywords clusterName:@"褲子" offset:self.recordOffset limit:RECORD_LIMIT];
            break;
        case SEARCH_TYPE_HAT:
            if (self.searchText.length > 0) {
                [keywords addObject:self.searchText];
            }
            
            [self searchWithCluster:keywords clusterName:@"帽子" offset:self.recordOffset limit:RECORD_LIMIT];
            break;
        case SEARCH_TYPE_SHOES:
            [keywords addObject:@"鞋子"];
            if (self.searchText.length > 0) {
                [keywords addObject:self.searchText];
            }
            
            [self searchWithCluster:keywords clusterName:nil offset:self.recordOffset limit:RECORD_LIMIT];
            break;
    }
    
    self.recordOffset = self.recordOffset + RECORD_LIMIT;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CollectionView Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.records.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSInteger size = (self.iOSDeviceScreenSize.width - 30) / 2;
    return CGSizeMake(size, size);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    
    SearchRecord *record = self.records[indexPath.row];
    [cell.imageView setImageWithURL:[NSURL URLWithString:record.imageUrl]];
    if (self.selectedIndexPath != nil && self.selectedIndexPath.row == indexPath.row) {
        [self setSelectedCellBorder:cell];
    }
    else {
        [self unsetSelectedCellBorder:cell];
    }
    
    return cell;
}

- (void)setSelectedCellBorder:(ImageCell *)cell {
    cell.layer.borderWidth = 3.0f;
    cell.layer.borderColor = [UIColor orangeColor].CGColor;
}

- (void)unsetSelectedCellBorder:(ImageCell *)cell {
    cell.layer.borderWidth = 1.0f;
    cell.layer.borderColor = [UIColor grayColor].CGColor;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndexPath != nil) {
        ImageCell *cell = (ImageCell *)[collectionView cellForItemAtIndexPath:self.selectedIndexPath];
        [self unsetSelectedCellBorder:cell];
    }
    self.selectedIndexPath = indexPath;
    
    ImageCell *cell = (ImageCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self setSelectedCellBorder:cell];
    
    [self.delegate getSelectedRecord:self.records[self.selectedIndexPath.row]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)insertRowAtBottom {
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self didSearch];
        [self.collectionView.infiniteScrollingView stopAnimating];
    });
}

#pragma mark - UISearchBar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.maskView.hidden = NO;
    self.searchBar.showsCancelButton = YES;
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    [self.searchText setString:text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self resetDataWithSearchText:self.searchText];
    [self didSearch];
    [self.searchBar resignFirstResponder];
    self.maskView.hidden = YES;
    self.searchBar.showsCancelButton = NO;
}

- (void)searchWithCluster:(NSArray *)keywords clusterName:(NSString *)clusterName offset:(NSInteger)offset limit:(NSInteger)limit {
    self.responseData = [NSMutableData new];
    NSURL *url;
    
    if (keywords == nil || keywords.count == 0) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://tw.egs.srch.ect.yahoo.com:4080/v2/egs/list/shopping/QueryByClusterName/?cluster=%@&offset=%lu&hits=%lu", [clusterName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],(long) offset-1, limit]];
        self.searchInterface = SEARCH_INTERFACE_API;
    }
    else {
        NSString *keyword = [keywords componentsJoinedByString:@" "];
        NSMutableString *query = [NSMutableString string];
        [query appendString:[NSString stringWithFormat:@"SELECT * FROM oneecsearch.search (%lu,%lu) WHERE keyword='%@' and property='shopping'", (long)offset, limit, keyword]];
        if (clusterName != nil) {
            [query appendString:[NSString stringWithFormat:@" and flc='%@'",clusterName]];
        }
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ec.yql.yahoo.com:4080/v1/public/yql?q=%@&format=json", [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]]];
        self.searchInterface = SEARCH_INTERFACE_YQL;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    NSLog(@"%@", url);
    [request setHTTPMethod:@"GET"];
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark - NSURLConnection

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.responseData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *error = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:self.responseData options:kNilOptions error:&error];
    
    if (self.searchInterface == SEARCH_INTERFACE_YQL) {
        [self.records addObjectsFromArray:[SearchRecord searchRecordsWithArray:[jsonArray valueForKeyPath:@"query.results.hits"]]];
    }
    else if (self.searchInterface == SEARCH_INTERFACE_API) {
        [self.records addObjectsFromArray:[SearchRecord searchRecordsWithArray:[jsonArray valueForKeyPath:@"response_data.result.ecsearch.hits"]]];
    }
    [self.collectionView reloadData];
    [SVProgressHUD dismiss];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"something very bad happened here: %@", error);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
