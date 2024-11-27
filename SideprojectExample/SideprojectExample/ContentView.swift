//
//  ContentView.swift
//  SideprojectExample
//
//  Created by Purav Manot on 27/11/24.
//

import SwiftUI
import Sideproject

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List(0..<5)
        } detail: {
            SideprojectAccountsView()
        }
    }
}
