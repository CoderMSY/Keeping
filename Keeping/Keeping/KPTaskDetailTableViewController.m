//
//  KPTaskDetailTableViewController.m
//  Keeping
//
//  Created by 宋 奎熹 on 2017/1/20.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

#import "KPTaskDetailTableViewController.h"
#import "TaskManager.h"
#import "Utilities.h"
#import "KPSeparatorView.h"
#import "UIView+MJAlertView.h"
#import "DateUtil.h"
#import "DateTools.h"
#import "KPImageViewController.h"
#import "KPSchemeTableViewController.h"
#import "KPReminderViewController.h"
#import "KPSchemeManager.h"

#define ENDLESS_STRING @"无限期"
#define DATE_FORMAT @"yyyy/MM/dd"

@interface KPTaskDetailTableViewController ()

@end

@implementation KPTaskDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    //导航栏左上角
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NAV_CANCEL"] style:UIBarButtonItemStylePlain target:self action:@selector(backAction:)];
    self.navigationItem.leftBarButtonItems = @[cancelItem];
    //导航栏右上角
    UIBarButtonItem *okItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"NAV_DONE"] style:UIBarButtonItemStylePlain target:self action:@selector(doneAction:)];
    //不能编辑==过期==没有右上角
    if([self.tableView isUserInteractionEnabled]){
        self.navigationItem.rightBarButtonItems = @[okItem];
    }
    
    
    //任务名
    [self.taskNameField setFont:[UIFont fontWithName:[Utilities getFont] size:25.0f]];
    //文本框代理
    self.taskNameField.delegate = self;
    self.linkTextField.delegate = self;
    
    
    //持续时间
    for(UILabel *label in self.durationStack.subviews){
        [label setFont:[UIFont fontWithName:[Utilities getFont] size:20.0f]];
    }
    
    
    //星期几选项按钮
    for(UIButton *button in self.weekDayStack.subviews){
        [button setTintColor:[Utilities getColor]];
        [button setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
        if(button.tag != -1){
            //-1是全选按钮
            [button.titleLabel setFont:[UIFont fontWithName:[Utilities getFont] size:18.0f]];
            UIImage *buttonImg = [UIImage imageNamed:@"CIRCLE_BORDER"];
            buttonImg = [buttonImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [button setBackgroundImage:buttonImg forState:UIControlStateNormal];
        }else{
            [button.titleLabel setFont:[UIFont fontWithName:[Utilities getFont] size:12.0f]];
        }
    }
    
    
    //提醒标签
    [self.reminderLabel setFont:[UIFont fontWithName:[Utilities getFont] size:20.0f]];
    //提醒开关
    [self.reminderSwitch setTintColor:[Utilities getColor]];
    [self.reminderSwitch setOnTintColor:[Utilities getColor]];
    [self.reminderSwitch addTarget:self action:@selector(showReminderPickerAction:) forControlEvents:UIControlEventValueChanged];
    
    
    //APP名字标签
    [self.appNameLabel setFont:[UIFont fontWithName:[Utilities getFont] size:20.0f]];
    
    
    //图片
    self.selectedImgView.userInteractionEnabled = YES;
    for(UIButton *button in self.imgButtonStack.subviews){
        [button setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont fontWithName:[Utilities getFont] size:15.0f]];
    }
    
    
    //链接
    [self.linkTextField setFont:[UIFont fontWithName:[Utilities getFont] size:15.0f]];
    
    
    //到期日期颜色
    [self.endDateLabel setTextColor:[Utilities getColor]];
    
    
    
    if(self.task != NULL){
        [self.navigationItem setTitle:@"任务详情"];
        
        [self.taskNameField setText:[self.task name]];
        
        self.selectedWeekdayArr = [NSMutableArray arrayWithArray:self.task.reminderDays];
        if([self.selectedWeekdayArr count] > 0){
            [self.allButton setTitle:@"清空" forState: UIControlStateNormal];
        }else{
            [self.allButton setTitle:@"全选" forState: UIControlStateNormal];
        }
        for(NSNumber *num in self.selectedWeekdayArr){
            UIImage *buttonImg = [UIImage imageNamed:@"CIRCLE_FULL"];
            buttonImg = [buttonImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.weekDayStack.subviews[num.integerValue-1] setBackgroundImage:buttonImg forState:UIControlStateNormal];
            [self.weekDayStack.subviews[num.integerValue-1] setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        
        [self.startDateLabel setText:[self.task.addDate formattedDateWithFormat:DATE_FORMAT]];
        if(self.task.endDate != NULL){
            [self.endDateLabel setText:[self.task.endDate formattedDateWithFormat:DATE_FORMAT]];
            
            //如果已经超期，不能编辑
            //            if([self.task.endDate isEarlierThan:[NSDate date]]){
            //                [self.tableView setUserInteractionEnabled:NO];
            //            }else{
            //                [self.tableView setUserInteractionEnabled:YES];
            //            }
            
        }else{
            [self.endDateLabel setText:ENDLESS_STRING];
        }
        
        //对星期排序
        NSMutableArray *arr = [NSMutableArray arrayWithArray:self.task.reminderDays];
        [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSNumber *n1 = (NSNumber *)obj1;
            NSNumber *n2 = (NSNumber *)obj2;
            NSComparisonResult result = [n1 compare:n2];
            return result == NSOrderedDescending;
        }];
        self.task.reminderDays = arr;
        
        self.selectedApp = self.task.appScheme;
        if(self.selectedApp != NULL){
            [self.appNameLabel setText:self.selectedApp.allKeys[0]];
        }
        
        self.reminderTime = self.task.reminderTime;
        if(self.reminderTime != NULL){
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm"];
            NSString *currentDateStr = [dateFormatter stringFromDate:self.reminderTime];
            [self.reminderLabel setText:currentDateStr];
            [self.reminderSwitch setOn:YES];
        }else{
            [self.reminderLabel setText:@"无"];
            [self.reminderSwitch setOn:NO];
        }
        
        if(self.task.image != NULL){
            [self.selectedImgView setImage:[UIImage imageWithData:self.task.image]];
            [self setHasImage];
        }else{
            [self setNotHaveImage];
        }
        
        [self.linkTextField setText:self.task.link];
        
        [self.tableView reloadData];
        
    }else{
        [self.navigationItem setTitle:@"新增任务"];
        
        [self.startDateLabel setText:[[NSDate date] formattedDateWithFormat:DATE_FORMAT]];
        [self.endDateLabel setText:ENDLESS_STRING];
        
        self.selectedWeekdayArr = [[NSMutableArray alloc] init];
        [self.reminderSwitch setOn:NO];
        
        [self setNotHaveImage];
        
        [self.taskNameField becomeFirstResponder];
    }
    
}

- (void)hideKeyboard{
    if([self.taskNameField isFirstResponder]){
        [self.taskNameField resignFirstResponder];
    }
    if([self.linkTextField isFirstResponder]){
        [self.linkTextField resignFirstResponder];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)checkCompleted{
    if([self.taskNameField.text isEqualToString:@""]){
        return NO;
    }
    if([self.selectedWeekdayArr count] <= 0){
        return NO;
    }
    return YES;
}

- (void)backAction:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)nextAction:(id)sender{
    if(![self checkCompleted]){
        [UIView addMJNotifierWithText:@"信息填写不完整" dismissAutomatically:YES];
    }else{
        [self performSegueWithIdentifier:@"addExtraSegue" sender:nil];
    }
}

- (void)doneAction:(id)sender{
    
    //先检查有没有填满必填信息
    if(![self checkCompleted]){
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"信息填写不完整"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的"
                                                           style:UIAlertActionStyleDefault
                                                         handler: nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    if(self.task == NULL){
        self.task = [Task new];
    }
    
    //任务名
    self.task.name = self.taskNameField.text;
    //app 名
    self.task.appScheme = self.selectedApp;
    //提醒时间
    self.task.reminderTime = self.reminderTime;
    //图片
    self.task.image = UIImagePNGRepresentation(self.selectedImgView.image);
    //链接
    self.task.link = self.linkTextField.text;       //有：文字，无：@“”
    //结束日期
    if([self.endDateLabel.text isEqualToString:ENDLESS_STRING]){
        self.task.endDate = NULL;
    }else{
        self.task.endDate = [NSDate dateWithString:self.endDateLabel.text formatString:DATE_FORMAT];
    }
    
    //更新
    if(self.task.id == 0){
        
        //添加日期，打卡数组
        NSDate *addDate = [NSDate dateWithYear:[[NSDate date] year] month:[[NSDate date] month] day:[[NSDate date] day]];
        self.task.addDate = addDate;
        self.task.punchDateArr = [[NSMutableArray alloc] init];

        //完成时间
        //对星期排序
        NSMutableArray *arr = [NSMutableArray arrayWithArray:self.selectedWeekdayArr];
        [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSNumber *n1 = (NSNumber *)obj1;
            NSNumber *n2 = (NSNumber *)obj2;
            NSComparisonResult result = [n1 compare:n2];
            return result == NSOrderedDescending;
        }];
        //赋值
        self.task.reminderDays = arr;
        
        //增加
        [[TaskManager shareInstance] addTask:self.task];
        
        //提示
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"新增成功"
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){
                                                             [self.navigationController popToRootViewControllerAnimated:YES];
                                                         }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }else{
        //完成时间排序
        NSMutableArray *arr = [NSMutableArray arrayWithArray:self.selectedWeekdayArr];
        [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSNumber *n1 = (NSNumber *)obj1;
            NSNumber *n2 = (NSNumber *)obj2;
            NSComparisonResult result = [n1 compare:n2];
            return result == NSOrderedDescending;
        }];
        self.selectedWeekdayArr = arr;
        
        if(![self.task.reminderDays isEqual:arr]){
            UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:@"注意"
                                                message:@"您更改了预计完成日的选项，这会导致今天之前的打卡记录清空，新的记录将从今天开始重新计算。您要继续吗？"
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                               style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action){
                                                                     
                                                                     [[TaskManager shareInstance] updateTask:self.task];
                                                                     
                                                                     UIAlertController *alertController =
                                                                     [UIAlertController alertControllerWithTitle:@"修改成功"
                                                                                                         message:nil
                                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                                                                     UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的"
                                                                                                                        style:UIAlertActionStyleDefault
                                                                                                                      handler:^(UIAlertAction *action){
                                                                                                                          [self.navigationController popToRootViewControllerAnimated:YES];
                                                                                                                      }];
                                                                     [alertController addAction:okAction];
                                                                     [self presentViewController:alertController animated:YES completion:nil];
                                                                 }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"仍然更改"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action){
                                                                 
                                                                 //更新厨师日期、打卡数组和提醒日期
                                                                 self.task.reminderDays = arr;
                                                                 
                                                                 NSDate *addDate = [NSDate dateWithYear:[[NSDate date] year] month:[[NSDate date] month] day:[[NSDate date] day]];
                                                                 self.task.addDate = addDate;
                                                                 self.task.punchDateArr = [[NSMutableArray alloc] init];
                                                                 
                                                                 [[TaskManager shareInstance] updateTask:self.task];
                                                                 
                                                                 UIAlertController *alertController =
                                                                 [UIAlertController alertControllerWithTitle:@"修改成功"
                                                                                                     message:nil
                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                                                 UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的"
                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                  handler:^(UIAlertAction *action){
                                                                                                                      [self.navigationController popToRootViewControllerAnimated:YES];
                                                                                                                  }];
                                                                 [alertController addAction:okAction];
                                                                 [self presentViewController:alertController animated:YES completion:nil];
                                                             }];
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }else{
            
            [[TaskManager shareInstance] updateTask:self.task];
            
            UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:@"修改成功"
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action){
                                                                 [self.navigationController popToRootViewControllerAnimated:YES];
                                                             }];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }

    }
}

