//
//  MARWYNewListVC.m
//  maxiaoding
//
//  Created by Martin.Liu on 2018/1/6.
//  Copyright © 2018年 MAIERSI. All rights reserved.
//

#import "MARWYNewListVC.h"
#import "MARWYNewTableCell.h"
#import <MJRefresh.h>
#import "MARWYUtility.h"
#import "MARWebViewController.h"

@interface MARWYNewListVC () <UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) MARWebViewController *webVC;
@end

@implementation MARWYNewListVC
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self needReloadData];
    
//    // 获取所有已知的时区缩写
//    NSDictionary *zoneAbbreviations = [NSTimeZone abbreviationDictionary];
//
//    NSTimeZone *zone = [NSTimeZone localTimeZone];
//
//    // 获取指定时区的缩写
//    NSString *zoneAbbreviation1 = [zone abbreviation];
//
//    // 获取指定时间所在时区名称缩写
//    NSString *zoneAbbreviation2 = [zone abbreviationForDate:[NSDate date]];
//    NSLog(@">>>>> zoneAbbreviations : %@", zoneAbbreviations);
//
//    NSLog(@">>>>> zoneAbbreviation1 : %@", zoneAbbreviation1);
//
//    NSLog(@">>>>> zoneAbbreviation2 : %@", zoneAbbreviation2);
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.model.contentOffset = self.tableView.contentOffset;
}

- (void)needReloadData
{
    [self.tableView reloadData];
    if (self.model.wyNewArray.count > 0) {
        self.tableView.contentOffset = self.model.contentOffset;
    }
    MARLog(@">>>> viewWillAppear");
    [self hiddenEmptyView];
    if (self.model.isDataEmpty) {
        [self showEmptyViewWithImageimage:nil description:@"敬请期待..."];
    }
    if (self.model.wyNewArray.count == 0) {
        self.tableView.contentOffset = CGPointZero;
        [self loadData];
    }
    else if ([[NSDate new] timeIntervalSince1970] - self.model.lastLoadTimeStamp > 60 * 30)
    {
        // 上次加载到页面出现大于半小时自动重新刷新
        [self refreshLoadData];
    }
}

- (void)UIGlobal
{
    MARAdjustsScrollViewInsets_NO(self.tableView, self);
    self.tableView.tableFooterView = [UIView new];
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadData)];
    footer.stateLabel.hidden = YES;
    footer.refreshingTitleHidden = YES;
    self.tableView.mj_footer = footer;
    
    @weakify(self)
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weak_self refreshLoadData];
    }];
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    self.tableView.mj_header = header;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 90;
}

- (void)refreshLoadData
{
    self.model.refreshLoadFn ++;
    [self.model.wyNewArray removeAllObjects];
    self.tableView.contentOffset = CGPointZero;
    [self loadData];
}

