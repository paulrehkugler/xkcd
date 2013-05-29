//
//  FAQViewController.m
//

#import "FAQViewController.h"

@interface FAQViewController ()

@property (nonatomic, readwrite) IBOutlet UITextView *textView;

@end

@implementation FAQViewController

@synthesize textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if(self) {
    self.title = NSLocalizedString(@"FAQ", @"FAQ");
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(done)];
  NSString *faqPath = [[NSBundle mainBundle] pathForResource:@"faq" ofType:@"plist"];
  NSArray *faqArray = [NSArray arrayWithContentsOfFile:faqPath];

  NSMutableAttributedString *display = [[NSMutableAttributedString alloc] init];

  UIFont *boldFont = [UIFont fontWithName:@"Helvetica-Bold" size:16.0f];
  NSDictionary *qAttributes = @{NSFontAttributeName: boldFont};

  UIFont *regularFont = [UIFont fontWithName:@"Helvetica" size:14.0f];
  NSDictionary *aAttributes = @{NSFontAttributeName: regularFont};

  for(NSDictionary *faqEntry in faqArray) {
    NSString *q = [NSString stringWithFormat:@"\u2022 %@", faqEntry[@"Q"]];
    NSString *a = faqEntry[@"A"];

    NSAttributedString *attributedQ = [[NSAttributedString alloc] initWithString:q attributes:qAttributes];
    [display appendAttributedString:attributedQ];

    [display appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
    NSAttributedString *attributedA = [[NSAttributedString alloc] initWithString:a attributes:aAttributes];
    [display appendAttributedString:attributedA];

    [display appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [display appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
  }

  textView.attributedText = display;
}

- (void)done {
  [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
