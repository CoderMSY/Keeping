//
//  KPSchemeTableViewController.m
//  Keeping
//
//  Created by 宋 奎熹 on 2017/1/18.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

#import "KPSchemeTableViewController.h"
#import "KPSchemeManager.h"
#import "KPSchemeTableViewCell.h"
#import "Utilities.h"
#import "KPScheme.h"

@implementation KPSchemeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"Choose an app", nil)];
    
    //隐藏返回键
    [self.navigationItem setHidesBackButton:YES];
    //导航栏左上角
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NAV_BACK"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction:)];
    self.navigationItem.leftBarButtonItems = @[cancelItem];
    //导航栏右上角
    UIBarButtonItem *okItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NAV_DONE"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction:)];
    self.navigationItem.rightBarButtonItems = @[okItem];
    
    self.searchResults = [[NSMutableArray alloc] init];
    
    [self loadApps];
    //搜索框
    [self setSearchControllerView];
}

- (void)loadApps{
    self.schemeArr = [NSMutableArray arrayWithArray:[[KPSchemeManager shareInstance] getSchemeArr]];
    
    [self.tableView reloadData];
}

- (void)setSearchControllerView{
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = false;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.frame = CGRectMake(0, 100, self.view.frame.size.width, 44);
    self.searchController.searchBar.placeholder = NSLocalizedString(@"App name", nil);
    // 设置SearchBar的颜色主题为白色
    self.searchController.searchBar.barTintColor = [UIColor whiteColor];
    self.searchController.searchBar.backgroundImage = [[UIImage alloc] init];
    //搜索栏表头视图
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.searchController.searchBar sizeToFit];
    //背景颜色
    self.searchController.searchResultsUpdater = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.delegate passScheme:self.selectedApp];
}

- (void)backAction:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showSubmitAlert{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"sms:krayc425@gmail.com"] options:@{} completionHandler:^(BOOL success) {
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self.searchController isActive]){
        return 1;
    }else{
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([self.searchController isActive]){
        return self.searchResults.count;
    }else{
        if(section == 1){
            return [self.schemeArr count];
        }else{
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"KPSchemeTableViewCell";
    UINib *nib = [UINib nibWithNibName:@"KPSchemeTableViewCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
    KPSchemeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (self.searchController.isActive) {
        KPScheme *s = self.searchResults[indexPath.row];
        [cell.appNameLabel setText:s.name];
        
        if(self.selectedApp == self.searchResults[indexPath.row]){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        return cell;
    } else {
        if (indexPath.section <= 1) {
            if (indexPath.section == 0) {
                cell.appNameLabel.text = NSLocalizedString(@"None", nil);
                if(self.selectedApp == NULL){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }else{
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            } else {
                KPScheme *s = self.schemeArr[indexPath.row];
                [cell.appNameLabel setText:s.name];
                if (self.selectedApp == self.schemeArr[indexPath.row]) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            return cell;
        } else {
            return [super tableView:tableView cellForRowAtIndexPath:indexPath];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.isActive) {
        return 44;
    } else {
        if (indexPath.section != 1) {
            return [super tableView:tableView heightForRowAtIndexPath:indexPath];
        } else {
            return 44;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(self.searchController.isActive){
        return 10;
    }else{
        if (indexPath.section == 1) {
            return 10;
        } else {
            return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(self.searchController.isActive){
        if(self.selectedApp != self.searchResults[indexPath.row]){
            self.selectedApp = self.searchResults[indexPath.row];
        }else{
            self.selectedApp = NULL;
        }
    }else{
        if(indexPath.section == 2){
            [self showSubmitAlert];
        }else{
            if(indexPath.section == 1){
                if(self.selectedApp != self.schemeArr[indexPath.row]){
                    self.selectedApp = self.schemeArr[indexPath.row];
                }else{
                    self.selectedApp = NULL;
                }
            }else{
                self.selectedApp = NULL;
            }
        }
    }
    [tableView reloadData];
}

#pragma mark - Search Delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{
    if (self.searchResults.count > 0) {
        [self.searchResults removeAllObjects];
    }
    //NSPredicate 谓词
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF.name CONTAINS[cd] %@", searchController.searchBar.text];
    self.searchResults = [[self.schemeArr filteredArrayUsingPredicate:searchPredicate] mutableCopy];
    //刷新表格
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    dispatch_async(dispatch_get_main_queue(), ^{
        //滚动到选择的地方
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.schemeArr indexOfObject:self.selectedApp] inSection:1] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    });
}

@end
