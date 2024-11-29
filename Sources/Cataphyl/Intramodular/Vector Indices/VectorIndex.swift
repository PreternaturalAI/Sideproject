//
// Copyright (c) Vatsal Manot
//

import Foundation
import LargeLanguageModels
import Swallow

import CoreML

public protocol VectorIndex<Key>: Sendable {
    associatedtype Key: Hashable
    
    func query<Query: VectorIndexQuery<Key>>(
        _ query: Query
    ) async throws -> [VectorIndexQueryResultItem<Self>]
}

/// A vector index.
public protocol _NoasyncVectorIndex<Key>: VectorIndex, Sendable {
    func query<Query: VectorIndexQuery<Key>>(
        _ query: Query
    ) throws -> [VectorIndexQueryResultItem<Self>]
}

public protocol MutableVectorIndex<Key>: VectorIndex {
    mutating func insert(
        contentsOf pairs: some Sequence<(Key, [Double])>
    ) async throws
    
    mutating func remove(
        _ items: Set<Key>
    ) async throws
    
    mutating func removeAll() async throws
}

/// A vector index that supports insertion/removal.
public protocol _NoasyncMutableVectorIndex<Key>: _NoasyncVectorIndex, MutableVectorIndex, Sendable {
    mutating func insert(contentsOf pairs: some Sequence<(Key, [Double])>) throws
    mutating func remove(_ items: Set<Key>) throws
    mutating func removeAll() throws
}

// MARK: - Extensions

extension MutableVectorIndex {
    public mutating func insert(
        _ vector: [Double],
        forKey key: Key
    ) async throws {
        try await insert(contentsOf: [(key, vector)])
    }
    
    public mutating func insert(
        contentsOf pairs: some Sequence<(Key, _RawTextEmbedding)>
    ) async throws {
        try await insert(contentsOf: pairs.lazy.map({ ($0, $1.rawValue) }))
    }
    
    public mutating func remove(
        forKey key: Key
    ) async throws {
        try await remove([key])
    }
}

extension _NoasyncMutableVectorIndex {
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
    
    public mutating func remove(_ items: some Sequence<Key>) throws {
        try remove(Set(items))
    }
}

// MARK: - Auxiliary

public enum VectorIndices: _StaticSwift.Namespace {
    
}

public struct VectorIndexQueryResultItem<Index: VectorIndex> {
    public let item: Index.Key
    public let score: Double
}

public enum VectorIndexError: Error {
    case unsupportedQuery(any VectorIndexQuery)
}

// MARK: - Deprecated

public typealias VectorIndexSearchResult = VectorIndexQueryResultItem
