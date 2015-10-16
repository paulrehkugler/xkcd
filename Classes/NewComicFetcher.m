//
//  NewComicFetcher.m
//  xkcd
//
//  Created by Joshua Bleecher Snyder on 9/1/09.
//  Copyright 2009 Treeline Labs. All rights reserved.
//

#define RECREATE_FROM_SCRATCH 0

// When [comicsToInsert count] reaches kInsertChunkSize,
// comics will be inserted in bulk.
// Inserting one at a time creates a crappy ux.
#define kInsertChunkSize 25

#import "NewComicFetcher.h"
#import "FetchComicFromWeb.h"
#import "Comic.h"
#import "XkcdErrorCodes.h"
#import "TLMacros.h"

#pragma mark -

@interface NewComicFetcher ()

- (void)fetchComic:(NSInteger)comicNumber;

@property (nonatomic) NSOperationQueue *fetchQueue;
@property (nonatomic) NSMutableArray *comicsToInsert;

@end

#pragma mark -

@implementation NewComicFetcher

- (instancetype)init {
	if (self = [super init]) {
		_fetchQueue = [[NSOperationQueue alloc] init];
		_comicsToInsert = [NSMutableArray arrayWithCapacity:kInsertChunkSize];
	}
	return self;
}

- (void)fetchComic:(NSInteger)comicNumber {
	FetchComicFromWeb *fetchOperation = [[FetchComicFromWeb alloc] initWithComicNumber:comicNumber
																	  completionTarget:self
																				action:@selector(didCompleteFetchOperation:)];
	[self.fetchQueue addOperation:fetchOperation];
}

- (void)fetch {
	Comic *lastKnownComic = [Comic lastKnownComic];
	if (lastKnownComic) {
		NSInteger comicToFetch = [lastKnownComic.number integerValue] + 1;
		[self fetchComic:comicToFetch];
	}
	else {
#if RECREATE_FROM_SCRATCH
		TLDebugLog(@"RECREATE_FROM_SCRATCH: Fetching comic 1");
		[Comic deleteAllComics];
		[self fetchComic:1];
#else
		[self.delegate newComicFetcher:self
					  didFailWithError:[NSError errorWithDomain:kXkcdErrorDomain
														   code:kXkcdErrorCodeCouldNotFindLastComic
													   userInfo:nil]];
#endif
	}
}

- (void)insertComics {
	for (FetchComicFromWeb *fetchOperation in self.comicsToInsert) {
		Comic *newComic = [Comic comic];
		newComic.number = @(fetchOperation.comicNumber);
		newComic.name = fetchOperation.comicName;
		newComic.titleText = fetchOperation.comicTitleText;
		newComic.imageURL = fetchOperation.comicImageURL;
		newComic.transcript = fetchOperation.comicTranscript;
		[self.delegate newComicFetcher:self didFetchComic:newComic];
	}
	[self.comicsToInsert removeAllObjects];
}

- (void)didCompleteFetchOperation:(FetchComicFromWeb *)fetchOperation {
	if (fetchOperation.got404) {
		// all done!
		[self insertComics];
		[self.delegate newComicFetcherDidFinishFetchingAllComics:self];
	}
	else if (fetchOperation.error) {
		// Network fail? Change in API?
		[self insertComics];
		[self.delegate newComicFetcher:self didFailWithError:fetchOperation.error];
	}
	else if (fetchOperation.comicName && fetchOperation.comicTitleText && fetchOperation.comicImageURL && fetchOperation.comicTranscript) {
		// Got a comic -- store it and keep going
		[self.comicsToInsert addObject:fetchOperation];
		[self fetchComic:(fetchOperation.comicNumber + 1)];
		if (fetchOperation.comicNumber % kInsertChunkSize == 0) {
			[self insertComics];
		}
	}
	else {
		// wtf?
		[self insertComics];
	}
}

@end
