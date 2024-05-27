//
// Copyright (c) Vatsal Manot
//

import Swallow

extension VectorIndices {
    /// A vector index that is a lazily-evaluated index over a collection of vector indices.
    ///
    /// Like `Publishers.MergeMany` but for vector indices.
    public struct MergeMany<Base: RandomAccessCollection>: VectorIndex where Base.Element: VectorIndex {
        public typealias Key = Base.Element.Key
        
        private let base: Base
        
        public init(_ base: Base) {
            self.base = base
        }
        
        public func query<Query: VectorIndexQuery<Key>>(
            _ query: Query
        ) throws -> [VectorIndexSearchResult<Self>] {
            switch query {
                case let query as VectorIndexQueries.TopK<Key>:
                    return try base
                        .flatMap({ try $0.query(query) })
                        .sorted(by: { $0.score > $1.score })
                        .prefix(query.maximumNumberOfResults)
                        .map {
                            VectorIndexSearchResult(item: $0.item, score: $0.score)
                        }
                default:
                    throw VectorIndexError.unsupportedQuery(query)
            }
        }
    }
}
