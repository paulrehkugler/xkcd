//
//  ExplainXkcdContentFetcher.h
//  xkcd
//
//  Created by Stuart McHattie on 22/06/2013.
//
//

#import <Foundation/Foundation.h>


@class ExplainXkcdContentFetcher;
@class Comic;


@protocol ExplainXkcdContentFetcherDelegate <NSObject>

@required

- (void)explainXkcdContentFetcher:(ExplainXkcdContentFetcher *)fetcher didFetchExplanationForComic:(Comic *)comic;
- (void)explainXkcdContentFetcher:(ExplainXkcdContentFetcher *)fetcher didFailWithError:(NSError *)error onComic:(Comic *)comic;

@end


@interface ExplainXkcdContentFetcher : NSObject

@property(nonatomic, weak, readwrite) id<ExplainXkcdContentFetcherDelegate> delegate;

-(void)fetchExplanationForComic:(Comic *)comic;

@end


