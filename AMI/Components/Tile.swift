//
//  Tile.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import SwiftUI

struct Tile: View {
    @State var title: String
    @State var content: String
    @State var action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 18))
                    .foregroundStyle(.blueFranceSun113)
                Text(content)
                    .font(.system(size: 16))
                HStack {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.blueFranceSun113)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .border(width: 1, edges: [.top, .leading, .trailing], color: Color.gray)
            .border(width: 8, edges: [.bottom], color: .blueFranceSun113)
        }
        .padding(16)
        .simultaneousGesture(TapGesture().onEnded {
            action()
        })
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}

#Preview {
    Tile(title: "PR239", content: "build two apps per platforms"){}
}
