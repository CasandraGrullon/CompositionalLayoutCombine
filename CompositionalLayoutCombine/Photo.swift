//
//  Photo.swift
//  CompositionalLayoutCombine
//
//  Created by casandra grullon on 8/25/20.
//  Copyright © 2020 casandra grullon. All rights reserved.
//

import Foundation

struct PhotoResultsWrapper: Decodable {
  let hits: [Photo]
}

struct Photo: Decodable, Hashable {
  let id: Int
  let webformatURL: String
}
