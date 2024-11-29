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
                            // TODO: (@pmanot) Implement pause/resume functionality
                        } label: {
                            Image(systemName: .pauseCircleFill)
                        }
                        
                        Button {
                            modelStore.cancelDownload(for: model)
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

