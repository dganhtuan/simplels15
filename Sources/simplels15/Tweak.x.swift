import Orion
import UIKit
import CoreText

struct Prefs {
    static var enabled = true
    static var yOffset: CGFloat = 0.0
    static var sizeClock: CGFloat = 80.0
    static var sizeDate: CGFloat = 20.0
    static var fontName = "System"
    static var fontStyle = "Normal"
    static var hideWeather = false
    static var hideLunar = false

    static func load() {
        CFPreferencesAppSynchronize("com.tuan.simplels15" as CFString)
        let path = "/var/jb/var/mobile/Library/Preferences/com.tuan.simplels15.plist"
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else { return }

        enabled = dict["enabled"] as? Bool ?? true
        yOffset = dict["yOffset"] as? CGFloat ?? 0.0
        sizeClock = dict["sizeClock"] as? CGFloat ?? 80.0
        sizeDate = dict["sizeDate"] as? CGFloat ?? 20.0
        fontName = dict["fontName"] as? String ?? "System"
        fontStyle = dict["fontStyle"] as? String ?? "Normal"
        hideWeather = dict["hideWeather"] as? Bool ?? false
        hideLunar = dict["hideLunar"] as? Bool ?? false
    }
}

// Hook vào View chính để xử lý Ẩn và Trục Y
class DateViewHook: ClassHook<UIView> {
    static let targetName = "SBFLockScreenDateView"

    func layoutSubviews() {
        orig.layoutSubviews()
        guard Prefs.enabled else { return }
        
        // Di chuyển trục Y cho cả cụm
        target.transform = CGAffineTransform(translationX: 0, y: Prefs.yOffset)
    }
}

// Hook vào các nhãn văn bản để xử lý Font, Size và Ẩn thành phần
class LabelHook: ClassHook<UIView> {
    static let targetName = "SBUILegibilityLabel"

    func setFont(_ font: UIFont) {
        guard Prefs.enabled else { orig.setFont(font); return }
        
        var finalSize = font.pointSize
        let isClock = font.pointSize > 50.0 // Đồng hồ thường rất to
        let isDate = font.pointSize > 15.0 && font.pointSize <= 50.0 // Ngày tháng

        if isClock { finalSize = Prefs.sizeClock }
        else if isDate { finalSize = Prefs.sizeDate }

        var newFont: UIFont?
        if Prefs.fontName == "System" {
            if Prefs.fontStyle == "Bold" { newFont = .systemFont(ofSize: finalSize, weight: .bold) }
            else if Prefs.fontStyle == "Italic" { newFont = .italicSystemFont(ofSize: finalSize) }
            else { newFont = .systemFont(ofSize: finalSize, weight: .medium) }
        } else {
            newFont = UIFont(name: Prefs.fontName, size: finalSize)
            if newFont == nil { newFont = UIFont(name: "\(Prefs.fontName)-Regular", size: finalSize) }
        }
        
        orig.setFont(newFont ?? font)
    }

    func setText(_ text: String?) {
        guard Prefs.enabled, let text = text else { orig.setText(text); return }
        
        // Xử lý ẩn Lịch âm (thường chứa các từ như "Giáp", "Ất", "Bính" hoặc định dạng ngày âm)
        if Prefs.hideLunar && (text.contains("tháng") && text.count > 15) {
            target.isHidden = true
            target.alpha = 0
            return
        }
        
        orig.setText(text)
    }
}

// Hook riêng cho Thời tiết (thường nằm trong Subtitle View)
class SubtitleHook: ClassHook<UIView> {
    static let targetName = "SBFLockScreenDateSubtitleView"
    
    func layoutSubviews() {
        orig.layoutSubviews()
        if Prefs.enabled && Prefs.hideWeather {
            target.isHidden = true
            target.alpha = 0
        }
    }
}

struct SimpleLS15: Tweak {
    init() {
        Prefs.load()
        // Đăng ký font Lobster
        let fontPath = "/var/jb/Library/PreferenceBundles/simplels15prefs.bundle/lobster.ttf"
        let url = URL(fileURLWithPath: fontPath)
        if let dataProvider = CGDataProvider(url: url as CFURL), let font = CGFont(dataProvider) {
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterGraphicsFont(font, &error)
        }

        let name = CFNotificationName("com.tuan.simplels15/ReloadPrefs" as CFString)
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { _, _, _, _, _ in Prefs.load() }, name.rawValue, nil, .deliverImmediately)
    }
}
