//
//  NewComicFetcherDelegate.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/28/16.
//
//

import Foundation

/**
 *  A `NewComicImageFetcherDelegate` is an object that receives updates about events
 *  in the `NewComicImageFetcher`'s lifecyle.
 */
protocol NewComicFetcherDelegate: class {
	
   /**
	Notifies the receiver that the `NewComicImageFetcher` fetched a `Comic`.
	
	- parameter fetcher: The `NewComicImageFetcher` that triggered this message.
	- parameter comic:   The `Comic` that has been fetched.
	*/
	func newComicFetcher(fetcher: NewComicFetcher, didFetchComic comic: Comic)
	
   /**
	Notifies the receiver that the `NewComicImageFetcher` fetched all `Comic`s.
	
	- parameter fetcher: The `NewComicImageFetcher` that triggered this message.
	*/
	func newComicFetcherDidFinishFetchingAllComics(fetcher: NewComicFetcher)
	
   /**
	Notifies the receiver that the `NewComicImageFetcher` failed fetching a `Comic`.
	
	- parameter fetcher: The `NewComicImageFetcher` that triggered this message.
	- parameter error:   The `NSError` representation of the failure.
	*/
	func newComicFetcher(fetcher: NewComicFetcher, didFailWithError error: NSError)
}
