//
//  MyWorkSection.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct MyWorkSection: View {
    let items: [WorkItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("My Work")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    WorkCard(item: items[index])
                    
                    if index != items.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.leading, 62)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(GlassCard(cornerRadius: 20))
        }
    }
}
