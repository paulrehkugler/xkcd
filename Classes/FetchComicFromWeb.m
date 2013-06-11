//
//  FetchComicFromWeb.m
//

#import "FetchComicFromWeb.h"
#import "Comic.h"
#import "xkcdAppDelegate.h"
#import "NSString_HTML.h"
#import "NSData+BrokenUnicodeJSON.h"
#import "NSDictionary+TypeSafety.h"

#pragma mark -

@interface FetchComicFromWeb ()

@property(nonatomic, assign, readwrite) NSInteger comicNumber;
@property(nonatomic, strong, readwrite) NSString *comicName;
@property(nonatomic, strong, readwrite) NSString *comicTitleText;
@property(nonatomic, strong, readwrite) NSString *comicImageURL;
@property(nonatomic, strong, readwrite) NSString *comicTranscript;
@property(nonatomic, weak, readwrite) id target;
@property(nonatomic, assign, readwrite) SEL action;
@property(nonatomic, strong, readwrite) NSError *error;
@property(nonatomic, assign, readwrite) BOOL got404;

@end

#pragma mark -

@implementation FetchComicFromWeb

- (id)initWithComicNumber:(NSInteger)comicNumberToFetch completionTarget:(id)completionTarget action:(SEL)completionAction {
  if(self = [super init]) {
    _comicNumber = comicNumberToFetch;
    _target = completionTarget;
    _action = completionAction;
  }
  return self;
}

- (void)main {
  if(self.comicNumber == 404) {
    // Smart ass :)
    self.comicName = @"Not found";
    self.comicTitleText = @"";
    self.comicImageURL = @"http://imgs.xkcd.com/static/xkcdLogo.png"; // anything...
    self.comicTranscript = @"";
  } else {
    NSURL *comicURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.xkcd.com/%i/info.0.json", self.comicNumber]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:comicURL];
    [request setValue:kUseragent forHTTPHeaderField:@"User-Agent"];
    NSHTTPURLResponse *response = nil;
    NSError *requestError = nil;
    NSData *comicData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    self.got404 = [response statusCode] == 404;
    if(!self.got404) {
      self.error = requestError;
      if(!requestError) {
        NSError *parseError = nil;
        NSData *fixedData = [comicData dataByFixingFuckedUpUnicodeInJSON];
        NSDictionary *comicDictionary = [NSJSONSerialization JSONObjectWithData:fixedData options:0 error:&parseError];
        self.error = parseError;
        if(!parseError && [comicDictionary isKindOfClass:[NSDictionary class]]) {
          self.comicName = [NSString stringByCleaningHTML:[comicDictionary stringForKey:@"title"]];
          self.comicTitleText = [NSString stringByCleaningHTML:[comicDictionary stringForKey:@"alt"]];
          self.comicImageURL = [NSString stringByCleaningHTML:[comicDictionary stringForKey:@"img"]];
          self.comicTranscript = [comicDictionary stringForKey:@"transcript"];
          // TODO: use link/news to detect "large version" image urls
        }
      }
    }
  }
  if(![self isCancelled]) {
    [self.target performSelectorOnMainThread:self.action withObject:self waitUntilDone:NO];
  }
}

@end
