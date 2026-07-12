#import "RootViewController.h"
#import <ffmpegkit/FFmpegKit.h>
#import <PhotosUI/PhotosUI.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface RootViewController () <UITableViewDelegate, UITableViewDataSource, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, assign) float currentScale;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation RootViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait; 
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ตั้งค่าพื้นหลังรวมเป็นสีดำสนิทสนมกับ Dark Mode 
    self.view.backgroundColor = [UIColor blackColor];
    self.currentScale = 2.0f; // ค่าเริ่มต้นของ itsscale
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = NO;
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = [UIColor systemBlueColor];
        self.title = @"TT-Tool";
    }

    [self setupData];
    [self setupTableView];
    [self setupSpinner];
}

- (void)setupData {
    self.menuItems = @[
        @{@"title": @"เลือกวิดีโอจากคลังภาพ", @"subtitle": @"ดึงไฟล์ต้นฉบับตรงไม่ผ่านเบราว์เซอร์"},
        @{@"title": @"ตั้งค่าความเร็ว (itsscale)", @"subtitle": @"ปัจจุบัน: 2.0x (สโลว์โมชัน 2 เท่า)"}
    ];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.tableView];
}

- (void)setupSpinner {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spinner.color = [UIColor systemBlueColor];
    self.spinner.center = self.view.center;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
}

#pragma mark - UITableView Quick Setup (Dark Style)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DarkCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor colorWithWhite:0.07 alpha:1.0]; // สีเทาเข้มหรูหรา
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        
        // เอฟเฟกต์การเลือกสีมืด
        UIView *selectedBG = [[UIView alloc] init];
        selectedBG.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        cell.selectedBackgroundView = selectedBG;
    }
    
    NSDictionary *item = self.menuItems[indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = item[@"subtitle"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        [self openSystemPicker];
    } else if (indexPath.row == 1) {
        [self showScaleAlert];
    }
}

#pragma mark - Core Action: การปรับค่าความเร็วผ่าน Alert

- (void)showScaleAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ตั้งค่าตัวคูณเวลา" message:@"ใส่ค่า itsscale ที่ต้องการรันในคำสั่ง FFmpeg (เช่น 2.0 หรือ 0.5)" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.text = [NSString stringWithFormat:@"%.1f", self.currentScale];
    }];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"ตกลง" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *input = alert.textFields.firstObject;
        if (input.text.floatValue > 0) {
            self.currentScale = input.text.floatValue;
            [self setupData];
            [self.tableView reloadData];
        }
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"ยกเลิก" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Core Action: ดึงไฟล์ดิบผ่าน PHPicker (เลี่ยง WebKit Auto-Compress)

- (void)openSystemPicker {
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    config.filter = [PHPickerFilter videosFilter];
    config.preferredAssetRepresentationMode = PHPickerConfigurationAssetRepresentationModeCurrent; // จุดสำคัญ: ดึงไฟล์ดิบ ไม่แปลงไฟล์!
    
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (results.count == 0) return;
    
    [self.spinner startAnimating];
    
    PHPickerResult *result = results.firstObject;
    NSItemProvider *provider = result.itemProvider;
    
    // ดึง Type Identifier ของไฟล์วิดีโอต้นฉบับ
    NSString *typeIdentifier = @"public.mpeg-4";
    if (![provider hasItemConformingToTypeIdentifier:typeIdentifier]) {
        if (provider.registeredTypeIdentifiers.count > 0) {
            typeIdentifier = provider.registeredTypeIdentifiers.firstObject;
        }
    }
    
    [provider loadFileRepresentationForTypeIdentifier:typeIdentifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (error || !url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                [self showStatusAlert:@"เกิดข้อผิดพลาดในการดึงไฟล์ต้นฉบับ"];
            });
            return;
        }
        
        // คัดลอกวิดีโอไปยังตำแหน่งโฟลเดอร์ชั่วคราวของตัวแอป
        NSString *tempDir = NSTemporaryDirectory();
        NSString *inputPath = [tempDir stringByAppendingPathComponent:@"Test.MP4"];
        NSString *outputPath = [tempDir stringByAppendingPathComponent:@"Test1.MP4"];
        
        [[NSFileManager defaultManager] removeItemAtPath:inputPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:inputPath error:nil];
        
        // ประกอบคำสั่งและเริ่มประมวลผลผ่านคลัง FFmpegKit
        NSString *cmd = [NSString stringWithFormat:@"-itsscale %f -i %@ -codec copy %@", self.currentScale, inputPath, outputPath];
        
        [FFmpegKit executeAsync:cmd withCompleteCallback:^(id<Session> session) {
            ReturnCode *code = [session getReturnCode];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                if ([ReturnCode isSuccess:code]) {
                    // ส่งวิดีโอผลลัพธ์กลับเข้าไปบันทึกไว้ในม้วนฟิล์มคลังภาพ
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:outputPath]];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (success) {
                                [self showStatusAlert:@"แปลงไฟล์และบันทึกลงคลังภาพความละเอียด 1080p สำเร็จ!"];
                            } else {
                                [self showStatusAlert:@"แปลงสำเร็จแต่บันทึกลงอัลบั้มไม่ได้ ตรวจสอบสิทธิ์เข้าถึงคลังภาพ"];
                            }
                        });
                    }];
                } else {
                    [self showStatusAlert:@"คำสั่ง FFmpeg ทำงานล้มเหลว"];
                }
            });
        }];
    }];
}

- (void)showStatusAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ระบบทำงาน" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"ตากลบล็อค" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
