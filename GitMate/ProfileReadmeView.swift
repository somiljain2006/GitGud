//  ProfileReadmeView.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import SwiftUI
import WebKit

struct ProfileReadmeView: View {
    let htmlContent: String
    let username: String
    let followers: Int
    let following: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ReadmeWebView(htmlString: htmlContent, username: username, followers: followers, following: following)
                .navigationTitle("README.md")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ReadmeWebView: UIViewRepresentable {
    let htmlString: String
    let username: String
    let followers: Int
    let following: Int
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
        let heatmapHTML = """
        <h2>Contribution Graph</h2>
        <div class="heatmap-wrapper">
            <img src="https://ghchart.rshah.org/40c463/\(username)" alt="\(username)'s Github chart" />
            <div class="stats-row">
                <span><strong>\(followers)</strong> followers</span>
                <span>&middot;</span>
                <span><strong>\(following)</strong> following</span>
            </div>
        </div>
        """
        
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
        <style>
            :root { color-scheme: light dark; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                font-size: 16px;
                line-height: 1.5;
                padding: 16px;
                margin: 0;
                color: #c9d1d9;
            }
            @media (prefers-color-scheme: light) {
                body { color: #24292f; }
            }
            .anchor { display: none; }
            img { max-width: 100%; height: auto; border-radius: 6px; }
            a { color: #58a6ff; text-decoration: none; }
            h1, h2 { border-bottom: 1px solid #30363d; padding-bottom: 0.3em; margin-top: 24px; }
            pre { background-color: rgba(110,118,129,0.1); padding: 16px; border-radius: 6px; overflow: auto; }
            code { font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace; background-color: rgba(110,118,129,0.2); padding: 0.2em 0.4em; border-radius: 6px; font-size: 85%; }
            pre code { background-color: transparent; padding: 0; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 16px; }
            th, td { border: 1px solid #30363d; padding: 6px 13px; }
            tr:nth-child(even) { background-color: rgba(255,255,255,0.05); }
            
            .heatmap-wrapper {
                overflow-x: auto;
                padding: 16px;
                background-color: rgba(110,118,129,0.1);
                border-radius: 6px;
                margin-top: 16px;
                margin-bottom: 32px;
            }
            .heatmap-wrapper img {
                min-width: 650px; 
            }
           .stats-row {
                display: flex;
                justify-content: flex-start;
                gap: 12px;
                margin-top: 12px;
                color: #8b949e;
                font-size: 14px;
            }
            .stats-row strong {
                color: #c9d1d9;
            }
        </style>
        </head>
        <body>
            \(htmlString)
            \(heatmapHTML) 
        </body>
        </html>
        """
        uiView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
