import Orion
import UIKit
import CoreText

struct Prefs {
    static var enabled = true
    static var alignment = 1
    static var yOffset: CGFloat = 0.0
    static var fontName = "System"
    static var fontStyle = "Normal"

    static func load() {
        CFPreferencesAppSynchronize("com.tuan.simplels15" as CFString)
        let path = "/var/jb/var/mobile/Library/Preferences/com.tuan.simplels15.plist"
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else { return }

        enabled = dict["enabled"] as? Bool ?? true
        alignment = dict["alignment"] as? Int ?? 1
        yOffset = dict["yOffset"] as? CGFloat ?? 0.0
        fontName = dict["fontName"] as? String ?? "System"
        fontStyle = dict["fontStyle"] as? String ?? "Normal"
    }
}

func registerCustomFont(fileName: String) {
    let path = "/var/jb/Library/PreferenceBundles/simplels15prefs.bundle/\(fileName)"
    let url = URL(fileURLWithPath: path)
    guard let dataProvider = CGDataProvider(url: url as CFURL),
          let customFont = CGFont(dataProvider) else { return }
    var error: Unmanaged<CFError>?
    CTFontManagerRegisterGraphicsFont(customFont, &error)
}

class DateViewHook: ClassHook<UIView> {
    static let targetName = "SBFLockScreenDateView"

    func setFrame(_ frame: CGRect) {
        var newFrame = frame
        if Prefs.enabled {
            newFrame.origin.y += Prefs.yOffset
        }
        orig.setFrame(newFrame)
    }

    func setAlignmentPercent(_ percent: Double) {
        guard Prefs.enabled else { orig.setAlignmentPercent(percent); return }
        if Prefs.alignment == 0 { orig.setAlignmentPercent(0.0) }
        else if Prefs.alignment == 1 { orig.setAlignmentPercent(0.5) }
        else { orig.setAlignmentPercent(1.0) }
    }
    
    func alignmentPercent() -> Double {
        guard Prefs.enabled else { return orig.alignmentPercent() }
        if Prefs.alignment == 0 { return 0.0 }
        if Prefs.alignment == 1 { return 0.5 }
        return 1.0
    }
}

class LabelHook: ClassHook<UIView> {
    static let targetName = "SBUILegibilityLabel"

    func setTextAlignment(_ alignment: NSTextAlignment) {
        guard Prefs.enabled,
              let font = target.value(forKey: "font") as? UIFont,
              font.pointSize > 40.0 else {
            orig.setTextAlignment(alignment)
            return
        }

        if Prefs.alignment == 0 { orig.setTextAlignment(.left) }
        else if Prefs.alignment == 1 { orig.setTextAlignment(.center) }
        else { orig.setTextAlignment(.right) }
    }

    func setFont(_ font: UIFont) {
        guard Prefs.enabled, font.pointSize > 40.0 else { orig.setFont(font); return }

        let size = font.pointSize
        var newFont: UIFont?

        if Prefs.fontName == "System" {
            if Prefs.fontStyle == "Bold" { newFont = UIFont.systemFont(ofSize: size, weight: .bold) }
            else { newFont = UIFont.systemFont(ofSize: size, weight: .medium) }
        } else {
            newFont = UIFont(name: Prefs.fontName, size: size)
            if newFont == nil { newFont = UIFont(name: "\(Prefs.fontName)-Regular", size: size) }
        }
        orig.setFont(newFont ?? UIFont.systemFont(ofSize: size, weight: .medium))
    }

    func setTextColor(_ color: UIColor) {
        guard Prefs.enabled,
              let font = target.value(forKey: "font") as? UIFont,
              font.pointSize > 40.0,
              Prefs.fontStyle == "Glass" else {
            orig.setTextColor(color)
            return
        }

        let glassColor = UIColor(white: 1.0, alpha: 0.75)
        target.layer.shadowColor = UIColor.black.cgColor
        target.layer.shadowOffset = CGSize(width: 0, height: 2)
        target.layer.shadowRadius = 4.0
        target.layer.shadowOpacity = 0.5
        target.layer.masksToBounds = false

        orig.setTextColor(glassColor)
    }
}

struct SimpleLS15: Tweak {
    init() {
        Prefs.load()
        registerCustomFont(fileName: "lobster.ttf")

        let name = CFNotificationName("com.tuan.simplels15/ReloadPrefs" as CFString)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in Prefs.load() },
            name.rawValue,
            nil,
            .deliverImmediately
        )
    }
}