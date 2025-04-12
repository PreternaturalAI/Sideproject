//
//  ModelSearchVIew.Tab.swift
//  Sideproject
//
//  Created by Jared Davidson on 4/12/25.
//

import SwiftUI

extension ModelSearchView {
    public enum Tab {
        case discover
        case downloaded
        
        var keyPath: KeyPath<ModelStore, [ModelStore.Model]> {
            switch self {
                case .discover: return \ModelStore.models
                case .downloaded: return \ModelStore.downloadedModels
            }
        }
    }
}


// MARK: - Conformances

extension ModelSearchView.Tab: CustomStringConvertible, CaseIterable {
    public var description: String {
        switch self {
            case .discover: "Discover"
            case .downloaded: "Downloaded"
        }
    }
}
