//
//  TLMersenneTwister.h
//  TLCommon
//
//  Created by Joshua Bleecher Snyder on 9/11/09.
//

#import <Foundation/Foundation.h>

@interface TLMersenneTwister : NSObject

+ (unsigned long)randInt32; /* generates a random number on [0,0xffffffff]-interval */
+ (long)randInt31; /* generates a random number on [0,0x7fffffff]-interval */

+ (double)randRealClosed; /* generates a random number on [0,1]-real-interval */
+ (double)randRealClopen;  /* generates a random number on [0,1)-real-interval */
+ (double)randRealOpen; /* generates a random number on (0,1)-real-interval */
+ (double)randRealClopen53; /* generates a random number on [0,1) with 53-bit resolution*/

+ (void)setSeed:(unsigned long)newSeed; // note that this is only necessary if doing reproducibility testing or better seeds are required; time(NULL) seeding happens automatically

@end
