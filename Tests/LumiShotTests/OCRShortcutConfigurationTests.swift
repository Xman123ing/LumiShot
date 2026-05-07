import XCTest
import LumiShotKit

final class OCRShortcutConfigurationTests: XCTestCase {
    func testRecorderDerivedConfigurationStoresModifiers() {
        XCTAssertEqual(OCRShortcutStorage.key, "settings.ocrShortcut.key")
        XCTAssertEqual(OCRShortcutStorage.useCommand, "settings.ocrShortcut.useCommand")
        XCTAssertEqual(OCRShortcutStorage.useShift, "settings.ocrShortcut.useShift")
        XCTAssertEqual(OCRShortcutStorage.useOption, "settings.ocrShortcut.useOption")
        XCTAssertEqual(OCRShortcutStorage.useControl, "settings.ocrShortcut.useControl")

        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        defaults.set("x", forKey: OCRShortcutStorage.key)
        defaults.set(true, forKey: OCRShortcutStorage.useCommand)
        defaults.set(true, forKey: OCRShortcutStorage.useShift)
        defaults.set(false, forKey: OCRShortcutStorage.useOption)
        defaults.set(false, forKey: OCRShortcutStorage.useControl)

        XCTAssertEqual(defaults.string(forKey: OCRShortcutStorage.key), "x")
        XCTAssertTrue(defaults.bool(forKey: OCRShortcutStorage.useCommand))
        XCTAssertTrue(defaults.bool(forKey: OCRShortcutStorage.useShift))
        XCTAssertFalse(defaults.bool(forKey: OCRShortcutStorage.useOption))
        XCTAssertFalse(defaults.bool(forKey: OCRShortcutStorage.useControl))

        let configuration = OCRShortcutConfiguration.load(from: defaults)

        XCTAssertEqual(configuration.storageKey, "x")
        XCTAssertTrue(configuration.useCommand)
        XCTAssertTrue(configuration.useShift)
        XCTAssertFalse(configuration.useOption)
        XCTAssertFalse(configuration.useControl)
    }

    func testLoadUsesCommandByDefaultWhenUseCommandUnset() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        defaults.set("z", forKey: OCRShortcutStorage.key)

        XCTAssertNil(defaults.object(forKey: OCRShortcutStorage.useCommand))

        let configuration = OCRShortcutConfiguration.load(from: defaults)

        XCTAssertEqual(configuration.storageKey, "z")
        XCTAssertTrue(
            configuration.useCommand,
            "Existing installs without useCommand saved should behave like Command + key"
        )
    }

    func testInvalidKeyFallbackToDefaultStorageKey() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        defaults.set("@@@", forKey: OCRShortcutStorage.key)
        defaults.set(false, forKey: OCRShortcutStorage.useCommand)

        let configuration = OCRShortcutConfiguration.load(from: defaults)

        XCTAssertEqual(configuration.storageKey, OCRShortcutConfiguration.defaultStorageKey)
    }

    func testNormalizedStorageKeySkipsGarbageToFirstAlnum() {
        XCTAssertEqual(OCRShortcutConfiguration.normalizedStorageKey("@@@x"), "x")
        XCTAssertEqual(OCRShortcutConfiguration.normalizedStorageKey(""), OCRShortcutConfiguration.defaultStorageKey)
    }
}
