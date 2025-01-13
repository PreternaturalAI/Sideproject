//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 28/11/24.
//

import Foundation

extension String {
    func deletingPrefix(
        _ prefix: String
    ) -> String {
        guard hasPrefix(prefix) else {
            return self
        }
        
        return String(dropFirst(prefix.count))
    }
}
