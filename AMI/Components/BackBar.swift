//
//  SwiftUIView.swift
//  AMI
//
//  Created by Aline Bonnet on 18/12/2025.
//

import SwiftUI

struct BackBar: View {
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "arrowtriangle.left.fill")
            Text("Retour")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .simultaneousGesture(TapGesture().onEnded {
            
        })
    }
}

#Preview {
    BackBar()
}
