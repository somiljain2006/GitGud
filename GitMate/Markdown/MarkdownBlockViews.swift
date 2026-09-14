//
//  MarkdownBlockViews.swift
//  GitMate
//

import SwiftUI
import WebKit

struct MarkdownImageBlock: View {
    let url: URL
    let alt: String
    let id: UUID
    @State private var renderMode: RenderMode = .loading
    enum RenderMode { case loading, svg, gif, raster }

    var body: some View {
        Group {
            switch renderMode {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .task { await detectContentType() }
            case .svg:
                if url.absoluteString.lowercased().contains("shields.io") || url.absoluteString.lowercased().contains("badge") {
                    SVGBadgeView(url: url)
                } else {
                    SVGNormalView(url: url, widthHint: nil)
                }
            case .gif:
                GIFView(url: url)
            case .raster:
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(maxWidth: .infinity, minHeight: 80)
                    case let .success(image):
                        image.resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    case .failure:
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(alt.isEmpty ? "Failed to load image" : alt).font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .id(id)
    }

    private func detectContentType() async {
        if let mode = detectFromExtension() {
            renderMode = mode
            return
        }
        if let mode = await detectFromHeadRequest() {
            renderMode = mode
            return
        }
        renderMode = await detectFromGetRequest()
    }

    private func detectFromExtension() -> RenderMode? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "svg":
            return .svg
        case "gif":
            return .gif
        case "png", "jpg", "jpeg", "webp", "bmp", "tiff", "heic":
            return .raster
        default:
            return nil
        }
    }

    private func detectFromHeadRequest() async -> RenderMode? {
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "HEAD"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                let status = http.statusCode
                let ct = http.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""

                if status < 200 || status >= 300 {
                    return .raster
                }
                if ct.contains("svg") {
                    return .svg
                }
                if ct.contains("gif") {
                    return .gif
                }
                if ct.hasPrefix("image/") || ct.contains("png") || ct.contains("jpeg") || ct.contains("webp") {
                    return .raster
                }
            }
        } catch {
            return .raster
        }
        return nil
    }

    private func detectFromGetRequest() async -> RenderMode {
        var getRequest = URLRequest(url: url, timeoutInterval: 10)
        getRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        getRequest.setValue("bytes=0-511", forHTTPHeaderField: "Range")

        do {
            let (data, response) = try await URLSession.shared.data(for: getRequest)
            if let http = response as? HTTPURLResponse {
                let ct = http.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
                if ct.contains("svg") {
                    return .svg
                }
                if ct.contains("gif") {
                    return .gif
                }
            }
            if let text = String(data: data.prefix(256), encoding: .utf8), text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("<svg") || (text.contains("<?xml") && text.contains("<svg")) {
                return .svg
            } else {
                return .raster
            }
        } catch {
            return .raster
        }
    }
}

struct MarkdownListBlock: View {
    let items: [String]
    let color: Color
    let id: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body.weight(.bold))
                        .foregroundStyle(color)
                    Text(.init(item))
                        .foregroundStyle(color)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, 4)
        .id(id)
    }
}

struct MarkdownAttributedBlock: View {
    let content: String
    let color: Color
    let id: UUID

    var body: some View {
        if let attributedString = try? AttributedString(markdown: content, options: markdownOptions) {
            Text(attributedString)
                .foregroundStyle(color)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .id(id)
        } else {
            Text(content)
                .foregroundStyle(color)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .id(id)
        }
    }

    private var markdownOptions: AttributedString.MarkdownParsingOptions {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .full
        options.failurePolicy = .returnPartiallyParsedIfPossible
        return options
    }
}

struct MarkdownCodeBlock: View {
    let language: String?
    let content: String
    let color: Color
    let id: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(content)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(color.opacity(0.95))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .id(id)
    }
}

struct MarkdownDetailsBlock: View {
    let summary: String
    let content: String
    let color: Color
    let id: UUID
    let baseURL: URL?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)
                    Text(summary)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                MarkdownText(content, color: color, baseURL: baseURL)
                    .padding(.leading, 18)
                    .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .id(id)
    }
}

struct MarkdownHeadingBlock: View {
    let level: Int
    let text: String
    let color: Color
    let id: UUID

    private var font: Font {
        switch level {
        case 1: return .title.bold()
        case 2: return .title2.bold()
        case 3: return .title3.bold()
        case 4: return .headline.bold()
        case 5: return .subheadline.bold()
        default: return .footnote.bold()
        }
    }

