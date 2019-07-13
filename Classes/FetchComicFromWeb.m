//
//  FetchComicFromWeb.m
//

#import "FetchComicFromWeb.h"
#import "Comic.h"
#import "NSString_HTML.h"
#import "NSDictionary+TypeSafety.h"
#import "xkcd-Swift.h"

#pragma mark -

@interface FetchComicFromWeb ()

@property (nonatomic) NSInteger comicNumber;
@property (nonatomic) NSString *comicName;
@property (nonatomic) NSString *comicTitleText;
@property (nonatomic) NSString *comicImageURL;
@property (nonatomic) NSString *comicTranscript;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic) NSError *error;
@property (nonatomic) BOOL got404;
@property (nonatomic) NSURLSession *URLSession;
@property (nonatomic) NSURLSessionDataTask *dataTask;

@end

#pragma mark -

@implementation FetchComicFromWeb

- (instancetype)initWithComicNumber:(NSInteger)comicNumberToFetch
						 URLSession:(NSURLSession *)URLSession
				   completionTarget:(id)completionTarget
							 action:(SEL)completionAction {
	if (self = [super init]) {
		_comicNumber = comicNumberToFetch;
		_target = completionTarget;
		_action = completionAction;
		_URLSession = URLSession;
	}
	return self;
}

- (void)main {
	if (self.comicNumber == 404) {
		// Smart ass :)
		self.comicName = @"Not found";
		self.comicTitleText = @"";
		self.comicImageURL = @"http://imgs.xkcd.com/static/xkcdLogo.png"; // anything...
		self.comicTranscript = @"";

        if (![self isCancelled]) {
            [self.target performSelectorOnMainThread:self.action withObject:self waitUntilDone:NO];
        }
	}
	else {
		NSURL *comicURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.xkcd.com/%li/info.0.json", (long)self.comicNumber]];
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:comicURL];
		[request setValue:[Constants userAgent] forHTTPHeaderField:@"User-Agent"];
		
		self.dataTask = [self.URLSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
			if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
				NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
				self.got404 = statusCode == 404;
			}
			
			if (!self.got404) {
				self.error = error;
				if (!error) {
					NSError *parseError = nil;
					NSDictionary *comicDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
					self.error = parseError;
					if (!parseError && [comicDictionary isKindOfClass:[NSDictionary class]]) {
						self.comicName = [NSString stringByCleaningHTML:[comicDictionary stringForKey:@"title"]];
						self.comicTitleText = [NSString stringByCleaningHTML:[comicDictionary stringForKey:@"alt"]];
						self.comicImageURL = [NSString stringByCleaningHTML:[comicDictionary stringForKey:@"img"]];
						self.comicTranscript = [comicDictionary stringForKey:@"transcript"];
						// TODO: use link/news to detect "large version" image urls
					}
				}
			}

            if (![self isCancelled]) {
                [self.target performSelectorOnMainThread:self.action withObject:self waitUntilDone:NO];
            }
		}];
		
		[self.dataTask resume];
	}
}

@end
