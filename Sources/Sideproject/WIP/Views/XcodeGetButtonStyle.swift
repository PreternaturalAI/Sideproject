//
//  File.swift
//  Sideproject
//
//  Created by Purav Manot on 29/11/24.
//

import Foundation
import SwiftUI

struct XcodeGetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.blue)
            .padding(4)
            .padding(.horizontal, 14)
            .background(.white, in: .capsule)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .contentShape(.capsule)
    }
}
