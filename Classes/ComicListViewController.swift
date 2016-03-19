//
//  ComicListViewController.swift
//  xkcd
//
//  Created by Paul Rehkugler on 1/28/16.
//
//

import CoreData
import MessageUI
import UIKit

final class ComicListViewController: UITableViewController {
	var requestedLaunchComic: Int?
	
	func indexPathForComicNumbered(comicNumber: Int) -> NSIndexPath? {
		
	}
	
	// MARK: - UIViewController
	
	override init(style: UITableViewStyle) {
		searchController = UISearchController(searchResultsController: nil)
		comicFetcher = NewComicFetcher()
		imageFetcher = SingleComicImageFetcher(URLSession: NSURLSession.sharedSession())
		
		super.init(style: style)
		
		self.title = NSLocalizedString("xkcd", comment: "Title of the main view.")
		searchController.searchResultsUpdater = self
		comicFetcher.delegate = self
		imageFetcher.delegate = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		addRefreshControl()
		addNavigationBarButtons()
		addSearchBarTableHeader()
		setFetchedResultsController()
		
		reloadAllData()
		scrollToComicAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))

		checkForNewComics()
		
		if
			let requestedLaunchComic = self.requestedLaunchComic,
			let indexPath = indexPathForComicNumbered(requestedLaunchComic)
		{
			scrollToComicAtIndexPath(indexPath)
			
			if let comic = Comic.comicNumbered(requestedLaunchComic) {
				viewComic(comic)
			}
		}
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Private
	
	private static let downloadImage = UIImage(named: "download")!.imageWithRenderingMode(.AlwaysTemplate)

	private let searchController: UISearchController
	private let comicFetcher: NewComicFetcher
	private let imageFetcher: SingleComicImageFetcher

	private var fetchedResultsController: NSFetchedResultsController
	
	private func addSearchBarTableHeader() {
		let searchBar = searchController.searchBar
		searchBar.autoresizingMask = .FlexibleWidth
		searchBar.sizeToFit()
		searchBar.placeholder = NSLocalizedString("Search xkcd", comment: "Search bar placeholder.")
		searchBar.autocapitalizationType = .None
		
		tableView.tableHeaderView = searchBar
	}
	
	private func addRefreshControl() {
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: Selector("checkForNewComics"), forControlEvents: .ValueChanged)
		
		self.refreshControl = refreshControl
	}
	
	private func addNavigationBarButtons() {
		let systemItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("systemAction:"))
		navigationItem.leftBarButtonItem = systemItem
		
		let editButtonItem = self.editButtonItem()
		editButtonItem.target = self
		editButtonItem.action = Selector("edit:")
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	private func setFetchedResultsController() {
		fetchedResultsController = fetchedResultsControllerWithSearchString(nil)
		
		do {
			try fetchedResultsController.performFetch()
		}
		catch let error as NSError {
			print("List fetch failed: \(error.description)")
		}
	}
	
	private func fetchedResultsControllerWithSearchString(searchString: String?) -> NSFetchedResultsController {
		let fetchRequest = NSFetchRequest()
		fetchRequest.entity = Comic.entityDescription()
		
		if let query = searchString {
			fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] \(query) OR titleText CONTAINS[cd] \(query) OR transcript CONTAINS[cd] \(query) or number = \(Int(query))", argumentArray: nil)
		}
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: false)]
		
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedCoreDataStack().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
		fetchedResultsController.delegate = self
		return fetchedResultsController
	}
	
	private func reloadAllData() {
		tableView.reloadData()
	}
	
	private func scrollToComicAtIndexPath(indexPath: NSIndexPath) {
		guard
			tableView.numberOfSections <= indexPath.section
			&& tableView.numberOfRowsInSection(indexPath.section) < indexPath.row
			else {
				return
		}
		
		tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
	}
	
	private func checkForNewComics() {
		didStartRefreshing()
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		comicFetcher.fetch()
	}
	
	private func didStartRefreshing() {
		refreshControl?.beginRefreshing()
	}
	
	private func didFinishRefreshing() {
		refreshControl?.endRefreshing()
	}
}

extension ComicListViewController: NewComicFetcherDelegate {
	
}

extension ComicListViewController: NSFetchedResultsControllerDelegate {
	
}

extension ComicListViewController: SingleComicImageFetcherDelegate {
	
}

extension ComicListViewController: MFMailComposeViewControllerDelegate {
	
}

extension ComicListViewController: UIScrollViewDelegate {
	
}

extension ComicListViewController: UISearchResultsUpdating {
	
}