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

    var body: some View {
        VStack {
            Group {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 18))
                        .foregroundStyle(Asset.Colors.blueFranceSun113.swiftUIColor)
                    Text(content)
                        .font(.system(size: 16.0))
                    HStack {
                        Image(systemName: "arrow.right")
                            .foregroundStyle(Asset.Colors.blueFranceSun113.swiftUIColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(EdgeInsets(top: 16.0, leading: 16.0, bottom: 2.0, trailing: 16.0))
            }
            Asset.Colors.blueFranceSun113.swiftUIColor
                .frame(height: 8.0)
        }
        .border(Asset.Colors.blueFranceSun113.swiftUIColor, width: 1.0)
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    Tile(title: "PR239", content: "build two apps per platforms")
}