    var body: some View {
        let attributed = (try? AttributedString(markdown: text)) ?? AttributedString(text)
        Text(attributed)
            .font(font)
            .foregroundStyle(color)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .id(id)
    }
}

struct SVGImageView: UIViewRepresentable {
    let url: URL
    @Binding var aspectRatio: CGFloat?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        loadSVG(into: webView)
        return webView
    }

    func updateUIView(_: WKWebView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(aspectRatio: $aspectRatio)
    }

    private func loadSVG(into webView: WKWebView) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let svgString = String(data: data, encoding: .utf8) else { return }

            let html = """
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
            html, body { margin: 0; padding: 0; background: transparent; overflow: visible; }
            svg { width: 100%; height: auto; display: block; }
            </style>
            </head>
            <body>
            \(svgString)
            <script>
            var svg = document.querySelector('svg');
            if (svg && !svg.getAttribute('viewBox')) {
                var w = parseFloat(svg.getAttribute('width'));
                var h = parseFloat(svg.getAttribute('height'));
                if (!isNaN(w) && !isNaN(h)) {
                    svg.setAttribute('viewBox', '0 0 ' + w + ' ' + h);
                }
            }
            </script>
            </body>
            </html>
            """
            DispatchQueue.main.async {
                webView.loadHTMLString(html, baseURL: url)
            }
        }.resume()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var aspectRatio: CGFloat?

        init(aspectRatio: Binding<CGFloat?>) {
            _aspectRatio = aspectRatio
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            let script = """
            (function() {
                var svg = document.querySelector('svg');
                if (!svg) return null;
                var vb = svg.viewBox && svg.viewBox.baseVal;
                if (vb && vb.width && vb.height) return vb.width / vb.height;
                var w = svg.getAttribute('width');
                var h = svg.getAttribute('height');
                if (w && h) return parseFloat(w) / parseFloat(h);
                return null;
            })();
            """

            webView.evaluateJavaScript(script) { result, _ in
                if let ratio = result as? Double {
                    DispatchQueue.main.async { self.aspectRatio = CGFloat(ratio) }
                }
            }
        }
    }
}

struct SVGBadgeView: View {
    let url: URL
    @State private var aspectRatio: CGFloat?

    var body: some View {
        SVGImageView(url: url, aspectRatio: $aspectRatio)
            .frame(width: aspectRatio.map { max(24, 20 * $0) } ?? 90, height: 20)
    }
}

struct SVGNormalView: View {
    let url: URL
    let widthHint: CGFloat?
    @State private var aspectRatio: CGFloat?

    private var displayWidth: CGFloat {
        min(widthHint ?? 300, 300)
    }

    var body: some View {
        if let aspectRatio, aspectRatio > 0 {
            SVGImageView(url: url, aspectRatio: $aspectRatio)
                .id("loaded")
                .frame(width: displayWidth, height: displayWidth / aspectRatio)
        } else {
            SVGImageView(url: url, aspectRatio: $aspectRatio)
                .id("measuring")
                .frame(width: displayWidth, height: displayWidth)
                .hidden()
                .overlay(ProgressView().frame(width: displayWidth, height: 60))
        }
    }
}

struct MarkdownInlineBlock: View {
    let elements: [InlineElement]
    let color: Color
    let id: UUID

    var body: some View {
        InlineFlowLayout(spacing: 6) {
            ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
                switch element {
                case let .text(text):
                    if let attributedText = try? AttributedString(markdown: text) {
                        Text(attributedText).foregroundStyle(color)
                    } else {
                        Text(text).foregroundStyle(color)
                    }
                case let .link(text, url):
                    Link(text, destination: url).foregroundStyle(color)
                case let .image(alt, url):
                    MarkdownImageBlock(url: url, alt: alt, id: UUID())
                case let .linkedImage(url, linkURL, widthHint):
                    Link(destination: linkURL) {
                        if let widthHint, widthHint > 60 {
                            SVGNormalView(url: url, widthHint: widthHint)
                        } else {
                            InlineBadgeView(url: url)
                        }
                    }.buttonStyle(.plain)
                case let .icon(name):
                    Image(systemName: name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(color)
                }
            }
        }.id(id)
    }
}

struct InlineBadgeView: View {
    let url: URL
    @State private var renderMode: InlineBadgeRenderMode = .loading
    enum InlineBadgeRenderMode { case loading, svg, raster }

