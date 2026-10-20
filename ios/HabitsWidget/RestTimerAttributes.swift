import ActivityKit
import Foundation

/// ⚠️ الملف ده لازم يكون في الـ Target الاتنين: Runner و HabitsWidget
/// (التطبيق بيبدأ الـ Live Activity، والـ Widget Extension بيرسمها).
@available(iOS 16.1, *)
struct RestTimerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// وقت نهاية الراحة (لو العداد واقف: الوقت + المتبقي)
    var endsAt: Date
    var totalSeconds: Int
    /// موجود لو العداد متوقف مؤقتاً
    var pausedRemaining: Int?
    /// مثلاً: "Chest • Upper • Set 3"
    var label: String

    var startedAt: Date { endsAt.addingTimeInterval(-Double(max(totalSeconds, 1))) }
    var isPaused: Bool { pausedRemaining != nil }
  }
}
