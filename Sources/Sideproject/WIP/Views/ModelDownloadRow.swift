//
//  SwiftUIView.swift
//  Sideproject
//
//  Created by Purav Manot on 28/11/24.
//

import SwiftUI

extension ModelSearchView {
    struct ModelDownloadRow: View {
        @EnvironmentObject var modelStore: ModelStore
        var model: ModelStore.Model
        
        var body: some View {
            GroupBox {
                VStack(alignment: .leading) {
                    Text(model.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        ProgressView(value: model.downloadProgess)
                            .progressViewStyle(.linear)
                            .padding(.horizontal, 5)
                        
                        Button {
                            Task { @MainActor in
                                switch model.state {
                                    case .paused(let _):
                                        print("resuming")
                                        modelStore.resumeDownload(for: model)
                                    default:
                                        print("pausing")
                                        await modelStore.pauseDownload(for: model)
                                }
                            }
                        } label: {
                            Image(systemName: .pauseCircleFill)
                        }
                        
                        Button {
                           // modelStore.cancelDownload(for: model)
                        } label: {
                            Image(systemName: .xmarkCircleFill)
                        }
                    }
                }
            }
            .padding(5)
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
        }
    }
}