- (void)loadData
{
    [MARDataAnalysis setEventPage:@"WYNewListVC" EventLabel:@"wangyinew_loaddata"];
    if (self.isLoading) return;
    self.isLoading = YES;
    self.model.lastLoadTimeStamp = [[NSDate new] timeIntervalSince1970];
    MARWYGetNewArticleListR *requestModel = [MARWYGetNewArticleListR new];
    requestModel.offset = self.model.wyNewArray.count;
    requestModel.size = 20;
    requestModel.fn = self.model.refreshLoadFn;
    requestModel.from = requestModel.channel = self.model.categoryModel.tid;
    [requestModel setSignature];
    @weakify(self)
    NSArray *loadRedianArray = @[@"热点"];
    NSArray *loadTitleArray2 = @[@"新闻学院",@"音乐",@"活力冬奥学院",@"云课堂",@"汽车",@"房产",@"商城live",@"二次元",@"佛学",@"阳光法院",@"京东",@"天猫",@"跟贴",@"直播",@"NBA"];
    NSArray *loadTitleArray3 = @[@"萌宠", @"视频", @"美女"];//@[@"萌宠"];
    NSArray *loadTitleArray4 = @[@""];//@[@"段子"];
    if ([@"头条" isEqualToString:self.model.categoryModel.tname]) {
        requestModel.from = @"toutiao";
        requestModel.prog = @"Rpic2";
        @weakify(self)
        [MARWYNewNetworkManager getRecommendNewList:requestModel success:^(NSArray<MARWYNewModel *> *array) {
            @strongify(self)
            if (!strong_self) return;
            strong_self.isLoading = NO;
            [strong_self _loadNewArray:array];
            [strong_self.tableView reloadData];
        } failure:^(NSURLSessionTask *task, NSError *error) {
            weak_self.isLoading = NO;
            NSLog(@">>>>> get toutiao list error : %@", error);
            [weak_self.tableView reloadData];
            [weak_self.tableView.mj_header endRefreshing];
            [weak_self.tableView.mj_footer endRefreshing];
        }];
    }
    else if ([@"网易号" isEqualToString:self.model.categoryModel.tname]) {
        requestModel.from = @"toutiao";
        requestModel.prog = @"netease_h";
        @weakify(self)
        [MARWYNewNetworkManager getRecommendNewList:requestModel success:^(NSArray<MARWYNewModel *> *array) {
            @strongify(self)
            if (!strong_self) return;
            strong_self.isLoading = NO;
            [strong_self _loadNewArray:array];
            [strong_self.tableView reloadData];
        } failure:^(NSURLSessionTask *task, NSError *error) {
            weak_self.isLoading = NO;
            NSLog(@">>>>> get toutiao list error : %@", error);
            [weak_self.tableView reloadData];
            [weak_self.tableView.mj_header endRefreshing];
            [weak_self.tableView.mj_footer endRefreshing];
        }];
    }
    else if ([loadRedianArray containsObject:self.model.categoryModel.tname]) {
        [MARWYNewNetworkManager getRecommendNewList:requestModel success:^(NSArray<MARWYNewModel *> *array) {
            @strongify(self)
            if (!strong_self) return;
            strong_self.isLoading = NO;
            [strong_self _loadNewArray:array];
            [strong_self.tableView reloadData];
        } failure:^(NSURLSessionTask *task, NSError *error) {
            weak_self.isLoading = NO;
            NSLog(@">>>>> get new list error : %@", error);
            [weak_self.tableView reloadData];
            [weak_self.tableView.mj_header endRefreshing];
            [weak_self.tableView.mj_footer endRefreshing];
        }];
    }
    else if ([loadTitleArray2 containsObject:self.model.categoryModel.tname]) {
        [MARWYNewNetworkManager getNewArticleList2:requestModel success:^(NSArray<MARWYNewModel *> *array) {
            @strongify(self)
            if (!strong_self) return;
            strong_self.isLoading = NO;
            [strong_self _loadNewArray:array];
            [strong_self.tableView reloadData];
        } failure:^(NSURLSessionTask *task, NSError *error) {
            weak_self.isLoading = NO;
            NSLog(@">>>>> get new list error : %@", error);
            [weak_self.tableView reloadData];
            [weak_self.tableView.mj_header endRefreshing];
            [weak_self.tableView.mj_footer endRefreshing];
        }];
    }
    else if ([loadTitleArray3 containsObject:self.model.categoryModel.tname])
    {
        [MARWYNewNetworkManager getNewArticleList3:requestModel success:^(NSArray<MARWYNewModel *> *array) {
            @strongify(self)
            if (!strong_self) return;
            strong_self.isLoading = NO;
            [strong_self _loadNewArray:array];
            [strong_self.tableView reloadData];
        } failure:^(NSURLSessionTask *task, NSError *error) {
            weak_self.isLoading = NO;
            NSLog(@">>>>> get new list error : %@", error);
            [weak_self.tableView reloadData];
            [weak_self.tableView.mj_header endRefreshing];
            [weak_self.tableView.mj_footer endRefreshing];
        }];
    }
    else if ([loadTitleArray4 containsObject:self.model.categoryModel.tname]) {
        [MARWYNewNetworkManager getNewArticleList4:requestModel success:^(NSArray<MARWYNewModel *> *array) {
            @strongify(self)
            if (!strong_self) return;
            strong_self.isLoading = NO;
            [strong_self _loadNewArray:array];
            [strong_self.tableView reloadData];
        } failure:^(NSURLSessionTask *task, NSError *error) {
            weak_self.isLoading = NO;
            NSLog(@">>>>> get new list error : %@", error);
            [weak_self.tableView reloadData];
            [weak_self.tableView.mj_header endRefreshing];
            [weak_self.tableView.mj_footer endRefreshing];
        }];
    }
    else
    {
        [MARWYNewNetworkManager getNewArticleList:requestModel success:^(NSArray<MARWYNewModel *> *array) {
            @strongify(self)
            if (!strong_self) return;
            strong_self.isLoading = NO;
            [strong_self _loadNewArray:array];
            [strong_self.tableView reloadData];
        } failure:^(NSURLSessionTask *task, NSError *error) {
            weak_self.isLoading = NO;
            NSLog(@">>>>> get new list error : %@", error);
            [weak_self.tableView reloadData];
            [weak_self.tableView.mj_header endRefreshing];
            [weak_self.tableView.mj_footer endRefreshing];
        }];
    }
}

