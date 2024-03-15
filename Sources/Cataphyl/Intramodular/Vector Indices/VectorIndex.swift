//
// Copyright (c) Vatsal Manot
//

import Foundation
import LargeLanguageModels
import Swallow

/// A vector index.
public protocol VectorIndex<Key>: AsyncVectorIndex {
    func query<Query: VectorIndexQuery<Key>>(
        _ query: Query
    ) throws -> [VectorIndexSearchResult<Self>]
}

/// A vector index that supports insertion/removal.
public protocol MutableVectorIndex<Key>: VectorIndex, MutableAsyncVectorIndex {
    mutating func insert(contentsOf pairs: some Sequence<(Key, [Double])>) throws
    mutating func remove(_ items: Set<Key>) throws
    mutating func removeAll() throws
}

// MARK: - Extensions

extension MutableVectorIndex {
    /// Insert a vector for a given key.
    public mutating func insert(
        _ vector: [Double],
        forKey key: Key
    ) throws {
        try insert(contentsOf: [(key, vector)])
    }
    
    public mutating func insert(
        contentsOf pairs: some Sequence<(Key, _RawTextEmbedding)>
    ) throws {
        try insert(contentsOf: pairs.lazy.map({ ($0, $1.rawValue) }))
    }
    
    /// Remove the vector associated with a given key.
    public mutating func remove(
        forKey key: Key
    ) throws {
        try remove([key])
    }
}

// MARK: - Auxiliary

public struct VectorIndexSearchResult<Index: AsyncVectorIndex> {
    public let item: Index.Key
    public let score: Double
}

public enum VectorIndexError: Error {
    case unsupportedQuery(any VectorIndexQuery)
}