#pragma mark - Select Weekday Actions

- (IBAction)selectWeekdayAction:(id)sender{
    UIButton *btn = (UIButton *)sender;
    UIImage *buttonImg;
    NSNumber *tag = [NSNumber numberWithInteger:btn.tag];
    //包含
    if([self.selectedWeekdayArr containsObject:tag]){
        buttonImg = [UIImage imageNamed:@"CIRCLE_BORDER"];
        [self.selectedWeekdayArr removeObject:tag];
        [btn setTitleColor:[Utilities getColor] forState:UIControlStateNormal];
    }else{
        //不包含
        buttonImg = [UIImage imageNamed:@"CIRCLE_FULL"];
        [self.selectedWeekdayArr addObject:tag];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    buttonImg = [buttonImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btn setBackgroundImage:buttonImg forState:UIControlStateNormal];
    
    if([self.selectedWeekdayArr count] > 0){
        [self.allButton setTitle:@"清空" forState: UIControlStateNormal];
    }else{
        [self.allButton setTitle:@"全选" forState: UIControlStateNormal];
    }
}

- (IBAction)selectAllWeekdayAction:(id)sender{
    UIButton *btn = (UIButton *)sender;
    if([btn.titleLabel.text isEqualToString:@"全选"]){
        [self.allButton setTitle:@"清空" forState: UIControlStateNormal];
        for(UIButton *button in self.weekDayStack.subviews){
            if(button.tag != -1){
                NSNumber *tag = [NSNumber numberWithInteger:button.tag];
                if(![self.selectedWeekdayArr containsObject:tag]){
                    [self selectWeekdayAction:button];
                }
            }
        }
    }else if([btn.titleLabel.text isEqualToString:@"清空"]){
        [self.allButton setTitle:@"全选" forState: UIControlStateNormal];
        for(UIButton *button in self.weekDayStack.subviews){
            if(button.tag != -1){
                NSNumber *tag = [NSNumber numberWithInteger:button.tag];
                if([self.selectedWeekdayArr containsObject:tag]){
                    [self selectWeekdayAction:button];
                }
            }
        }
    }
}

#pragma mark - Reminder Actions

- (void)showReminderPickerAction:(id)sender{
    if(![self.reminderSwitch isOn]){
        self.reminderTime = NULL;
        [self.reminderLabel setText:@"无"];
    }else{
        NSDate *date = (NSDate *)sender;
        [self performSegueWithIdentifier:@"reminderSegue" sender:date];
    }
}

#pragma mark - Pic Actions

- (IBAction)deletePicAction:(id)sender{
    if(self.selectedImgView.image == [UIImage new]){
        return;
    }else{
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"删除图片"
                                            message:@"您确定要删除这张图片？"
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alertController addAction:cancelAction];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"删除"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action){
                                                             [self setNotHaveImage];
                                                         }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (IBAction)modifyPicAction:(id)sender{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"选择一张照片" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"拍照"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                                                             imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                                                             [self presentViewController:imagePickerController animated:YES completion:nil];
                                                         }];
    
    UIAlertAction *photosAction = [UIAlertAction actionWithTitle:@"从相册选取"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                                             [self presentViewController:imagePickerController animated:YES completion:nil];
                                                         }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        [alert addAction:cameraAction];
    }
    
    [alert addAction:photosAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)clickPicAction:(id)sender{
    if(self.selectedImgView.image == [UIImage new]){
        return;
    }else{
        [self performSegueWithIdentifier:@"imageSegue" sender:self.selectedImgView.image];
    }
}

