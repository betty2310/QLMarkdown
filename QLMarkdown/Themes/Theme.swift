//
//  Theme.swift
//  QLMarkdown
//
//  Created by Sbarex on 14/12/20.
//

import Cocoa


@objc class Theme: NSObject {
    enum ThemeAppearance: Int {
        case undefined
        case light
        case dark
    }
    
    enum PropertyName: Hashable {
        case plain
        case canvas
        case number
        case string
        case escape
        case preProcessor
        case stringPreProc
        case blockComment
        case lineComment
        case lineNum
        case `operator`
        case interpolation
        case keyword(index: Int)
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.name)
        }
        
        var index: Int {
            switch self {
            case .plain: return 0
            case .canvas: return 1
            case .number: return 2
            case .string: return 3
            case .escape: return 4
            case .preProcessor: return 5
            case .stringPreProc: return 6
            case .blockComment: return 7
            case .lineComment: return 8
            case .lineNum: return 9
            case .operator: return 10
            case .interpolation: return 11
            case .keyword(let index): return 12 + index
            }
        }
        
        var name: String {
            switch self {
            case .plain: return "Default"
            case .canvas: return "Background"
            case .number: return "Number"
            case .string: return "String"
            case .escape: return "Escape"
            case .preProcessor: return "Preprocessor"
            case .stringPreProc: return "String preprocessor"
            case .blockComment: return "Block comment"
            case .lineComment: return "Line comment"
            case .lineNum: return "Line number"
            case .operator: return "Operator"
            case .interpolation: return "Interpolation"
            case .keyword(let index):
                return "Keyword \(index+1)"
            }
        }
        
        /// CSS class used to render the token.
        var cssClass: [String] {
            switch self {
            case .plain: return ["hl"]
            case .canvas: return ["hl"]
            case .number: return ["hl", "num"]
            case .escape: return ["hl", "esc"]
            case .string: return ["hl", "str"]
            case .preProcessor: return ["hl", "ppc"]
            case .stringPreProc: return ["hl", "pps"]
            case .blockComment: return ["hl", "com"]
            case .lineComment: return ["hl", "slc"]
            case .lineNum: return ["hl", "lin"]
            case .operator:
                return ["hl", "opt"]
            case .interpolation:
                return ["hl", "ipl"]
                
            case .keyword(let index):
                return ["hl", "kw" + String(UnicodeScalar(UInt8(97 + index)))]
            }
        }
        
        var isKeyword: Bool {
            switch self {
            case .keyword(_):
                return true
            default:
                return false
            }
        }
        var keywordIndex: Int {
            switch self {
            case .keyword(let i):
                return i
            default:
                return -1
            }
        }
    }
    
    class PropertyStyle {
        enum Attribute: String {
            case italic = "italic"
            case bold = "bold"
            case underline = "underline"
            
            case color = "color"
        }
        
        var italic: Bool? {
            didSet {
                guard oldValue != italic else { return }
                
            }
        }
        var bold: Bool?
        var underline: Bool?
        var color: String?
        
        init(color: String?, italic: Bool?, bold: Bool?, underline: Bool?) {
            self.color = color
            self.italic = italic
            self.bold = bold
            self.underline = underline
        }
        
        convenience init(property: HThemeProperty) {
            let color = property.color != nil ? String(cString: property.color) : nil
            
            let bold: Bool? = property.bold < 0 ? nil : property.bold > 0
            let italic: Bool? = property.italic < 0 ? nil : property.italic > 0
            let underline: Bool? = property.underline < 0 ? nil : property.underline > 0
            
            self.init(color: color, italic: italic, bold: bold, underline: underline)
        }
        
        func getCSSStyle() -> String {
            var style = ""
            if let italic = self.italic {
                style += "font-style: \(italic ? "italic" : "normal"); "
            }
            if let bold = self.bold {
                style += "font-weight: \(bold ? "bold" : "normal"); "
            }
            if let underline = self.underline {
                style += "text-decoration: \(underline ? "underline" : "none"); "
            }
            if let color = self.color {
                style += "color: \(color); "
            }
            
            return style
        }
        
        subscript(name: Attribute)->AnyHashable? {
            get {
                switch name {
                case .bold:
                    return bold
                case .italic:
                    return italic
                case .underline:
                    return underline
                case .color:
                    return color;
                }
            }
            set {
                switch name {
                case .bold:
                    if newValue == nil {
                        bold = nil
                    } else if let v = newValue as? Bool {
                        bold = v
                    }
                case .italic:
                    if newValue == nil {
                        italic = nil
                    } else if let v = newValue as? Bool {
                        italic = v
                    }
                case .underline:
                    if newValue == nil {
                        underline = nil
                    } else if let v = newValue as? Bool {
                        underline = v
                    }
                case .color:
                    if newValue == nil {
                        color = nil
                    } else if let v = newValue as? String {
                        color = v
                    }
                }
            }
        }
        
        func export() -> String {
            var export = ""
            if let italic = self.italic {
                export += italic ? "italic " : "noitalic "
            }
            if let bold = self.bold {
                export += bold ? "bold " : "nobold "
            }
            if let underline = self.underline {
                export += underline ? "underline " : "nounderline "
            }
            if let color = self.color {
                export += "\(color) "
            }
            if export.count > 0 {
                export.removeLast()
            }
            return export
        }
        
        func getFormattedString(_ text: String, font: NSFont, forIcon: Bool = false, plainColor: String?) -> NSAttributedString {
            var attributes: [NSAttributedString.Key: Any] = [:]
            if let cc = NSColor(css: self.color ?? plainColor) {
                attributes[.foregroundColor] = cc
            }
            if !forIcon, let underline = self.underline {
                attributes[.underlineStyle] = underline ? NSUnderlineStyle.double : NSUnderlineStyle(rawValue: 0)
                attributes[.underlineColor] = attributes[.foregroundColor]
            }
            var fontTraits: NSFontTraitMask = []
            if let bold = self.bold {
                fontTraits.insert(bold ? .boldFontMask : .unboldFontMask)
            }
            if let italic = self.italic {
                fontTraits.insert(italic ? .italicFontMask : .unitalicFontMask)
            }
            if !fontTraits.isEmpty, let f = NSFontManager.shared.font(withFamily: font.familyName ?? font.fontName, traits: fontTraits, weight: 5, size: font.pointSize) {
                attributes[.font] = f
            } else {
                attributes[.font] = font
            }
            return NSAttributedString(string: text + "\n", attributes: attributes)
        }
    }
    
    public static func == (lhs: Theme, rhs: Theme) -> Bool {
        return lhs.name == rhs.name && lhs.isStandalone == rhs.isStandalone
    }
    
    @objc dynamic var name: String {
        didSet {
            guard oldValue != name else { return }
            self.isDirty = true
        }
    }
    
    dynamic var desc: String {
        didSet {
            guard oldValue != desc else { return }
            self.isDirty = true
        }
    }
    var path: String
    dynamic var appearance: ThemeAppearance = .undefined {
        didSet {
            guard oldValue != appearance else { return }
            self.isDirty = true
        }
    }
    
    var plain: PropertyStyle
    var canvas: PropertyStyle
    var number: PropertyStyle
    var string: PropertyStyle
    var escape: PropertyStyle
    var preProcessor: PropertyStyle
    var stringPreProc: PropertyStyle
    var blockComment: PropertyStyle
    var lineComment: PropertyStyle
    var lineNum: PropertyStyle
    var `operator`: PropertyStyle
    var interpolation: PropertyStyle
    var keywords: [PropertyStyle]
    
    var isBase16: Bool = false
    var isStandalone: Bool = false
    @objc dynamic var isDirty: Bool = false
    
    convenience init (theme: HTheme) {
        let import_prop = { ( p: inout PropertyStyle, property: HThemeProperty) in
            p.color = property.color != nil ? String(cString: property.color) : nil
            if property.bold < 0 {
                p.bold = nil
            } else {
                p.bold = property.bold > 0
            }
            if property.italic < 0 {
                p.italic = nil
            } else {
                p.italic = property.italic > 0
            }
            if property.underline < 0 {
                p.underline = nil
            } else {
                p.underline = property.underline > 0
            }
        }
        
        self.init(name: theme.name != nil ? String(cString: theme.name) : "")
        self.desc = theme.desc != nil ? String(cString: theme.desc) : ""
        self.path = theme.path != nil ? String(cString: theme.path) : ""
    
        self.appearance = theme.appearance == HThemeAppearance(1) ? .light : (theme.appearance == HThemeAppearance(2) ? .dark : .undefined)
        self.isStandalone = theme.standalone > 0
        self.isBase16 = theme.base16 > 0
        
        import_prop(&self.plain, theme.plain.pointee)
        import_prop(&self.canvas, theme.canvas.pointee)
        import_prop(&self.number, theme.number.pointee)
        import_prop(&self.string, theme.string.pointee)
        import_prop(&self.escape, theme.escape.pointee)
        import_prop(&self.preProcessor, theme.preProcessor.pointee)
        import_prop(&self.stringPreProc, theme.stringPreProc.pointee)
        import_prop(&self.blockComment, theme.blockComment.pointee)
        import_prop(&self.lineComment, theme.lineComment.pointee)
        import_prop(&self.lineNum, theme.lineNum.pointee)
        import_prop(&self.operator, theme.operatorProp.pointee)
        import_prop(&self.interpolation, theme.interpolation.pointee)
        self.keywords = []
        for i in 0 ..< Int(theme.keyword_count) {
            if let k = theme.keywords[i]?.pointee {
                self.keywords.append(PropertyStyle(property: k))
            }
        }
        self.isDirty = false
    }
    
    init(name: String) {
        self.name = name
        self.desc = ""
        self.path = ""
        self.appearance = .undefined
        self.isBase16 = false
        self.isStandalone = false
        
        self.plain = PropertyStyle(color: "#000000", italic: nil, bold: nil, underline: nil)
        self.canvas = PropertyStyle(color: "#ffffff", italic: nil, bold: nil, underline: nil)
        
        self.number = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.string = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.escape = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.preProcessor = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.stringPreProc = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.blockComment = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.lineComment = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.lineNum = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.`operator` = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.interpolation = PropertyStyle(color: nil, italic: nil, bold: nil, underline: nil)
        self.keywords = []
        
        self.isDirty = false
    }
    
    
    func getCSSStyle() -> String {
        let formatPropertyCss = { (name: PropertyName, property: PropertyStyle) -> String in
            var css = "." + name.cssClass.joined(separator: ".") + " {\n"
            if name == .canvas {
                css += "    background-color: \(property.color ?? "#ffffff");\n"
            } else {
                css += property.getCSSStyle()
            }
            css += "}\n"
            return css
        }
        
        var css = ""
        
        if let background = self.canvas.color {
            css += "body { background-color: \(background); }\n"
        }
        if let color = self.plain.color {
            css += "body { color: \(color); }\n"
        }
        
        css += formatPropertyCss(.canvas, self.canvas)
        css += formatPropertyCss(.plain, self.plain)
        css += formatPropertyCss(.number, self.number)
        css += formatPropertyCss(.string, self.string)
        css += formatPropertyCss(.escape, self.escape)
        css += formatPropertyCss(.preProcessor, self.preProcessor)
        css += formatPropertyCss(.stringPreProc, self.stringPreProc)
        css += formatPropertyCss(.blockComment, self.blockComment)
        css += formatPropertyCss(.lineComment, self.lineComment)
        css += formatPropertyCss(.lineNum, self.lineNum)
        css += formatPropertyCss(.operator, self.operator)
        css += formatPropertyCss(.interpolation, self.interpolation)
        for (i, keyword) in self.keywords.enumerated() {
            css += formatPropertyCss(.keyword(index: i), keyword)
        }
        
        return css
    }
    
    func getHtmlExample() -> String {
        let formatProperty = { (name: PropertyName, property: PropertyStyle) -> String in
            return "<div class='\(name.cssClass.joined(separator: " "))'>\(name.name)</div>\n"
        }
        
        let css = self.getCSSStyle()
        
        var s = """
<html>
<head>
        <title>\(self.name)</title>
<style type="text/css">
body {
    font-family: ui-monospace, -apple-system, BlinkMacSystemFont, sans-serif;
    user-select: none;
}
\(css)
</style>
</head>

<body>
    <pre>
"""
        s += formatProperty(.plain, self.plain)
        s += formatProperty(.canvas, self.canvas)
        s += formatProperty(.number, self.number)
        s += formatProperty(.string, self.string)
        s += formatProperty(.escape, self.escape)
        s += formatProperty(.preProcessor, self.preProcessor)
        s += formatProperty(.stringPreProc, self.stringPreProc)
        s += formatProperty(.blockComment, self.blockComment)
        s += formatProperty(.lineComment, self.lineComment)
        s += formatProperty(.lineNum, self.lineNum)
        s += formatProperty(.operator, self.operator)
        s += formatProperty(.interpolation, self.interpolation)
        for (i, keyword) in self.keywords.enumerated() {
            s += formatProperty(.keyword(index: i), keyword)
        }
        
        s += """
    </pre>
</body>
</html>
"""
        return s
    }

    
    /// Get a NSAttributedString for preview the theme settings in the icon.
    /// This code don't call internally the getHtmlExample and is more (about 6x)  fast!
    internal func getAttributedExampleForIcon(font: NSFont) -> NSAttributedString {
        let s = NSMutableAttributedString()
        s.append(self.plain.getFormattedString(PropertyName.plain.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.number.getFormattedString(PropertyName.number.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.string.getFormattedString(PropertyName.string.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.escape.getFormattedString(PropertyName.escape.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.preProcessor.getFormattedString(PropertyName.preProcessor.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.stringPreProc.getFormattedString(PropertyName.stringPreProc.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.blockComment.getFormattedString(PropertyName.blockComment.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.lineComment.getFormattedString(PropertyName.lineComment.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.lineNum.getFormattedString(PropertyName.lineNum.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.operator.getFormattedString(PropertyName.operator.name, font: font, forIcon: true, plainColor: self.plain.color))
        s.append(self.interpolation.getFormattedString(PropertyName.interpolation.name, font: font, forIcon: true, plainColor: self.plain.color))
        for (i, keyword) in self.keywords.enumerated() {
            s.append(keyword.getFormattedString(PropertyName.keyword(index: i).name, font: font, forIcon: true, plainColor: self.plain.color))
        }
        
        return s
    }
    
    func getImage(forSize size: CGSize, font: NSFont) -> NSImage? {
        let format = getAttributedExampleForIcon(font: font)
        
        let rect = CGRect(origin: .zero, size: size)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let context = CGContext(
            data: nil,
            width: Int(rect.width),
            height: Int(rect.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue) {
            
            if let cc = NSColor(css: self.canvas.color) {
                context.setFillColor(cc.cgColor)
                context.fill(rect)
            }
            
            let c = NSGraphicsContext.current
            let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = graphicsContext
            
            format.draw(in: rect.insetBy(dx: 6, dy: 6))
            
            // Restore the context.
            NSGraphicsContext.current = c
            
            if !isStandalone {
                // Fill a corner to notify that this is a custom theme.
                context.setLineWidth(0)
                context.setFillColor(NSColor.controlAccentColor.cgColor)
                context.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX-20, y: rect.minY))
                context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY+20))
                context.fillPath()
            }
            
            if let image = context.makeImage() {
                return NSImage(cgImage: image, size: CGSize(width: context.width, height: context.height))
            }
        }
        return nil
    }
    
    class func getCombinedImage(light: ThemePreview?, dark: ThemePreview?) -> NSImage? {
        guard light?.image != nil || dark?.image != nil else {
            return nil
        }
        let rect: CGRect
        if let image = light?.image {
            rect = CGRect(origin: .zero, size: image.size)
        } else if let image = dark?.image {
            rect = CGRect(origin: .zero, size: image.size)
        } else {
            rect = .zero
        }
        
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let context = CGContext(
            data: nil,
            width: Int(rect.width),
            height: Int(rect.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue) {
            
            let priorNsgc = NSGraphicsContext.current
            defer { NSGraphicsContext.current = priorNsgc }
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            
            if let image = light?.image {
                image.draw(in: rect)
                let p = NSBezierPath.init()
                p.move(to: NSPoint(x: rect.width, y: rect.height))
                p.line(to: NSPoint(x: rect.width, y: 0))
                p.line(to: NSPoint(x: 0, y: 0))
                p.close()
                p.addClip()
            }
            
            if let image = dark?.image {
                image.draw(in: rect)
            }
            
            if let image = context.makeImage() {
                return NSImage(cgImage: image, size: CGSize(width: context.width, height: context.height))
            }
        }
        return nil
    }
    
    class func getCombinedImage2(light: ThemePreview?, dark: ThemePreview?, size: CGFloat, space: CGFloat) -> NSImage? {
        guard light?.image != nil || dark?.image != nil else {
            return nil
        }
        
        let rect: CGRect = CGRect(x: 0, y: 0, width: size * 2 + space, height: size)
        let image_size = CGSize(width: size, height: size)
        let font = NSFont.systemFont(ofSize: max(3, size / 6))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        if let context = CGContext(
            data: nil,
            width: Int(rect.width),
            height: Int(rect.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue) {
            
            let priorNsgc = NSGraphicsContext.current
            defer { NSGraphicsContext.current = priorNsgc }
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            
            if let image = light?.getImage(forSize: image_size, font: font) {
                image.draw(in: CGRect(origin: .zero, size: image_size))
            }
            
            if let image = dark?.getImage(forSize: image_size, font: font) {
                image.draw(in: CGRect(origin: CGPoint(x: size+space, y: 0), size: image_size))
            }
            
            if let image = context.makeImage() {
                return NSImage(cgImage: image, size: CGSize(width: context.width, height: context.height))
            }
        }
        return nil
    }
    
    subscript(name: PropertyName) -> PropertyStyle? {
        switch name {
        case .plain:
            return self.plain
        case .canvas:
            return self.canvas
        case .number:
            return self.number
        case .string:
            return self.string
        case .escape:
            return self.escape
        case .preProcessor:
            return self.preProcessor
        case .stringPreProc:
            return self.stringPreProc
        case .blockComment:
            return self.blockComment
        case .lineComment:
            return self.lineComment
        case .lineNum:
            return self.lineNum
        case .operator:
            return self.operator
        case .interpolation:
            return self.interpolation
        case .keyword(let index):
            if index >= 0 || index < self.keywords.count {
                return self.keywords[index]
            } else {
                return nil
            }
        }
    }
    
    enum ErrorSave: Error {
        case missingThemeFolder
    }
    
    func save() throws {
        if self.path.isEmpty {
            guard let dest = Settings.themesFolder?.appendingPathComponent(UUID().uuidString + ".theme") else {
                throw ErrorSave.missingThemeFolder
            }
            self.path = dest.path
        }
        try self.write(toFile: self.path)
        self.isDirty = false
        NotificationCenter.default.post(name: .themeDidSaved, object: self)
    }
    
    func write(toFile file: String) throws {
        var s = ""
        s += "Name = \"\(self.name.escapingForLua())\"\n\n"
        s += "Description = \"\(self.desc.escapingForLua())\"\n\n"

        if self.appearance != .undefined {
            s += "Categories = { \"\(self.appearance == .light ? "light" : "dark")\" }\n\n"
        }
        
        let exportProperty = { (property: PropertyStyle, name: String) -> String in
            var s = ""
            if !name.isEmpty {
                s += "\(name)\t= "
            } else {
                s += "\t"
            }
            s += "{ "
            var n = 0
            if let c = property.color {
                s += "Colour=\"\(c)\""
                n += 1
            }
            if let v = property.bold {
                if n > 0 {
                    s += ", "
                }
                s += "Bold=\(v ? "True" : "False")"
                n += 1
            }
            if let v = property.italic {
                if n > 0 {
                    s += ", "
                }
                s += "Italic=\(v ? "True" : "False")"
                n += 1
            }
            if let v = property.underline {
                if n > 0 {
                    s += ", "
                }
                s += "Underline=\(v ? "True" : "False")"
                n += 1
            }
            s += " }"
            if name.isEmpty {
                s += ", "
            }
            s += "\n"
            return s
        }
        
        s += exportProperty(self.plain, "Default")
        s += exportProperty(self.canvas, "Canvas")
        s += exportProperty(self.number, "Number")
        s += exportProperty(self.escape, "Escape")
        s += exportProperty(self.string, "String")
        s += exportProperty(self.stringPreProc, "StringPreProc")
        s += exportProperty(self.blockComment, "BlockComment")
        s += exportProperty(self.lineComment, "LineComment")
        s += exportProperty(self.preProcessor, "PreProcessor")
        s += exportProperty(self.lineNum, "LineNum")
        s += exportProperty(self.operator, "Operator")
        s += exportProperty(self.interpolation, "Interpolation")
        s += "\nKeywords = {\n"
        if self.keywords.count > 0 {
            for keyword in self.keywords {
                s += exportProperty(keyword, "")
            }
        }
        s += "}\n"
        s += "\n"
        
        try s.write(toFile: file, atomically: true, encoding: .utf8)
    }
    
    func duplicate() -> Theme {
        let t = Theme(name: self.name)
        t.desc = self.desc
        
        let exportProperty = { (dstTheme: Theme, name: PropertyName) in
            let src = self[name]!
            let dst = dstTheme[name]!
            dst.color = src.color
            dst.bold = src.bold
            dst.italic = src.italic
            dst.underline = src.underline
        }
        exportProperty(t, .plain)
        exportProperty(t, .canvas)
        exportProperty(t, .number)
        exportProperty(t, .string)
        exportProperty(t, .escape)
        exportProperty(t, .preProcessor)
        exportProperty(t, .stringPreProc)
        exportProperty(t, .blockComment)
        exportProperty(t, .lineComment)
        exportProperty(t, .lineNum)
        exportProperty(t, .operator)
        exportProperty(t, .interpolation)
        for keyword in self.keywords {
            let k = PropertyStyle(color: keyword.color, italic: keyword.italic, bold: keyword.bold, underline: keyword.underline)
            t.keywords.append(k)
        }
        return t
    }
}

class ThemePreview: Theme {
    fileprivate var _image_is_set = false
    fileprivate var _image: NSImage? = nil
    
    @objc dynamic var image: NSImage? {
        if !_image_is_set {
            _image = self.getImage(forSize: CGSize(width: 100, height: 100), font: NSFont.systemFont(ofSize: 8))
            _image_is_set = true
        }
        return _image
    }
    
    func invalidateImage() {
        self.willChangeValue(forKey: #keyPath(image))
        _image = nil
        _image_is_set = false
        self.didChangeValue(forKey: #keyPath(image))
    }
    
    func getAttributedTitle() -> NSAttributedString {
        let s = NSMutableAttributedString(string: self.name)
        if !desc.isEmpty {
            s.append(NSAttributedString(string: "\n\(desc)", attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]))
        }
        return s
    }
    
    override func duplicate() -> ThemePreview {
        let t = ThemePreview(name: self.name)
        t.desc = self.desc
        
        let exportProperty = { (dstTheme: Theme, name: PropertyName) in
            let src = self[name]!
            let dst = dstTheme[name]!
            dst.color = src.color
            dst.bold = src.bold
            dst.italic = src.italic
            dst.underline = src.underline
        }
        exportProperty(t, .plain)
        exportProperty(t, .canvas)
        exportProperty(t, .number)
        exportProperty(t, .string)
        exportProperty(t, .escape)
        exportProperty(t, .preProcessor)
        exportProperty(t, .stringPreProc)
        exportProperty(t, .blockComment)
        exportProperty(t, .lineComment)
        exportProperty(t, .lineNum)
        exportProperty(t, .operator)
        exportProperty(t, .interpolation)
        for keyword in self.keywords {
            let k = PropertyStyle(color: keyword.color, italic: keyword.italic, bold: keyword.bold, underline: keyword.underline)
            t.keywords.append(k)
        }
        return t
    }
}

extension NSNotification.Name {
    static let currentThemeDidChange = NSNotification.Name("currentThemeDidChange")
    static let themeDidSaved = NSNotification.Name("themeDidSaved")
    static let themeDidAdded = NSNotification.Name("themeDidAdded")
    static let themeDidDeleted = NSNotification.Name("themeDidDeleted")
}
