import Foundation

public enum LumiShotNotifications {
    public static let triggerExtractOCR = Notification.Name("LumiShot.TriggerExtractOCR")
    public static let didExtractOCRText = Notification.Name("LumiShot.DidExtractOCRText")
    public static let extractedTextKey = "text"
}
