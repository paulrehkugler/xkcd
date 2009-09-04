//
//  FetchComicFromWeb.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#import "FetchComicFromWeb.h"
#import "FlurryAPI.h"
#import "Comic.h"
#import "xkcdAppDelegate.h"

#pragma mark -
#pragma mark Statics

static NSArray *characterEntityArray = nil;

#pragma mark -

@interface FetchComicFromWeb ()

+ (NSString *)decodeCharacterEntitiesIn:(NSString *)source;

@property(nonatomic, assign, readwrite) NSInteger comicNumber;
@property(nonatomic, retain, readwrite) NSString *comicName;
@property(nonatomic, retain, readwrite) NSString *comicTitleText;
@property(nonatomic, retain, readwrite) NSString *comicImageURL;
@property(nonatomic, assign, readwrite) id target;
@property(nonatomic, assign, readwrite) SEL action;
@property(nonatomic, retain, readwrite) NSError *error;

@end

#pragma mark -

@implementation FetchComicFromWeb

@synthesize comicNumber;
@synthesize comicName;
@synthesize comicTitleText;
@synthesize comicImageURL;
@synthesize target;
@synthesize action;
@synthesize error;

- (id)initWithComicNumber:(NSInteger)comicNumberToFetch completionTarget:(id)completionTarget action:(SEL)completionAction {
  if(self = [super init]) {
    self.comicNumber = comicNumberToFetch;
    self.target = completionTarget;
    self.action = completionAction;
  }
  return self;
}

- (void)main {
  NSURL *comicURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.xkcd.com/%i", self.comicNumber]];
  if(self.comicNumber == 404) {
    // Smart ass :)
    self.comicName = @"Not found";
    self.comicTitleText = @"";
    self.comicImageURL = @"http://imgs.xkcd.com/static/xkcdLogo.png"; // anything...
  } else if(self.comicNumber == 482) {
    // Work around malformed HTML
    self.comicName = @"Height";
    self.comicTitleText = @"Interestingly, on a true vertical log plot, I think the Eiffel Tower's sides really would be straight lines.";
    self.comicImageURL = @"http://imgs.xkcd.com/comics/height.png";
  } else if(self.comicNumber == 488) {
    // Work around malformed HTML
    self.comicName = @"Steal This Comic";
    self.comicTitleText = @"I spent more time trying to get an audible.com audio book playing than it took to listen to the book.  I have lost every other piece of DRM-locked music I have paid for.";
    self.comicImageURL = @"http://imgs.xkcd.com/comics/steal_this_comic.png";
  } else if(self.comicNumber == 563) {
    // Work around malformed HTML
    self.comicName = @"Fermirotica";
    self.comicTitleText = @"I love how Google handles dimensional analysis.  Stats are ballpark and vary wildly by time of day and whether your mom is in town.";
    self.comicImageURL = @"http://imgs.xkcd.com/comics/fermirotica.png";
  } else {
    // Parse "normally" -- god I want an API!
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:comicURL] autorelease];
    [request setValue:kUseragent forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *response = nil;
    NSError *requestError = nil;
    NSData *comicData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    self.error = requestError;
    if(!requestError) {
      NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:comicData] autorelease];
      [parser setDelegate:self];
      [parser parse];
    }
  }  
  if(![self isCancelled]) {
    [self.target performSelectorOnMainThread:self.action withObject:self waitUntilDone:NO];
  }
}

- (void)dealloc {
  [comicName release];
  comicName = nil;
  
  [comicTitleText release];
  comicTitleText = nil;
  
  [comicImageURL release];
  comicImageURL = nil;
  
  [error release];
  error = nil;
  
  target = nil;
  action = NULL;
  
  [super dealloc];
}

#pragma mark -
#pragma mark NSXMLParser delegate functions

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
  
  if([attributeDict objectForKey:@"alt"] &&
     [attributeDict objectForKey:@"src"] &&
     [attributeDict objectForKey:@"title"]) {
    
    self.comicName = [[self class] decodeCharacterEntitiesIn:[attributeDict objectForKey:@"alt"]];
    self.comicTitleText = [[self class] decodeCharacterEntitiesIn:[attributeDict objectForKey:@"title"]];
    NSString *imageURLString = [attributeDict objectForKey:@"src"];
    self.comicImageURL = imageURLString;
  }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
  NSLog(@"Parse error on comic %i, %@", self.comicNumber, parseError);
  [FlurryAPI logError:@"Parse error" message:[NSString stringWithFormat:@"Parse error on comic %i: %@", self.comicNumber, parseError] exception:nil];
}

#pragma mark -
#pragma mark Helper functions

