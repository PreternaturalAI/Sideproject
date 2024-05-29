//
// Copyright (c) Vatsal Manot
//

import CorePersistence
import Foundation
import Swallow
import _USearch

public struct _USearchIndex {
    public typealias Metric = USearchMetric
    
    public struct Configuration: Codable, Hashable, Sendable {
        public var index: USearchMetric
    }
}

extension _USearchIndex: _FileDocument {
    public init(
        configuration: ReadConfiguration
    ) throws {
        fatalError()
    }
    
    public func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        fatalError()
    }
}

extension USearchMetric: Codable {
    public init(from decoder: Decoder) throws {
        self = try Self(rawValue: try RawValue(from: decoder)).unwrap()
    }
    
    public func encode(to encoder: Encoder) throws {
        try rawValue.encode(to: encoder)
    }
}

public typealias USearchScalar = _USearch.USearchScalar
public typealias USearchMetric = _USearch.USearchMetric

public final class USearchIndex {
    let index: _USearch.USearchIndex
    
    enum State {
        case initialized
        case loaded
        case viewing
    }
    
    var state: State = .initialized
    
    public init(
        metric: USearchMetric,
        dimensions: UInt32,
        connectivity: UInt32,
        quantization: USearchScalar
    ) {
        index = _USearch.USearchIndex.make(
            metric: metric,
            dimensions: dimensions,
            connectivity: connectivity,
            quantization: quantization
        )
        
        state = .initialized
    }
    
    enum Error: Swift.Error, LocalizedError {
        case indexNotFound
        case alreadyLoaded
        case mutationNotAllowedInViewingIndex
        case invalidVectorSize
        case exception(Swift.Error)
        
        var errorDescription: String? {
            switch self {
                case .indexNotFound:
                    return "Can not find the index file."
                case .alreadyLoaded:
                    return "Index already loaded."
                case .mutationNotAllowedInViewingIndex:
                    return "Mutation not allowed in viewing index."
                case .invalidVectorSize:
                    return "Invalid vector size."
                case .exception(let error):
                    return error.localizedDescription
            }
        }
    }
    
    public func load(path: String) throws {
        guard state != .loaded else {
            throw Error.alreadyLoaded
        }
        
        guard FileManager.default.fileExists(atPath: path) else {
            throw Error.indexNotFound
        }
        
        self.index.load(path: path)
        
        state = .loaded
    }
    
    public func view(
        path: String
    ) throws {
        guard state != .loaded else {
            throw Error.alreadyLoaded
        }
        
        guard FileManager.default.fileExists(atPath: path) else {
            throw Error.indexNotFound
        }
        
        self.index.view(path: path)
        
        state = .viewing
    }
    
    public func save(
        path: String
    ) throws {
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        }
        
        self.index.save(path: path)
    }
    
    public func clear() throws {
        guard state != .viewing else {
            throw Error.mutationNotAllowedInViewingIndex
        }
        
        self.index.clear()
    }
    
    public func add(
        label: USearchKey,
        vector: [Float]
    ) throws {
        guard state != .viewing else {
            throw Error.mutationNotAllowedInViewingIndex
        }
        
        guard vector.count == index.dimensions else {
            throw Error.invalidVectorSize
        }
        
        if index.count + 1 >= index.capacity {
            index.reserve(UInt32(index.count + 1))
        }
        
        self.index.add(key: label, vector: vector[...])
    }
    
    public func set(items: [(label: USearchKey, vector: [Float])]) throws {
        guard state != .viewing else { throw Error.mutationNotAllowedInViewingIndex }
        
        try clear()
        
        index.reserve(UInt32(items.count))
        
        for item in items {
            self.index.add(key: item.label, vector: item.vector[...])
        }
    }
    
    public func search(
        vector: [Float],
        count: Int
    ) throws -> [(label: USearchKey, distance: Float)] {
        guard vector.count == index.dimensions else {
            throw Error.invalidVectorSize
        }
        
        var result: ([USearchKey], [Float]) = ([], [])
        
        result = self.index.search(vector: vector[...], count: count)
        
        return zip(result.0, result.1).map({ ($0, $1) })
    }
}