    var body: some View {
        switch renderMode {
        case .loading:
            Color.clear.frame(width: 60, height: 20).task { await detect() }
        case .svg:
            SVGBadgeView(url: url)
        case .raster:
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(img):
                    img.resizable().scaledToFit().frame(height: 20)
                case .failure:
                    Image(systemName: "photo").foregroundStyle(.secondary).frame(height: 20)
                default:
                    Color.clear.frame(width: 60, height: 20)
                }
            }
        }
    }

    private func detect() async {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "svg": renderMode = .svg; return
        case "png", "jpg", "jpeg", "webp", "bmp", "tiff", "heic", "gif": renderMode = .raster; return
        default: break
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "HEAD"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                let status = http.statusCode
                if status < 200 || status >= 300 {
                    renderMode = .raster; return
                }
                let ct = http.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
                if ct.contains("svg") {
                    renderMode = .svg; return
                }
                if ct.hasPrefix("image/") || ct.contains("png") || ct.contains("jpeg") || ct.contains("webp") {
                    renderMode = .raster; return
                }
            }
        } catch {
            renderMode = .raster; return
        }
        renderMode = .raster
    }
}

struct InlineFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentY += lineHeight + spacing
                totalHeight = currentY
                currentX = 0
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let maxWidth = bounds.width
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX - bounds.minX + size.width > maxWidth, currentX > bounds.minX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
    }
}

struct MarkdownCalloutBlock: View {
    let type: CalloutType
    let content: String
    let color: Color
    let id: UUID

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .font(.headline)
                .foregroundStyle(type.tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(type.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(type.tint)

                if let attributedString = try? AttributedString(markdown: content) {
                    Text(attributedString)
                        .foregroundStyle(color)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(content)
                        .foregroundStyle(color)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.tint.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(type.tint.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .id(id)
    }
}

struct GIFImageView: UIViewRepresentable {
    let url: URL
    @Binding var aspectRatio: CGFloat?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator

        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>html, body { margin:0; padding:0; background:transparent; } img { width:100%; height:auto; display:block; }</style>
        </head>
        <body><img id="gif" src="\(url.absoluteString)"></body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: url)
        return webView
    }

    func updateUIView(_: WKWebView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(aspectRatio: $aspectRatio)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var aspectRatio: CGFloat?

        init(aspectRatio: Binding<CGFloat?>) {
            _aspectRatio = aspectRatio
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            let script = """
            (function() {
                var img = document.getElementById('gif');
                if (img && img.naturalWidth && img.naturalHeight) {
                    return img.naturalWidth / img.naturalHeight;
                }
                return null;
            })();
            """

            webView.evaluateJavaScript(script) { result, _ in
                if let ratio = result as? Double {
                    DispatchQueue.main.async { self.aspectRatio = CGFloat(ratio) }
                }
            }
        }
    }
}

struct GIFView: View {
    let url: URL
    @State private var aspectRatio: CGFloat?

    var body: some View {
        GIFImageView(url: url, aspectRatio: $aspectRatio)
            .aspectRatio(aspectRatio ?? 16.0 / 9.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct MarkdownTableBlock: View {
    let headers: [String]
    let rows: [[String]]
    let color: Color
    let id: UUID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                        cellText(header, bold: true)
                    }
                }
                .background(Color.white.opacity(0.08))

                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        ForEach(0 ..< headers.count, id: \.self) { colIndex in
                            let value = colIndex < row.count ? row[colIndex] : ""
                            cellText(value, bold: false)
                        }
                    }
                    .background(rowIndex.isMultiple(of: 2) ? Color.clear : Color.white.opacity(0.03))
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }.id(id)
    }

    private func cellText(_ text: String, bold: Bool) -> some View {
        let attributed = (try? AttributedString(markdown: text)) ?? AttributedString(text)
        return Text(attributed)
            .font(bold ? .caption.bold() : .caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minWidth: 90, alignment: .leading)
            .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.white.opacity(0.06)), alignment: .trailing)
    }
}

struct MarkdownQuoteBlock: View {
    let content: String
    let color: Color
    let id: UUID

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 3)

            if let attributedString = try? AttributedString(markdown: content, options: {
                var options = AttributedString.MarkdownParsingOptions()
                options.interpretedSyntax = .full
                options.failurePolicy = .returnPartiallyParsedIfPossible
                return options
            }()) {
                Text(attributedString)
                    .foregroundStyle(color.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(content)
                    .foregroundStyle(color.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(id)
    }
}
