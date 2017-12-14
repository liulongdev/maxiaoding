//
//  MARHistoryDayViewController.m
//  maxiaoding
//
//  Created by Martin.Liu on 2017/12/13.
//  Copyright © 2017年 MAIERSI. All rights reserved.
//

#import "MARHistoryDayViewController.h"
#import <MobAPI/MobAPI.h>
#import "MARHistoryDayTableCell.h"
#import "MARHistoryDayDetailVC.h"
#import "MARMonthDayView.h"
#import <Masonry.h>

@interface MARHistoryDayViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MARMonthDayView* monthDayView;
@property (nonatomic, strong) NSArray *historyDayArray;

@end

@implementation MARHistoryDayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = nil;
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIView *naviBar = self.navigationController.navigationBar;
    [naviBar addSubview:self.monthDayView];
    self.monthDayView.mar_left = (kScreenWIDTH - self.monthDayView.mar_width)/2;
    
    [self.monthDayView addTarget:self action:@selector(getDataWithDateStr:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_monthDayView removeFromSuperview];
}

- (void)UIGlobal
{
    self.tableView.tableFooterView = [UIView new];
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self refreshSortState];
}

- (void)getDataWithDateStr:(MARMonthDayView *)monthDayView
{
    self.dateStr = [NSString stringWithFormat:@"%02ld%02ld", monthDayView.month, monthDayView.day];
    _historyDayArray = nil;
    [self.tableView reloadData];
    [self loadData];
}

- (void)refreshSortState
{
    BOOL isDescSort = [MARUserDefault getBoolBy:USERDEFAULTKEY_HistoryDayDataDESCSort];
    NSString *sortStr = @"↓";
    if (!isDescSort) {
        sortStr = @"↑";
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:sortStr style:UIBarButtonItemStyleDone target:self action:@selector(clickRightSorkBtnAction:)];
}

- (void)getDataAndReloadData
{
    _historyDayArray = [MARHistoryDayModel getHistoryDayArrayWithDateStr:self.dateStr];
    [self.tableView reloadData];
}

- (void)clickRightSorkBtnAction:(id)sender
{
    if (_historyDayArray.count > 0) {
        BOOL isDescSort = [MARUserDefault getBoolBy:USERDEFAULTKEY_HistoryDayDataDESCSort];
        [MARUserDefault setBool:!isDescSort key:USERDEFAULTKEY_HistoryDayDataDESCSort];
        [self refreshSortState];
        [self getDataAndReloadData];
    }
}

- (void)loadData
{
    if (self.historyDayArray.count > 0) {
        return;
    }
    __weak __typeof(self) weakSelf = self;
    [self showActivityView:YES];
    [MobAPI sendRequest:[MOBAHistoryRequest historyRequestWithDay:self.dateStr] onResult:^(MOBAResponse *response) {
        [weakSelf showActivityView:NO];
        if (!response.error) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            NSArray<MARHistoryDayModel *> *historyDayArray = [NSArray mar_modelArrayWithClass:[MARHistoryDayModel class] json:response.responder[@"result"]];
//            strongSelf->_historyDayArray = historyDayArray;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                for (MARHistoryDayModel *model in historyDayArray) {
                    [model updateToDB];
                }
                mar_dispatch_async_on_main_queue(^{
                    [strongSelf getDataAndReloadData];
                });
            });
            
        }
    }];
}

- (NSArray *)historyDayArray
{
    if (!_historyDayArray) {
        _historyDayArray = [MARHistoryDayModel getHistoryDayArrayWithDateStr:self.dateStr];
    }
    return _historyDayArray;
}

- (NSString *)dateStr
{
    if (!_dateStr || ![_dateStr isKindOfClass:[NSString class]] || _dateStr.length != 4) {
        MARGLOBALMANAGER.dataFormatter.dateFormat = @"MMdd";
        if (_date) {
            _dateStr = [MARGLOBALMANAGER.dataFormatter stringFromDate:_date];
        }
        else
            _dateStr = [MARGLOBALMANAGER.dataFormatter stringFromDate:[NSDate date]];
    }
    return _dateStr;
}

- (MARMonthDayView *)monthDayView
{
    if (!_monthDayView) {
        _monthDayView = [[MARMonthDayView alloc] initWithFrame:CGRectMake(0, 0, 80, 44)];
        _monthDayView.flowLayout.itemSize = CGSizeMake(80, 44);
        _monthDayView.backgroundColor = [UIColor clearColor];
    }
    return _monthDayView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.historyDayArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MARHistoryDayTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCell" forIndexPath:indexPath];
    NSInteger row = indexPath.row;
    if (self.historyDayArray.count > row) {
        [cell setCellData:self.historyDayArray[row]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if (self.historyDayArray.count > row) {
        [self performSegueWithIdentifier:@"goHistoryDayDetailVC" sender:self.historyDayArray[row]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"goHistoryDayDetailVC"]) {
        MARHistoryDayDetailVC *historyDayDetailVC = segue.destinationViewController;
        if ([historyDayDetailVC isKindOfClass:[MARHistoryDayDetailVC class]] && [sender isKindOfClass:[MARHistoryDayModel class]]) {
            historyDayDetailVC.historyDayModel = sender;
        }
    }
}

@end