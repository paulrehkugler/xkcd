//
//  FAQViewController.m
//

#import "FAQViewController.h"

@interface FAQViewController ()

@property (nonatomic, readwrite) IBOutlet UITextView *textView;

@end

@implementation FAQViewController

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
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.firstLineHeadIndent = 8.0;
	paragraphStyle.headIndent = 8.0;
	paragraphStyle.tailIndent = -8.0;
	
	NSMutableAttributedString *display = [[NSMutableAttributedString alloc] init];
	
	UIFont *boldFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	NSDictionary *qAttributes = @{
								  NSFontAttributeName: boldFont,
								  NSParagraphStyleAttributeName: paragraphStyle
								  };
	
	UIFont *regularFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	NSDictionary *aAttributes = @{
								  NSFontAttributeName: regularFont,
								  NSParagraphStyleAttributeName: paragraphStyle
								  };
	
	for(NSDictionary *faqEntry in faqArray) {
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
}

- (void)done {
	[self dismissViewControllerAnimated:YES completion:^{}];
}

@end
