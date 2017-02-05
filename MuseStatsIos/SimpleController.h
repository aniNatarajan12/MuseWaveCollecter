//
//  SimpleController.h
//  MuseStatsIos
//
//  Created by Anirudh Natarajan on 2/4/17.
//  Copyright (c) 2016 Kodikos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Muse/Muse.h>

@interface SimpleController : UIViewController
< IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener, IXNLogListener,
  UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView* tableView;
@property (nonatomic, strong) IBOutlet UITextView* logView;
- (IBAction)disconnect:(id)sender;
- (IBAction)scan:(id)sender;
- (IBAction)stopScan:(id)sender;
- (void)applicationWillResignActive;
@end
