//
//  SwiftUIView.swift
//  Sideproject
//
//  Created by Purav Manot on 20/11/24.
//

import SwiftUIX

public struct ModelSearchView: View {
    @ObservedObject var modelStore: ModelStore
    @Binding var selection: ModelStore.Model.ID?

    @State private var selectedTab: Tab = .downloaded
    @State private var isShowingAllDownloads: Bool = false
    
    public var body: some View {
        NavigationSplitView {
            SideprojectAccountsView()
                .background(.black)
        } detail: {
            TableView(selectedTab: $selectedTab, selection: $selection)
                .padding()
        }
        .environmentObject(modelStore)
        .environmentObject(Sideproject.ExternalAccountStore.shared)
    }
}
