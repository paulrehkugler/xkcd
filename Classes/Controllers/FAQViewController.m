//
//  FAQViewController.m
//

#import "FAQViewController.h"

@interface FAQViewController ()

@property (nonatomic) UITextView *textView;

@end

@implementation FAQViewController

- (instancetype) init {
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"FAQ", @"FAQ");
		self.textView = [[UITextView alloc] init];
		self.textView.translatesAutoresizingMaskIntoConstraints = false;
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    [self.view addSubview:self.textView];
	
	NSArray<NSLayoutConstraint *> *constraints = @[
	  [self.textView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
	  [self.textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
	  [self.textView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
	  [self.textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
	];
	
	[NSLayoutConstraint activateConstraints:constraints];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(done)];
	NSString *faqPath = [[NSBundle mainBundle] pathForResource:@"faq" ofType:@"plist"];
	NSArray *faqArray = [NSArray arrayWithContentsOfFile:faqPath];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.firstLineHeadIndent = 8.0;
	paragraphStyle.headIndent = 8.0;
	paragraphStyle.tailIndent = -8.0;
	
	NSMutableAttributedString *display = [[NSMutableAttributedString alloc] init];
	
	UIFont *boldFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	NSMutableDictionary *qAttributes = [@{
								  NSFontAttributeName: boldFont,
								  NSParagraphStyleAttributeName: paragraphStyle
								  } mutableCopy];
	
    
    
	UIFont *regularFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	NSMutableDictionary *aAttributes = [@{
								  NSFontAttributeName: regularFont,
								  NSParagraphStyleAttributeName: paragraphStyle
								  } mutableCopy];
	
    if (@available(iOS 13.0, *)) {
        [qAttributes addEntriesFromDictionary:@{ NSForegroundColorAttributeName: [UIColor labelColor] }];
        [aAttributes addEntriesFromDictionary:@{ NSForegroundColorAttributeName: [UIColor labelColor] }];
    }
    
	for (NSDictionary *faqEntry in faqArray) {
		NSString *q = faqEntry[@"Q"];
		NSString *a = faqEntry[@"A"];
        
		NSAttributedString *attributedQ = [[NSAttributedString alloc] initWithString:q attributes:qAttributes];
		[display appendAttributedString:attributedQ];
		
		[display appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
		
		NSAttributedString *attributedA = [[NSAttributedString alloc] initWithString:a attributes:aAttributes];
		[display appendAttributedString:attributedA];
		
		[display appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
		[display appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
	}
	
	self.textView.attributedText = display;
	
	/*
	 Good ol' iOS 7+ scroll view behavior. Too hard to debug UIViewController, so here's a hack to make
	 sure the content doesn't underlap the nav bar when the view first appears. Cool.
	 */
	self.textView.contentOffset = CGPointMake(0, -self.view.safeAreaLayoutGuide.layoutFrame.origin.y);
}

- (void)done {
	[self dismissViewControllerAnimated:YES completion:^{}];
}

@end