- (void)_loadNewArray:(NSArray<MARWYNewModel *> *)array
{
    [self.model.wyNewArray addObjectsFromArray:array];
    if (self.model.wyNewArray.count <= 0) {
        self.model.isDataEmpty = YES;
        [self showEmptyViewWithImageimage:nil description:@"敬请期待..."];
    }
    else
        self.model.isDataEmpty = NO;
    
    [self.tableView reloadData];
    [self.tableView.mj_header endRefreshing];
    [self.tableView.mj_footer endRefreshing];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _webVC = nil;
    MARLog(@">>>>> viewDidAppear");
}

- (void)setIsLoading:(BOOL)isLoading
{
    _isLoading = isLoading;
    if (_isLoading) {
        if (self.model.wyNewArray.count <= 0) {
            [self showActivityView:YES];
        }
    }
    else
    {
        [self showActivityView:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark - UITableView Datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.model.wyNewArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MARWYNewTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MARWYNewTableCell" forIndexPath:indexPath];
    NSInteger row = indexPath.row;
    if (self.model.wyNewArray.count > row) {
        MARWYNewModel *model = self.model.wyNewArray[row];
        [cell setCellData:model];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    if (cell && [self mar_isSupportForceTouch]) {
        [self registerForPreviewingWithDelegate:self sourceView:cell];
    }
#pragma clang diagnostic pop
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [MARDataAnalysis setEventPage:@"WYNewListVC" EventLabel:@"wangyinew_clickcell"];
    _webVC = [[MARWebViewController alloc] init];
//    [self prePareDateForIndexPath:indexPath];
    MARSocialShareMessageModel *message = [self prepareMessageForIndexPath:indexPath];
    _webVC.messageModel = message;
    [self mar_pushViewController:_webVC animated:YES];
}

- (MARSocialShareMessageModel *)prepareMessageForIndexPath:(NSIndexPath *)indexPath
{
    MARSocialShareMessageModel *messageModel = [MARSocialShareMessageModel new];
    MARWebViewController *webVC = self.webVC;
    NSInteger row = indexPath.row;
    if (self.model.wyNewArray.count > row) {
        MARWYNewModel *model = self.model.wyNewArray[row];
        messageModel.title = model.title;
        messageModel.thumImage = model.imgsrc;
        messageModel.shareDesc = model.digest;
        // 特殊处理的类别
        NSArray *skipTypeArray = @[WYNEWSkipType_PhotoSet, WYNEWSkipType_Video, WYNEWSkipType_Special]; // WYNEWSkipType_Live
        if (model.skipType && [skipTypeArray containsObject:model.skipType]) {
            if ([model.skipType isEqualToString:WYNEWSkipType_PhotoSet]) {
                NSString *skipType = [model.skipID copy];
                if (skipType.length > 4) {
                    skipType = [[skipType substringFromIndex:4] stringByReplacingOccurrencesOfString:@"|" withString:@"/"];
                }
                NSString *urlExtStr = skipType;
                NSString *url = [NSString stringWithFormat:@"%@/%@/%@.json", WANGYIHOST, WYGetPhotoNewDetail, urlExtStr];
                @weakify(self)
                [self showActivityView:YES];
                [MARNetworkManager mar_get:url parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
                    @strongify(self)
                    if (!strong_self) return;
                    [strong_self showActivityView:NO];
                    //                    NSLog(@"get photos %@", responseObject);
                    if ([responseObject[@"url"] mar_isValidUrl]) {
                        if (strong_self.webVC == webVC) {
                            messageModel.URLString = responseObject[@"url"];
                            strong_self.webVC.URL = [NSURL URLWithString:responseObject[@"url"]];
                        }
                    }
                    else
                    {
                        if (strong_self.webVC == webVC) {
                            [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                        }
                    }
                } failure:^(NSURLSessionTask *task, NSError *error) {
                    @strongify(self)
                    if (!strong_self) return;
                    if (strong_self.webVC == webVC)
                        [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                    [strong_self showActivityView:NO];
                    NSLog(@">>>>> get photos error : %@", error);
                }];
            }
            else if ([model.skipType isEqualToString:WYNEWSkipType_Video])
            {
                @weakify(self)
                [self showActivityView:YES];
                [MARWYNewNetworkManager getVideoNewDetailWithSkipId:model.skipID success:^(NSURLSessionTask *task, id responseObject) {
                    @strongify(self)
                    if (!strong_self) return;
                    [strong_self showActivityView:NO];
                    MARWYVideoNewDetailModel *model = [MARWYVideoNewDetailModel mar_modelWithJSON:responseObject];
                    if ([model.vurl mar_isValidUrl]) {
                        if (strong_self.webVC == webVC) {
                            messageModel.URLString = model.vurl;
                            messageModel.shareDesc = model.desc;
                            strong_self.webVC.URL = [NSURL URLWithString:model.vurl];
                        }
                    }
                    else
                    {
                        if (strong_self.webVC == webVC) {
                            [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                        }
                    }
                    NSLog(@">>>>>>> get videoDetail : %@", responseObject);
                } failure:^(NSURLSessionTask *task, NSError *error) {
                    @strongify(self)
                    if (!strong_self) return;
                    if (strong_self.webVC == webVC)
                        [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                    NSLog(@">>>>>>> get videoDetail error : %@", error);
                }];
            }
            else if ([model.skipType isEqualToString:WYNEWSkipType_Special])
            {
                NSString *postId = model.postid;
                NSString *url = [NSString stringWithFormat:@"%@/%@/%@/full.html", WANGYIHOST, WYGetSpecialNewDetail, postId];
                @weakify(self)
                [self showActivityView:YES];
                [MARNetworkManager mar_get:url parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
                    @strongify(self)
                    if (!strong_self) return;
                    [strong_self showActivityView:NO];
                    MARWYNewDetailModel *detailModel = [MARWYNewDetailModel mar_modelWithJSON:responseObject[model.postid]];
                    NSLog(@">>>>> %@", detailModel);
                    if (strong_self.webVC == webVC) {
                        strong_self.webVC.htmlString = [detailModel getHtmlString];
                    }
                    else
                    {
                        if (strong_self.webVC == webVC) {
                            [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                        }
                    }
                } failure:^(NSURLSessionTask *task, NSError *error) {
                    @strongify(self)
                    if (!strong_self) return;
                    if (strong_self.webVC == webVC)
                        [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                    NSLog(@"get wynew detail error : %@", error);
                }];
                    
            }
        }
        else if (![model.docid mar_containsString:@"|"])
        {
            //  specail
            if ([model.url mar_isValidUrl]) {
                messageModel.URLString = model.url;
            }
            else
            {
                messageModel = nil;
            }
            @weakify(self)
            [self showActivityView:YES];
            [MARWYNewNetworkManager getNewDetailWithDocId:model.docid success:^(NSURLSessionTask *task, id responseObject) {
                @strongify(self)
                if (!strong_self) return;
                [strong_self showActivityView:NO];
                //                NSLog(@"get wynew detail  : %@", responseObject);
                MARWYNewDetailModel *detailModel = [MARWYNewDetailModel mar_modelWithJSON:responseObject[model.docid]];
                NSLog(@">>>>> %@", detailModel);
                if (strong_self.webVC == webVC) {
                    strong_self.webVC.htmlString = [detailModel getHtmlString];
                }
                else
                {
                    if (strong_self.webVC == webVC) {
                        [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                    }
                }
            } failure:^(NSURLSessionTask *task, NSError *error) {
                @strongify(self)
                if (!strong_self) return;
                if (strong_self.webVC == webVC)
                    [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                NSLog(@"get wynew detail error : %@", error);
            }];
        }
        else if ([model.url mar_isValidUrl]) {
            if (self.webVC == webVC) {
                webVC.URL = [NSURL URLWithString:model.url];
            }
        }
        else
        {
            messageModel = nil;
            if (self.webVC == webVC) {
                [self.webVC.navigationController popViewControllerAnimated:YES];
                ShowInfoMessage(@"我迷路了！", 1.f);
            }
        }
    }
    return messageModel;
}

- (void)prePareDateForIndexPath:(NSIndexPath *)indexPath
{
    MARWebViewController *webVC = self.webVC;
    NSInteger row = indexPath.row;
    if (self.model.wyNewArray.count > row) {
        MARWYNewModel *model = self.model.wyNewArray[row];
        if (model.skipType) {
            if ([model.skipType isEqualToString:WYNEWSkipType_PhotoSet]) {
                NSString *skipType = [model.skipID copy];
                if (skipType.length > 4) {
                    skipType = [[skipType substringFromIndex:4] stringByReplacingOccurrencesOfString:@"|" withString:@"/"];
                }
                NSString *urlExtStr = skipType;
                NSString *url = [NSString stringWithFormat:@"%@/%@/%@.json", WANGYIHOST, WYGetPhotoNewDetail, urlExtStr];
                @weakify(self)
                [self showActivityView:YES];
                [MARNetworkManager mar_get:url parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
                    @strongify(self)
                    if (!strong_self) return;
                    [strong_self showActivityView:NO];
                    //                    NSLog(@"get photos %@", responseObject);
                    if ([responseObject[@"url"] mar_isValidUrl]) {
                        if (strong_self.webVC == webVC) {
                            strong_self.webVC.URL = [NSURL URLWithString:responseObject[@"url"]];
                        }
                    }
                    else
                    {
                        if (strong_self.webVC == webVC) {
                            [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                        }
                    }
                } failure:^(NSURLSessionTask *task, NSError *error) {
                    @strongify(self)
                    if (!strong_self) return;
                    if (strong_self.webVC == webVC)
                        [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                    [strong_self showActivityView:NO];
                    NSLog(@">>>>> get photos error : %@", error);
                }];
            }
            else if ([model.skipType isEqualToString:WYNEWSkipType_Video])
            {
                @weakify(self)
                [self showActivityView:YES];
                [MARWYNewNetworkManager getVideoNewDetailWithSkipId:model.skipID success:^(NSURLSessionTask *task, id responseObject) {
                    @strongify(self)
                    if (!strong_self) return;
                    [strong_self showActivityView:NO];
                    MARWYVideoNewDetailModel *model = [MARWYVideoNewDetailModel mar_modelWithJSON:responseObject];
                    if ([model.vurl mar_isValidUrl]) {
                        if (strong_self.webVC == webVC) {
                            strong_self.webVC.URL = [NSURL URLWithString:responseObject[@"url"]];
                        }
                    }
                    else
                    {
                        if (strong_self.webVC == webVC) {
                            [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                        }
                    }
                    NSLog(@">>>>>>> get videoDetail : %@", responseObject);
                } failure:^(NSURLSessionTask *task, NSError *error) {
                    @strongify(self)
                    if (!strong_self) return;
                    if (strong_self.webVC == webVC)
                        [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                    NSLog(@">>>>>>> get videoDetail error : %@", error);
                }];
            }
            
        }
        else if (![model.docid mar_containsString:@"|"])
        {
            @weakify(self)
            [self showActivityView:YES];
            [MARWYNewNetworkManager getNewDetailWithDocId:model.docid success:^(NSURLSessionTask *task, id responseObject) {
                @strongify(self)
                if (!strong_self) return;
                [strong_self showActivityView:NO];
                //                NSLog(@"get wynew detail : %@", responseObject);
                MARWYNewDetailModel *detailModel = [MARWYNewDetailModel mar_modelWithJSON:responseObject[model.docid]];
                NSLog(@">>>>> %@", detailModel);
                if (strong_self.webVC == webVC) {
                    strong_self.webVC.htmlString = [detailModel getHtmlString];
                }
                else
                {
                    if (strong_self.webVC == webVC) {
                        [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                    }
                }
            } failure:^(NSURLSessionTask *task, NSError *error) {
                @strongify(self)
                if (!strong_self) return;
                if (strong_self.webVC == webVC)
                    [strong_self.webVC.navigationController popViewControllerAnimated:YES];
                NSLog(@"get wynew detail error : %@", error);
            }];
        }
        else if ([model.url mar_isValidUrl]) {
            if (self.webVC == webVC) {
                webVC.URL = [NSURL URLWithString:model.url];
            }
        }
        else
        {
            if (self.webVC == webVC) {
                [self.webVC.navigationController popViewControllerAnimated:YES];
                ShowInfoMessage(@"我迷路了！", 1.f);
            }
        }
    }
}

#pragma mark - ForceTouch Delegate
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    // 防止重复加入
    if ([self.presentedViewController isKindOfClass:[MARWebViewController class]]) {
        return nil;
    }
    else
    {
        _webVC = [[MARWebViewController alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[previewingContext sourceView]];
#pragma clang diagnostic pop
        [self prePareDateForIndexPath:indexPath];
        return _webVC;
    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    if (_webVC) {
        [self mar_pushViewController:_webVC animated:YES];
    }
}

#pragma mark - VTMagicProtocol
- (void)vtm_prepareForReuse
{
    MARLog(@">>>>>  vtm_prepareForReuse");
}

- (void)clickAppStatusBar
{
    if (self.magicController.currentViewController == self) {
        [self.tableView mar_scrollToTopAnimated:YES];
    }
}

@end

@implementation MARNewListPropertyModel

- (instancetype)init
{
    self = [self initWithCategoryModel:nil];
    if (!self) return nil;
    return self;
}

- (instancetype)initWithCategoryModel:(MARWYNewCategoryTitleModel *)model
{
    self = [super init];
    if (!self) return nil;
    _contentOffset = CGPointZero;
    _wyNewArray = [NSMutableArray arrayWithCapacity: 1 << 5];
    _categoryModel = model;
    _refreshLoadFn = 1;
    return self;
}

@end
