//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// A type that represents a query for a vector index.
///
/// This is a protocol (instead of say, an enum) in order to future-proof for complex query types that can't be anticipated at the moment.
public protocol RawVectorIndexQuery<Item> {
    associatedtype Item
}

// MARK: - Implemented Conformances

extension RawVectorIndexQueries {
    /// A k-nearest neighbor search.
    ///
    /// Reference:
    /// - https://www.elastic.co/guide/en/elasticsearch/reference/current/knn-search.html
    public struct TopK<Item>: RawVectorIndexQuery {
        public let vector: [Double]
        public let maximumNumberOfResults: Int
        
        public init(vector: [Double], maximumNumberOfResults: Int) {
            self.vector = vector
            self.maximumNumberOfResults = maximumNumberOfResults
        }
    }
}

extension RawVectorIndexQuery {
    /// A query representing a k-nearest neighbor search for a given vector.
    public static func topMatches<T>(
        for vector: [Double],
        maximumNumberOfResults: Int
    ) -> Self where Self == RawVectorIndexQueries.TopK<T> {
        Self(
            vector: vector,
            maximumNumberOfResults: maximumNumberOfResults
        )
    }
    
    public static func topMatches<T>(
        for textEmbedding: _RawTextEmbedding,
        maximumNumberOfResults: Int
    ) -> Self where Self == RawVectorIndexQueries.TopK<T> {
        Self.topMatches(
            for: textEmbedding.rawValue,
            maximumNumberOfResults: maximumNumberOfResults
        )
    }
    
    public static func topMatches<T>(
        for textEmbedding: SingleTextEmbedding,
        maximumNumberOfResults: Int
    ) -> Self where Self == RawVectorIndexQueries.TopK<T> {
        Self.topMatches(
            for: textEmbedding.embedding.rawValue,
            maximumNumberOfResults: maximumNumberOfResults
        )
    }
}

// MARK: - Auxiliary

public enum RawVectorIndexQueries {
    
}
