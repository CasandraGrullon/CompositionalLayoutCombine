//
//  ViewController.swift
//  CompositionalLayoutCombine
//
//  Created by casandra grullon on 8/25/20.
//  Copyright © 2020 casandra grullon. All rights reserved.
//

import UIKit
import Combine //asynchronous programming framework introduced in iOS 13
import Kingfisher

class PhotoSearchViewController: UIViewController {
    
    enum SectionKind: Int, CaseIterable {
        case main
    }
    private var collectionView: UICollectionView!
    typealias DataSource = UICollectionViewDiffableDataSource<SectionKind, Photo>
    private var dataSource: DataSource!
    
    private var searchController: UISearchController!
    //COMBINE:
    // in order to make any property a publisher you need to append @Published
    // publisher -> emits changes from the search bar to the search controller
    // to subscribe to the searchText's Publisher, prefix a $
    @Published private var searchText = ""
    // store subscriptions, without this the publisher will never emit values
    private var subscriptions: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Photo Search"
        view.backgroundColor = .systemBackground
        configureCollectionView()
        configureDataSource()
        configureSearchController()
        subscribeToPublisher()
    }
    private func searchPhotos(for query: String) {
        APIClient().searchPhotos(for: query)
            .sink(receiveCompletion: { (completion) in
                print(completion)
            }) { [weak self] (photos) in
                self?.updateSnapshot(with: photos)
        }
    .store(in: &subscriptions)
    }
    private func subscribeToPublisher() {
        //combine:
        $searchText
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main) //async
            .removeDuplicates()
            .sink { [weak self] (text) in //sink recieves values
                self?.searchPhotos(for: text)
                //call the api client for the photo search queue
        }
            .store(in: &subscriptions) //store them to our set
    }
    private func updateSnapshot(with photos: [Photo]) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections([.main])
        snapshot.appendItems(photos)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    private func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
    }
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let insetSize: CGFloat = 5
            item.contentInsets = NSDirectionalEdgeInsets(top: insetSize, leading: insetSize, bottom: insetSize, trailing: insetSize)
            
            let innerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
            let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: innerGroupSize, subitem: item, count: 2)
            let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: innerGroupSize, subitem: item, count: 3)
            
            let nestedGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(1000))
            let nestedGroup = NSCollectionLayoutGroup.horizontal(layoutSize: nestedGroupSize, subitems: [leadingGroup, trailingGroup])
            
            let section = NSCollectionLayoutSection(group: nestedGroup)
            
            return section
        }
        return layout
    }
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView, cellProvider: { (collectionView, indexPath, photo) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as? ImageCell else {
                fatalError("could not dequeue image cell")
            }
            cell.imageView.kf.setImage(with: URL(string: photo.webformatURL))
            return cell
        })
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([.main])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
}
extension PhotoSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            return
        }
        searchText = text
        //after assigning a new value to searchText, the subscriber will recieve the value
    }
}
