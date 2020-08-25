//
//  APIClient.swift
//  CompositionalLayoutCombine
//
//  Created by casandra grullon on 8/25/20.
//  Copyright © 2020 casandra grullon. All rights reserved.
//

import Foundation
import Combine

class APIClient {
    public func searchPhotos(for query: String) -> AnyPublisher<[Photo], Error> {
        let perPage = 200
        let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "paris"
        let endpoint = "https://pixabay.com/api/?key=\(Config.apiKey)&q=\(searchQuery)&per_page=\(perPage)&safesearch=true"
        //TODO: refactor to guard
        let url = URL(string: endpoint)!
        //using Combine for networking
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data) //1. get data from url session
            .decode(type: PhotoResultsWrapper.self, decoder: JSONDecoder()) //2. decode the data
            .map { $0.hits } //3. get only the hits -> [Photo]
            .receive(on: DispatchQueue.main) //4. recieve on main thread
            .eraseToAnyPublisher() //5. doesnt expose all inner workings of publisher. only returns the publisher we need
    }
}
