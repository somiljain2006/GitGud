//
//  MultiLanguageCodeEditor.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import Highlightr
import SwiftUI
import UIKit

struct MultiLanguageCodeEditor: UIViewRepresentable {
    @Binding var text: String
    let filePath: String

    var fontSize: CGFloat = 14

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = context.coordinator.highlight(text, filePath: filePath)
            uiView.selectedRange = selectedRange
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultiLanguageCodeEditor
        let highlightr = Highlightr()

        private let languageMap: [String: String] = [
            "swift": "swift",
            "js": "javascript", "jsx": "javascript",
            "ts": "typescript", "tsx": "typescript",
            "py": "python",
            "json": "json",
            "html": "xml", "htm": "xml",
            "css": "css", "scss": "css",
            "cpp": "cpp", "hpp": "cpp", "c": "cpp", "h": "cpp",
            "cs": "cs",
            "java": "java",
            "kt": "kotlin", "kts": "kotlin",
            "rb": "ruby",
            "go": "go",
            "rs": "rust",
            "sh": "bash", "bash": "bash",
            "yml": "yaml", "yaml": "yaml",
            "md": "markdown", "markdown": "markdown",
            "sql": "sql",
            "php": "php",
        ]

        init(_ parent: MultiLanguageCodeEditor) {
            self.parent = parent
            super.init()

            highlightr?.setTheme(to: "atom-one-dark")

            let customFont = UIFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular)
            highlightr?.theme.setCodeFont(customFont)
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            let selectedRange = textView.selectedRange
            textView.attributedText = highlight(textView.text, filePath: parent.filePath)
            textView.selectedRange = selectedRange
        }

        func highlight(_ text: String, filePath: String) -> NSAttributedString {
            guard let highlightr = highlightr else {
                return NSAttributedString(string: text, attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular),
                    .foregroundColor: UIColor.white,
                ])
            }

            let language = detectLanguage(from: filePath)
            if let highlighted = highlightr.highlight(text, as: language) {
                return highlighted
            }

            return NSAttributedString(string: text, attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular),
                .foregroundColor: UIColor.white,
            ])
        }

        private func detectLanguage(from path: String) -> String {
            let ext = path.components(separatedBy: ".").last?.lowercased() ?? ""
            return languageMap[ext] ?? ext
        }
    }
}
