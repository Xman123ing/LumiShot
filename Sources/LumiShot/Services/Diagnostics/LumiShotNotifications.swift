import Foundation

public enum LumiShotNotifications {
    public static let triggerExtractOCR = Notification.Name("LumiShot.TriggerExtractOCR")
    public static let triggerCapture = Notification.Name("LumiShot.TriggerCapture")
    public static let triggerCopyCapture = Notification.Name("LumiShot.TriggerCopyCapture")
    public static let triggerSaveCapture = Notification.Name("LumiShot.TriggerSaveCapture")
    public static let triggerUndoAnnotation = Notification.Name("LumiShot.TriggerUndoAnnotation")
    public static let requestOpenMainWindow = Notification.Name("LumiShot.RequestOpenMainWindow")
    public static let didExtractOCRText = Notification.Name("LumiShot.DidExtractOCRText")
    public static let extractedTextKey = "text"
}
