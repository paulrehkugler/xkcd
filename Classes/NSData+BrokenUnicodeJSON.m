//
//  NSData+BrokenUnicodeJSON.m
//

#import "NSData+BrokenUnicodeJSON.h"

@implementation NSData (BrokenUnicodeJSON)

// convert a hex char (i.e. an ascii digit or character in a..f or A..F)
// into the number (uint8_t in range 0..15) that it corresponds to.
// if the input is not a valid ascii hex char, returns UINT8_MAX.
uint8_t nibble_for_hex(char hex_char) {
	if (hex_char >= '0' && hex_char <= '9') {
		return hex_char - '0';
	}
	if (hex_char >= 'a' && hex_char <= 'f') {
		return hex_char - 'a' + 10;
	}
	if (hex_char >= 'A' && hex_char <= 'F') {
		return hex_char - 'A' + 10;
	}
	
	// not a valid input
	return UINT8_MAX;
}

- (NSData *)dataByFixingFuckedUpUnicodeInJSON {
	// TODO: This is a quick test hack. Needs unit tests, safety, bounds checking, defensive coding, etc.
	NSData *rawCharMarker = [NSData dataWithBytes:"\\u00" length:4];
	NSMutableData *fixedData = [self mutableCopy];
	
	BOOL moreToFix = YES;
	NSUInteger minLocation = 0;
	// it's safe to use a minLocation even though our data is mutable, since we're doing our
	// work from the beginning of the data, and only ever shortening it
	
	while(moreToFix) {
		NSRange rawCharRange = [fixedData rangeOfData:rawCharMarker options:0 range:NSMakeRange(minLocation, fixedData.length - minLocation)];
		if (rawCharRange.location == NSNotFound) {
			moreToFix = NO;
		}
		else {
			const char *chars = (const char *)[fixedData bytes];
			
			if (NSMaxRange(rawCharRange) + 2 < fixedData.length) {
				const char first_char = chars[rawCharRange.location + 4];
				const char second_char = chars[rawCharRange.location + 5];
				
				uint8_t first_nibble = nibble_for_hex(first_char);
				uint8_t second_nibble = nibble_for_hex(second_char);
				
				if (first_nibble == UINT8_MAX || second_nibble == UINT8_MAX) {
					// not valid hex (wtf?), skip
					minLocation = NSMaxRange(rawCharRange);
				}
				else {
					// valid hex, do the conversion
					char extracted_char = first_nibble << 4 | second_nibble;
					[fixedData replaceBytesInRange:NSMakeRange(rawCharRange.location, 6) // 6 == len of marker + two hex chars
										 withBytes:&extracted_char
											length:1];
				}
			}
			else {
				// need two hex chars to convert, no point in skipping ahead and looking more
				// because we're at the end of the data, so just be done
				moreToFix = NO;
			}
		}
	}
	
	return [fixedData copy];
}

@end
