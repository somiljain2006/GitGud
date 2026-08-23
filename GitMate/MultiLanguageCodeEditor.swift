//
//  MultiLanguageCodeEditor.swift
//  GitMate
//
//  Created by somil jain on 23/08/26.
//

import SwiftUI
import UIKit
import Highlightr

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
                    .foregroundColor: UIColor.white
                ])
            }

            let language = detectLanguage(from: filePath)
            if let highlighted = highlightr.highlight(text, as: language) {
                return highlighted
            }

            return NSAttributedString(string: text, attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular),
                .foregroundColor: UIColor.white
            ])
        }

        private func detectLanguage(from path: String) -> String {
            let ext = path.components(separatedBy: ".").last?.lowercased() ?? ""
            switch ext {
            case "swift": return "swift"
            case "js", "jsx": return "javascript"
            case "ts", "tsx": return "typescript"
            case "py": return "python"
            case "json": return "json"
            case "html", "htm": return "xml"
            case "css", "scss": return "css"
            case "cpp", "hpp", "c", "h": return "cpp"
            case "cs": return "cs"
            case "java": return "java"
            case "kt", "kts": return "kotlin"
            case "rb": return "ruby"
            case "go": return "go"
            case "rs": return "rust"
            case "sh", "bash": return "bash"
            case "yml", "yaml": return "yaml"
            case "md", "markdown": return "markdown"
            case "sql": return "sql"
            case "php": return "php"
            default: return ext
            }
        }
    }
}
