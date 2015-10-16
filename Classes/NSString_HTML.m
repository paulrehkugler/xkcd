//
//  NSString_HTML.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 2/17/10.
//

#import "NSString_HTML.h"
#import "TLMacros.h"

static NSArray *characterEntityArray = nil;

#pragma mark -

@interface HTMLStringCleaner : NSObject<NSXMLParserDelegate>

+ (NSString *)cleanedStringFromHTMLSnippet:(NSString *)HTMLSnippet;

@end

#pragma mark -

@interface HTMLStringCleaner ()

+ (NSString *)stringByDecodingCharacterEntitiesIn:(NSString *)source;
- (instancetype)initWithHTMLSnippet:(NSString *)HTMLSnippet;
- (NSString *)cleanedString;

@property (nonatomic) NSString *snippet;
@property (nonatomic) NSMutableString *resultAccumulator;
@property (nonatomic) BOOL parseErrorEncountered;

@end

#pragma mark -

@implementation HTMLStringCleaner

+ (NSString *)cleanedStringFromHTMLSnippet:(NSString *)HTMLSnippet {
	HTMLStringCleaner *cleaner = [[self alloc] initWithHTMLSnippet:HTMLSnippet];
	return [cleaner cleanedString];
}

// borrowed from http://www.thinkmac.co.uk/blog/2005/05/removing-entities-from-html-in-cocoa.html
// ...and fixed a little
+ (NSString *)stringByDecodingCharacterEntitiesIn:(NSString *)source {
	if (!source) {
		return nil;
	}
	
	NSMutableString *escaped = [NSMutableString stringWithString:source];
	if (!characterEntityArray) {
		characterEntityArray = @[@"&nbsp;", @"&iexcl;", @"&cent;", @"&pound;", @"&curren;", @"&yen;", @"&brvbar;",
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
								 @"&uacute;", @"&ucirc;", @"&uuml;", @"&yacute;", @"&thorn;", @"&yuml;"];
	}
	
	NSUInteger i;
	NSUInteger count = [characterEntityArray count];
	
	// Html
	for (i = 0; i < count; i++) {
		NSRange range = [source rangeOfString:characterEntityArray[i]];
		if (range.location != NSNotFound) {
			[escaped replaceOccurrencesOfString:characterEntityArray[i]
									 withString:[NSString stringWithFormat:@"%C", (unsigned short)(160 + i)]
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
		
		if (start.location != NSNotFound &&
			finish.location != NSNotFound &&
			finish.location > start.location) {
			
			NSRange entityRange = NSMakeRange(start.location, (finish.location - start.location) + 1);
			NSString *entity = [escaped substringWithRange:entityRange];
			NSString *value = [entity substringWithRange:NSMakeRange(2, [entity length] - 2)];
			
			[escaped deleteCharactersInRange:entityRange];
			
			if ([value hasPrefix: @"x"]) {
				unsigned int tempInt = 0;
				NSScanner *scanner = [NSScanner scannerWithString:[value substringFromIndex:1]];
				[scanner scanHexInt:&tempInt];
				[escaped insertString: [NSString stringWithFormat:@"%C", (unsigned short)tempInt] atIndex: entityRange.location];
			}
			else {
				[escaped insertString: [NSString stringWithFormat:@"%C", (unsigned short)[value intValue]] atIndex: entityRange.location];
			}
			i = start.location;
		}
		else {
			i++;
		}
		searchRange = NSMakeRange(i, [escaped length] - i);
	}
	
	return escaped;
}

- (instancetype)initWithHTMLSnippet:(NSString *)HTMLSnippet {
	if (self = [super init]) {
		_snippet = HTMLSnippet;
	}
	return self;
}

- (NSString *)cleanedString {
	self.resultAccumulator = [NSMutableString string];
	NSString *wrappedSnippet = [NSString stringWithFormat:@"<html>%@</html>", self.snippet];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[wrappedSnippet dataUsingEncoding:NSUTF8StringEncoding]];
	[parser setDelegate:self];
	[parser parse];
	NSString *tagFreeString = self.parseErrorEncountered ? self.snippet : self.resultAccumulator;
	NSString *cleanedString = [[self class] stringByDecodingCharacterEntitiesIn:tagFreeString];
	return cleanedString;
}

#pragma mark -
#pragma mark NSXMLParser delegate functions

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	[self.resultAccumulator appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	//  TLDebugLog(@"HTMLStringCleaner encountered parse error %@ on snippet %@", parseError, self.snippet);
	self.parseErrorEncountered = YES;
}

@end


@implementation NSString (HTML)

+ (NSString *)stringByCleaningHTML:(NSString *)HTMLSnippet {
	return [HTMLStringCleaner cleanedStringFromHTMLSnippet:HTMLSnippet];
}

@end
