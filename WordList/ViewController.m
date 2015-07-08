//
//  ViewController.m
//  WordList
//
//  Created by Alexander Doloz on 7/8/15.
//  Copyright (c) 2015 -. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Persistence.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateStatistics];
}

- (void)updateStatistics {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.textView.text = [appDelegate.persistence statistics];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadWordList:(id)sender {
    [(UIButton *)sender setHidden:YES];
    NSURL *url = [NSURL URLWithString:@"https://dotnetperls-controls.googlecode.com/files/enable1.txt"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"Loading words");
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSString *words = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (words != nil && statusCode == 200) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.persistence loadWordList:words];
        } else {
            NSLog(@"Error: %lu", statusCode);
            if (error != nil) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }
        [(UIButton *)sender setHidden:NO];
        [self updateStatistics];
    }];
}

@end
