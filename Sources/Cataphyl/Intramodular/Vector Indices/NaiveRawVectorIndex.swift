//
// Copyright (c) Vatsal Manot
//

import Accelerate
import Foundation
import OrderedCollections
import Swallow

/// A naive vector index that uses an in-memory ordered dictionary to store vectors.
///
/// While the cosine-similarity metric used to calculate scores is hardware accelerated, this index is still termed 'naive' because it uses a simple brute-force search as opposed to something optimized for large amounts of data (such as ANN/HNSW).
public struct NaiveRawVectorIndex<Key: Hashable>: Initiable, MutableRawVectorIndex {
    public var storage: OrderedDictionary<Key, [Double]> = [:]
    
    public var keys: OrderedSet<Key> {
        storage.keys
    }
    
    public init() {
        
    }
    
    @inline(__always)
    public mutating func insert(
        contentsOf pairs: some Sequence<(Key, [Double])>
    ) {
        self.storage.merge(
            OrderedDictionary(
                uniqueKeysWithValues: pairs.lazy.map({ ($0, $1) })
            ),
            uniquingKeysWith: {
                lhs,
                rhs in lhs
            }
        )
    }
    
    @inline(__always)
    public mutating func remove(_ items: Set<Key>) {
        for item in items {
            storage.removeValue(forKey: item)
        }
    }
    
    @inline(__always)
    public mutating func removeAll() {
        storage.removeAll()
    }
    
    @inline(__always)
    public func query(
        _ query: some RawVectorIndexQuery<Key>
    ) throws -> [VectorIndexSearchResult<Self>] {
        switch query {
            case let query as RawVectorIndexQueries.TopK<Key>:
                return rank(
                    query: query.vector,
                    topK: query.maximumNumberOfResults,
                    using: vDSP.cosineSimilarity
                )
            default:
                throw VectorIndexError.unsupportedQuery(query)
        }
    }
    
    @inline(__always)
    private func rank(
        query: [Double],
        topK: Int,
        using metric: ([Double], [Double]) -> Double
    ) -> [VectorIndexSearchResult<Self>] {
        let similarities: [Double] = storage.map({ metric($0.value, query) })
        
        // Find the indices of top-k similarity values
        let sortedCollections = (0..<similarities.count).sorted(by: {
            similarities[$0] > similarities[$1]
        })
        let topIndices = Array(sortedCollections.prefix(topK))
        
        return topIndices.map {
            VectorIndexSearchResult(
                item: storage.elements[$0].key,
                score: similarities[$0]
            )
        }
    }
}

// MARK: - Implemented Conformances

extension NaiveRawVectorIndex: Hashable {
    public func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }
}

extension NaiveRawVectorIndex: Sequence {
    public func makeIterator() -> AnyIterator<Key> {
        storage.keys.makeIterator().eraseToAnyIterator()
    }
}

extension NaiveRawVectorIndex: Codable where Key: Codable {
    public init(from decoder: Decoder) throws {
        self.storage = try OrderedDictionary(uniqueKeysWithValues: Dictionary(from: decoder))
    }
    
    public func encode(to encoder: Encoder) throws {
        try Dictionary(storage).encode(to: encoder)
    }
}