- (UIImage *)normalizedImage:(UIImage *)img {
    if (img.imageOrientation == UIImageOrientationUp){
        return img;
    }
    UIGraphicsBeginImageContextWithOptions(img.size, NO, img.scale);
    [img drawInRect:(CGRect){0, 0, img.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (void)setHasImage{
    [self.addImgButton setTitle:@"更改图片" forState: UIControlStateNormal];
    [self.viewImgButton setHidden:NO];
    [self.deleteImgButton setHidden:NO];
    [self.deleteImgButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.tableView reloadData];
}

- (void)setNotHaveImage{
    self.task.image = NULL;
    [self.selectedImgView setImage:NULL];
    
    [self.addImgButton setTitle:@"添加图片" forState: UIControlStateNormal];
    [self.viewImgButton setHidden:YES];
    [self.deleteImgButton setHidden:YES];
    [self.tableView reloadData];
}

#pragma mark - Select end date

- (void)showDatePicker{
    HSDatePickerViewController *hsdpvc = [[HSDatePickerViewController alloc] init];
    hsdpvc.delegate = self;
    hsdpvc.minDate = [NSDate date];
    
    hsdpvc.backButtonTitle = @"返回";
    hsdpvc.confirmButtonTitle = @"确定";
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:DATE_FORMAT];
    hsdpvc.dateFormatter = fmt;
    
    NSDateFormatter *myfmt = [[NSDateFormatter alloc] init];
    [myfmt setDateFormat:@"yyyy 年 MM 月"];
    hsdpvc.monthAndYearLabelDateFormater = myfmt;
    
    [self presentViewController:hsdpvc animated:YES completion:nil];
}

- (void)hsDatePickerPickedDate:(NSDate *)date{
    if(date == NULL){
        [self.endDateLabel setText:ENDLESS_STRING];
    }else{
        NSDate *endDate = [NSDate dateWithYear:[date year] month:[date month] day:[date day]];
        [self.endDateLabel setText:[endDate formattedDateWithFormat:DATE_FORMAT]];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    KPSeparatorView *view = [[[NSBundle mainBundle] loadNibNamed:@"KPSeparatorView" owner:nil options:nil] lastObject];
    switch (section) {
        case 0:
            [view setText:@"任务名"];
            break;
        case 1:
            [view setText:@"完成时间"];
            break;
        case 2:
            [view setText:@"持续时间"];
            break;
        case 3:
            [view setText:@"提醒时间"];
            break;
        case 4:
            [view setText:@"打开 APP"];
            break;
        case 5:
            [view setText:@"链接"];
            break;
        case 6:
            [view setText:@"图片"];
            break;
        default:
            [view setText:@""];
            break;
    }
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.00001f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 2:
            [self showDatePicker];
            break;
        case 3:
            [self showReminderPickerAction:[NSDate date]];
            break;
        case 4:
            [self performSegueWithIdentifier:@"appSegue" sender:nil];
            break;
        case 6:
            [self modifyPicAction:nil];
            break;
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 6){
        return self.view.frame.size.width;
    }else{
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self hideKeyboard];
    return YES;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"appSegue"]){
        KPSchemeTableViewController *kpstvc = (KPSchemeTableViewController *)[segue destinationViewController];
        kpstvc.delegate = self;
        if(self.selectedApp != NULL){
            [kpstvc setSelectedPath:[NSIndexPath indexPathForRow:[[KPSchemeManager getSchemeArr] indexOfObject:self.selectedApp] inSection:1]];
        }else{
            [kpstvc setSelectedPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }
    }else if([segue.identifier isEqualToString:@"reminderSegue"]){
        KPReminderViewController *kprvc = (KPReminderViewController *)[segue destinationViewController];
        kprvc.delegate = self;
        [kprvc.timePicker setPickingDate:(NSDate *)sender];
    }else if([segue.identifier isEqualToString:@"imageSegue"]){
        KPImageViewController *imageVC = (KPImageViewController *)[segue destinationViewController];
        [imageVC setImg:(UIImage *)sender];
    }
}

#pragma mark - Scheme Delegate

- (void)passScheme:(NSDictionary *)value{
    if([value.allKeys[0] isEqualToString:@""]){
        self.selectedApp = NULL;
        [self.appNameLabel setText:@"无"];
    }else{
        self.selectedApp = value;
        [self.appNameLabel setText:self.selectedApp.allKeys[0]];
    }
    [self.tableView reloadData];
}

#pragma mark - Reminder Delegate

- (void)passTime:(NSDate *)date{
    if(date == NULL){
        self.reminderTime = NULL;
        [self.reminderSwitch setOn:NO animated:YES];
        [self.reminderLabel setText:@"无"];
    }else{
        self.reminderTime = date;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSString *currentDateStr = [dateFormatter stringFromDate:self.reminderTime];
        [self.reminderLabel setText:currentDateStr];
    }
    [self.tableView reloadData];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    //原图还是编辑过的图？
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.selectedImgView setImage:[self normalizedImage:image]];
    [self setHasImage];
}

@end
