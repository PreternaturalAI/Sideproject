//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 29/11/24.
//

import Foundation
import SwiftUI

extension ModelSearchView {
    struct TableView: View {
        @EnvironmentObject private var modelStore: ModelStore
        @EnvironmentObject private var accountStore: Sideproject.ExternalAccountStore
        
        @State private var selectedModel: ModelStore.Model.ID? = nil
        @State private var sortOrder: [KeyPathComparator<ModelStore.Model>] = [KeyPathComparator(\ModelStore.Model.size), KeyPathComparator(\ModelStore.Model.name), KeyPathComparator(\ModelStore.Model.lastUsed)]
        
        @Binding var selectedTab: ModelSearchView.Tab
        
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
            }

            
            TableColumn("Last Used") { (model: ModelStore.Model) in
                Text(model.lastUsed, format: .relative(presentation: .named))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            TableColumn("Info", sortUsing: KeyPathComparator(\.size)) { (model: ModelStore.Model) in
                HStack {
                    Spacer()
                    
                    if selectedTab == .discover {
                        Button {
                            Task {
                                do {
                                    let url = try await modelStore.download(modelNamed: model.name, using: accountStore)
                                    print(url)
                                } catch {
                                    print(error)
                                    print(error.localizedDescription)
                                }
                                
                            }
                        } label: {
                            Text("Get")
                        }
                        .buttonStyle(XcodeGetButtonStyle())
                        .disabled(!accountStore.containsAccount(for: .huggingFace) || model.isDownloading)
                        
                    } else {
                        Text(model.sizeDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        
        @TableRowBuilder<ModelStore.Model>
        var tableRowContent: some TableRowContent<ModelStore.Model> {
            Section("Downloads") {
                ForEach(modelStore[keyPath: \.activeDownloads].sorted(using: sortOrder)) { model in
                    TableRow(model)
                }
            }
            
            Section(selectedTab == .discover ? "All models" : "Your models") {
                ForEach(modelStore[keyPath: selectedTab.keyPath].sorted(using: sortOrder)) { model in
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
        
        var body: some View {
            Table(of: ModelStore.Model.self, selection: $selectedModel, sortOrder: $sortOrder) {
                tableColumnContent
            } rows: {
                tableRowContent
            }
            .tableStyle(.inset)
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
            .padding()
        }
    }
}

// MARK: - Helpers

fileprivate extension Sideproject.ExternalAccountStore {
    func containsAccount(for descriptor: any Sideproject.ExternalAccountTypeDescriptor) -> Bool {
        return self.accounts(for: descriptor).count != 0
    }
}
