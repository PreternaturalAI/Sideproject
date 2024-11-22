//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 22/11/24.
//

import Foundation

extension String {
    public init(url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        try self.init(data: data)
    }
}
