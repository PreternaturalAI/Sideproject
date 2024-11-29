//
//  DownloadedModelRow.swift
//  SideprojectExample
//
//  Created by Purav Manot on 29/11/24.
//

import Foundation
import Sideproject
import SwiftUI

struct DownloadedModelRow: View {
    @StateObject var modelStore = try! ModelStore()
    
    var body: some View {
        Table(modelStore.models) {
            TableColumn("Name", value: \ModelStore.Model.name)
            
            TableColumn("Info") { model in
                Text(model.sizeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tableStyle(.inset)
        .alternatingRowBackgrounds(.disabled)
        .padding()
    }
}

#Preview {
    DownloadedModelRow()
}
