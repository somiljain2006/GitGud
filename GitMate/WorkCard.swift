//
//  WorkCard.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import SwiftUI

struct WorkCard: View {
    let item: WorkItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if item.type == .pullRequest {
                    Image("pull_request_icon")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(item.prState?.color ?? item.type.color)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: item.type.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(item.type.color)
                }
            }
            .frame(width: 34)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(item.repository)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                    
                    Spacer()
                    
                    Text(item.time)
                        .foregroundStyle(.gray)
                        .font(.system(size: 15))
                }
                
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(item.description)
                    .foregroundStyle(.gray)
                    .font(.system(size: 16))
            }
            
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Text("\(item.comments)")
                            .foregroundStyle(.gray)
                            .font(.system(size: 16, weight: .bold))
                    }
                
                Spacer()
            }
        }
        .padding(18)
    }
}
