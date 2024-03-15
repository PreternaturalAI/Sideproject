//
// Copyright (c) Vatsal Manot
//

import Accelerate
import Foundation

extension vDSP {
    @inlinable
    public static func euclideanDistance<U: AccelerateMutableBuffer>(
        lhs: U,
        rhs: U
    ) -> Double where U.Element == Double {
        vDSP.distanceSquared(lhs, rhs).squareRoot()
    }
    
    @inlinable
    public static func euclideanDistance<U: AccelerateMutableBuffer>(
        lhs: U,
        rhs: U
    ) -> Float where U.Element == Float {
        vDSP.distanceSquared(lhs, rhs).squareRoot()
    }
}

extension vDSP {
    @inlinable
    public static func cosineSimilarity<U: AccelerateBuffer>(
        lhs: U,
        rhs: U
    ) -> Double where U.Element == Double {
        let dotProduct = vDSP.dot(lhs, rhs)
        
        let lhsMagnitude = vDSP.sumOfSquares(lhs).squareRoot()
        let rhsMagnitude = vDSP.sumOfSquares(rhs).squareRoot()
        
        return dotProduct / (lhsMagnitude * rhsMagnitude)
    }
    
    @inlinable
    public static func cosineSimilarity<U: AccelerateBuffer>(
        lhs: U,
        rhs: U
    ) -> Float where U.Element == Float {
        let dotProduct = vDSP.dot(lhs, rhs)
        
        let lhsMagnitude = vDSP.sumOfSquares(lhs).squareRoot()
        let rhsMagnitude = vDSP.sumOfSquares(rhs).squareRoot()
        
        return dotProduct / (lhsMagnitude * rhsMagnitude)
    }
}
