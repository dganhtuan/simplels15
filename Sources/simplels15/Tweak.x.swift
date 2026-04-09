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

// 1. AN TOÀN TRỤC Y (Dùng setFrame để tránh lặp vô hạn AutoLayout)
class DateViewHook: ClassHook<UIView> {
    static let targetName = "SBFLockScreenDateView"

    func setFrame(_ frame: CGRect) {
        var newFrame = frame
        if Prefs.enabled {
            newFrame.origin.y += Prefs.yOffset
        }
        orig.setFrame(newFrame)
    }
}

// 2. CHỐNG ĐẠN FONT CHỮ VÀ VĂN BẢN
class LabelHook: ClassHook<UIView> {
    static let targetName = "SBUILegibilityLabel"

    // Thêm dấu '?' để không bị nổ khi Apple gửi font Rỗng (nil)
    func setFont(_ font: UIFont?) {
        guard Prefs.enabled, let realFont = font else {
            orig.setFont(font)
            return
        }
        
        var finalSize = realFont.pointSize
        let isClock = realFont.pointSize > 50.0
        let isDate = realFont.pointSize > 15.0 && realFont.pointSize <= 50.0

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
        
        orig.setFont(newFont ?? realFont)
    }

    // Đổi thành setString và có dấu '?'
    func setString(_ string: String?) {
        guard Prefs.enabled, let text = string else {
            orig.setString(string)
            return
        }
        
        // Nhận diện ngày tháng âm lịch (Thường có chữ 'tháng' và khá dài)
        if Prefs.hideLunar && text.lowercased().contains("tháng") && text.count > 10 {
            target.isHidden = true
            target.alpha = 0
            return
        }
        
        orig.setString(string)
    }
    
    // Thêm lại hiệu ứng Glass với bảo mật '?'
    func setTextColor(_ color: UIColor?) {
        guard Prefs.enabled else {
            orig.setTextColor(color)
            return
        }
        
        if Prefs.fontStyle == "Glass",
           let font = target.value(forKey: "font") as? UIFont,
           font.pointSize > 40.0 {
            
            let glassColor = UIColor(white: 1.0, alpha: 0.75)
            target.layer.shadowColor = UIColor.black.cgColor
            target.layer.shadowOffset = CGSize(width: 0, height: 2)
            target.layer.shadowRadius = 4.0
            target.layer.shadowOpacity = 0.5
            target.layer.masksToBounds = false
            
            orig.setTextColor(glassColor)
            return
        }
        
        orig.setTextColor(color)
    }
}

// 3. ẨN THỜI TIẾT
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

// 4. KHỞI TẠO TWEAK
struct SimpleLS15: Tweak {
    init() {
        Prefs.load()
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
