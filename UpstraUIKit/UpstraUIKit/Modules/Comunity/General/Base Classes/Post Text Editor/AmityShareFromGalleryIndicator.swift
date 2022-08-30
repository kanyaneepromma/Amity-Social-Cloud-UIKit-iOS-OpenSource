//
//  AmityShareFromGalleryIndicator.swift
//  AmityUIKit
//
//  Created by Mono TheForestcat on 26/8/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

import SwiftUI

public struct LoadingView: View {
    @Environment (\.colorScheme) var colorScheme: ColorScheme
    @State private var isLoading = false
    
    let style = StrokeStyle(lineWidth: 6, lineCap: .round)
    
    public init() {}
 
    public var body: some View {
        ZStack {
            Color(colorScheme == .light ? .white : .black).opacity(0.5)
 
            Circle()
                .trim(from: 0, to: 1)
                .stroke(
                    AngularGradient(gradient: .init(colors: [Color(UIColor.init(hex: "#d0021a")), Color(.systemGray5)]),
                                    center: .center),
                    style: style
                )
                .frame(width: 30, height: 30)
                .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                .onAppear() {
                    self.isLoading = true
            }
        }
    }
}