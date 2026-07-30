//
//  QuickActionsSection.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct QuickActionsSection: View {
    let actions: [QuickAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(actions) { action in
                    QuickActionCard(action: action)
                }
            }
        }
    }
}