// borrowed from http://www.thinkmac.co.uk/blog/2005/05/removing-entities-from-html-in-cocoa.html
// ...and fixed a little
+ (NSString *)decodeCharacterEntitiesIn:(NSString *)source {
  if(!source) {
    return nil;
  }
  
  NSMutableString *escaped = [NSMutableString stringWithString:source];
  if(!characterEntityArray) {
    characterEntityArray = [NSArray arrayWithObjects:
                            @"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
                            @"&sect;", @"&uml;", @"&copy;", @"&ordf;", @"&laquo;", @"&not;", @"&shy;", @"&reg;",
                            @"&macr;", @"&deg;", @"&plusmn;", @"&sup2;", @"&sup3;", @"&acute;", @"&micro;",
                            @"&para;", @"&middot;", @"&cedil;", @"&sup1;", @"&ordm;", @"&raquo;", @"&frac14;",
                            @"&frac12;", @"&frac34;", @"&iquest;", @"&Agrave;", @"&Aacute;", @"&Acirc;",
                            @"&Atilde;", @"&Auml;", @"&Aring;", @"&AElig;", @"&Ccedil;", @"&Egrave;",
                            @"&Eacute;", @"&Ecirc;", @"&Euml;", @"&Igrave;", @"&Iacute;", @"&Icirc;", @"&Iuml;",
                            @"&ETH;", @"&Ntilde;", @"&Ograve;", @"&Oacute;", @"&Ocirc;", @"&Otilde;", @"&Ouml;",
                            @"&times;", @"&Oslash;", @"&Ugrave;", @"&Uacute;", @"&Ucirc;", @"&Uuml;", @"&Yacute;",
                            @"&THORN;", @"&szlig;", @"&agrave;", @"&aacute;", @"&acirc;", @"&atilde;", @"&auml;",
                            @"&aring;", @"&aelig;", @"&ccedil;", @"&egrave;", @"&eacute;", @"&ecirc;", @"&euml;",
                            @"&igrave;", @"&iacute;", @"&icirc;", @"&iuml;", @"&eth;", @"&ntilde;", @"&ograve;",
                            @"&oacute;", @"&ocirc;", @"&otilde;", @"&ouml;", @"&divide;", @"&oslash;", @"&ugrave;",
                            @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;", nil];
    [characterEntityArray retain];
  }
  
  int i;
  int count = [characterEntityArray count];
  
  // Html
  for(i = 0; i < count; i++) {
    NSRange range = [source rangeOfString:[characterEntityArray objectAtIndex: i]];
    if(range.location != NSNotFound) {
      [escaped replaceOccurrencesOfString:[characterEntityArray objectAtIndex: i] 
                               withString:[NSString stringWithFormat:@"%C", 160 + i] 
                                  options:NSLiteralSearch 
                                    range:NSMakeRange(0, [escaped length])];
    }
  }
  
  // Decimal & Hex
  NSRange start, finish, searchRange = NSMakeRange(0, [escaped length]);
  i = 0;
  
  while(i < [escaped length]) {
    start = [escaped rangeOfString:@"&#" 
                           options:NSCaseInsensitiveSearch 
                             range:searchRange];
    
    finish = [escaped rangeOfString:@";" 
                            options:NSCaseInsensitiveSearch 
                              range:searchRange];
    
    if(start.location != NSNotFound &&
       finish.location != NSNotFound &&
       finish.location > start.location) {
      
      NSRange entityRange = NSMakeRange(start.location, (finish.location - start.location) + 1);
      NSString *entity = [escaped substringWithRange:entityRange];     
      NSString *value = [entity substringWithRange:NSMakeRange(2, [entity length] - 2)];
      
      [escaped deleteCharactersInRange:entityRange];
      
      if([value hasPrefix: @"x"]) {
        NSUInteger tempInt = 0;
        NSScanner *scanner = [NSScanner scannerWithString:[value substringFromIndex:1]];
        [scanner scanHexInt:&tempInt];
        [escaped insertString: [NSString stringWithFormat:@"%C", tempInt] atIndex: entityRange.location];
      } else {
        [escaped insertString: [NSString stringWithFormat:@"%C", [value intValue]] atIndex: entityRange.location];
      }
      i = start.location;
    } else {
      i++;
    }
    searchRange = NSMakeRange(i, [escaped length] - i);
  }
  
  NSDictionary *stringSubstitutions = [[[NSDictionary alloc] initWithObjectsAndKeys:
                                       @"&", @"&amp;",
                                       @"<", @"&lt;",
                                       @">", @"&gt;",
                                       @"'", @"&quot;",                           
                                       nil
                                       ] autorelease];
  
  for(NSString *stringToSubstitute in stringSubstitutions) {
    [escaped replaceOccurrencesOfString:stringToSubstitute
                             withString:[stringSubstitutions objectForKey:stringToSubstitute]
                                options:(NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch)
                                  range:NSMakeRange(0, [escaped length])
     ];
  }
  
  return escaped;    // Note this is autoreleased
}

@end
