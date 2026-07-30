//
//  DockTab.swift
//  GitMate
//
//  Created by somil jain on 30/07/26.
//

import Foundation

enum DockTab: String, CaseIterable {
    case home, inbox, aiSearch, explore, repos
    
    var title: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .inbox: return "tray.fill"
        case .aiSearch: return "brain.head.profile"
        case .explore: return "safari"
        case .repos: return "shippingbox.fill"
        }
    }
    
    var hasNotification: Bool {
        self == .inbox
    }
}
