//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 29/11/24.
//

import Foundation
import SwiftUIX

extension ModelSearchView {
    public struct TableView: View {
        @EnvironmentObject private var modelStore: ModelStore
        @EnvironmentObject private var accountStore: Sideproject.ExternalAccountStore
        
        @Binding private var selectedTab: ModelSearchView.Tab
        @Binding private var selection: ModelStore.Model.ID?

        @State private var sortOrder: [KeyPathComparator<ModelStore.Model>] = [KeyPathComparator(\ModelStore.Model.size), KeyPathComparator(\ModelStore.Model.name), KeyPathComparator(\ModelStore.Model.lastUsed)]
        @State private var searchText: String = ""
        
        private var models: [ModelStore.Model] {
            modelStore[keyPath: selectedTab.keyPath]
                .sorted(using: sortOrder)
                .filter(filterPredicate)
        }
        
        public init(selectedTab: Binding<ModelSearchView.Tab>, selection: Binding<ModelStore.Model.ID?>) {
            self._selectedTab = selectedTab
            self._selection = selection
        }
        
        public var body: some View {
            Table(of: ModelStore.Model.self, selection: $selection, sortOrder: $sortOrder) {
                tableColumnContent
            } rows: {
                tableRowContent
            }
            .tableStyle(.inset)
            .animation(.bouncy, value: modelStore.models)
            .alternatingRowBackgrounds(.disabled)
            .safeAreaInset(edge: .bottom, alignment: .leading) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        Image(systemName: .plus)
                        
                        Image(systemName: .minus)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(.background)
                }
            }
            .border(.quaternary, width: 1)
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Picker(selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.description)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .searchable(text: $searchText, placement: .toolbar)
            .onSubmit(of: .search) {
                Task {
                    do {
                        try await attemptDownload(for: searchText, using: Sideproject.ExternalAccountStore.shared)
                    } catch {
                        print(error)
                        print(error.localizedDescription)
                    }
                }
            }
        }
        
        @TableColumnBuilder<ModelStore.Model, KeyPathComparator<ModelStore.Model>>
        var tableColumnContent: some TableColumnContent<ModelStore.Model, KeyPathComparator<ModelStore.Model>> {
            TableColumn("Name") { (model: ModelStore.Model) in
                HStack {
                    Image(systemName: .cube)
                        .symbolRenderingMode(.hierarchical)
                        .font(.title)
                        .foregroundStyle(model.isOnDisk ? Color.blue.opacity(0.8) : Color.secondary)
                        .padding(.horizontal, 5)
                    
                    Text(model.name)
                        .font(.subheadline)
                }
                .frame(height: 32)
                .frame(minWidth: 50)
            }
            .width(min: 120, ideal: 150)
            
            TableColumn("Last Used") { (model: ModelStore.Model) in
                Group {
                    if let date = model.lastUsed {
                        Text(date, format: .relative(presentation: .named))
                    } else {
                        Text("--")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
            }
            .width(min: 50, ideal: 100)
            
            TableColumn("Info", sortUsing: KeyPathComparator(\.size)) { (model: ModelStore.Model) in
                HStack {
                    if selectedTab == .discover {
                        ModelDownloadButton(model: model)
                            .environmentObject(modelStore)
                            .environmentObject(accountStore)
                    } else {
                        Text(model.sizeDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .width(min: 50, ideal: 100)
            .alignment(.trailing)
        }
        
        @TableRowBuilder<ModelStore.Model>
        var tableRowContent: some TableRowContent<ModelStore.Model> {
            Section("Downloads") {
                ForEach(modelStore.activeDownloadKeys, id: \.self) { (id: ModelStore.Model.ID) in
                    if let model: ModelStore.Model = models.first (where: { $0.id == id }) {
                        TableRow(model)
                    }
                }
            }
            
            Section(selectedTab == .discover ? "All models" : "Your models") {
                ForEach(models) { model in
                    TableRow(model)
                        .contextMenu {
                            Button("Copy Name") {
                                NSPasteboard.general.setString(model.name, forType: .string)
                            }
                            Button("Show in Finder") {
                                if let url = model.url {
                                    NSWorkspace.shared.selectFile(url.path(percentEncoded: false), inFileViewerRootedAtPath: "")
                                }
                            }
                            .disabled(model.url == nil)
                            
                            Button("Remove..") {
                                modelStore.delete(model.id)
                            }
                            .disabled(!model.isOnDisk)
                        }
                }
            }
        }
        
        @discardableResult
        private func attemptDownload(for searchText: String, using accountStore: Sideproject.ExternalAccountStore) async throws -> URL? {
            var urlString = searchText
            guard urlString.contains("huggingface") else { return nil }
            
            if !urlString.hasPrefix("https://") {
                urlString = "https://" + urlString
            }
            
            guard let url = URL(string: urlString) else { return nil }
            var components = url.pathComponents
            
            components.removeAll { $0 == "/" }
            let name = components.joined(separator: "/")
            
            if !modelStore.models.map({ $0.name }).contains(name) {
                return nil
            }
            
            return try await modelStore.download(modelNamed: name, using: accountStore)
        }
        
        private func filterPredicate(model: ModelStore.Model) -> Bool {
            let needle = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Ensure the needle is not empty
            guard !needle.isEmpty else { return true }
            
            // Check if the needle matches any part of model.name or model.url
            let nameMatch = model.name.localizedCaseInsensitiveContains(needle)
            let urlMatch = model.url?.absoluteString.localizedCaseInsensitiveContains(needle) ?? false
            
            return nameMatch || urlMatch
        }
        
    }
}

extension ModelSearchView.TableView {
    struct ModelDownloadButton: View {
        @EnvironmentObject var modelStore: ModelStore
        @EnvironmentObject var accountStore: Sideproject.ExternalAccountStore
        
        @State private var isHovering: Bool = false
        
        var model: ModelStore.Model
        
        var body: some View {
            Group {
                if let download: ModelStore.Download = modelStore.activeDownloads[model.id] {
                    Button {
                        Task { @MainActor in
                            switch download.state {
                                case .paused:
                                    print("resuming")
                                    await modelStore.resumeDownload(for: model)
                                default:
                                    print("pausing")
                                    await modelStore.pauseDownload(for: model)
                            }
                        }
                    } label: {
                        Group {
                            if !isHovering {
                                ProgressView(value: download.progress)
                                    .controlSize(.small)
                                    .progressViewStyle(.circular)
                                    .animation(.linear, value: download.progress)
                            } else {
                                Image(systemName: download.isPaused ? "arrow.trianglehead.clockwise" : "pause.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                            }
                        }
                        .frame(width: 15, height: 15)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering = $0 }
                    
                    Button {
                        modelStore.cancelDownload(for: model)
                    } label: {
                        Image(systemName: .xmarkCircleFill)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                            .frame(width: 15, height: 15)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button("Get") {
                        Task { @MainActor in
                            do {
                                let url = try await modelStore.download(modelNamed: model.name, using: accountStore)
                                print(url)
                            } catch {
                                print(error)
                                print(error.localizedDescription)
                            }
                        }
                    }
                    .buttonStyle(XcodeGetButtonStyle())
                    .disabled(!accountStore.containsAccount(for: .huggingFace))
                }
            }
            .id(model.id)
        }
    }
}

// MARK: - Helpers

fileprivate extension Sideproject.ExternalAccountStore {
    func containsAccount(for descriptor: any Sideproject.ExternalAccountTypeDescriptor) -> Bool {
        return self.accounts(for: descriptor).count != 0
    }
}
