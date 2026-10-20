import AppIntents
import WidgetKit

/// زرار "+250 مل" التفاعلي (iOS 17+).
/// بيسجّل الكمية في الـ App Group من غير ما يفتح التطبيق،
/// والتطبيق بيضيفها لـ Hive أول ما يتفتح (HomeWidgetService.consumePendingWater).
@available(iOS 17.0, *)
struct AddWaterIntent: AppIntent {
  static var title: LocalizedStringResource = "إضافة مياه"
  static var description = IntentDescription("يضيف كمية مياه لهدف النهارده")

  @Parameter(title: "الكمية (مل)", default: 250)
  var amount: Int

  init() {}

  init(amount: Int) {
    self.amount = amount
  }

  func perform() async throws -> some IntentResult {
    HabitsStore.addPendingWater(amount)
    WidgetCenter.shared.reloadTimelines(ofKind: habitsWidgetKind)
    return .result()
  }
}
