import Foundation
import SwiftUI

/// لازم يطابق HomeWidgetService.appGroupId في Flutter
let habitsAppGroup = "group.com.example.gymapp"
let habitsWidgetKind = "HabitsWidget"

// MARK: - Brand colors (نفس AppTheme في Flutter)

extension Color {
  init(hex: UInt, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: opacity
    )
  }

  static let brandPrimary = Color(hex: 0x7C5CFF)
  static let brandSecondary = Color(hex: 0x22D3EE)
  static let brandWarning = Color(hex: 0xFBBF24)
  static let bgStart = Color(hex: 0x0A0A1F)
  static let bgMid = Color(hex: 0x11113A)
  static let bgEnd = Color(hex: 0x0B1B36)
}

// MARK: - Snapshot of today's habits

struct HabitsSnapshot {
  var name: String
  var score: Int          // 0..100
  var waterAmount: Int    // ml (شامل اللي اتضاف من الـ Widget)
  var waterGoal: Int
  var sleepHours: Double
  var meals: Int
  var tasksDone: Int
  var tasksTotal: Int
  var gymStreak: Int
  var activeStreak: Int
  var heat: [Int]         // آخر 35 يوم، آخر عنصر = النهارده

  var waterFraction: Double {
    waterGoal > 0 ? min(Double(waterAmount) / Double(waterGoal), 1) : 0
  }

  static let placeholder = HabitsSnapshot(
    name: "", score: 72, waterAmount: 1500, waterGoal: 2000, sleepHours: 7,
    meals: 2, tasksDone: 3, tasksTotal: 5, gymStreak: 6, activeStreak: 9,
    heat: (0..<35).map { i in [0, 20, 45, 70, 95][(i * 7 + i / 3) % 5] }
  )
}

enum HabitsStore {
  static var defaults: UserDefaults? { UserDefaults(suiteName: habitsAppGroup) }

  private static let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f
  }()

  static func dayString(_ date: Date = Date()) -> String { dayFormatter.string(from: date) }

  /// المياه اللي اتضافت من زرار الـ Widget ولسه التطبيق ماسجلهاش.
  static func pendingWater() -> Int {
    guard let d = defaults, d.string(forKey: "water_pending_day") == dayString() else { return 0 }
    return d.integer(forKey: "water_pending")
  }

  static func addPendingWater(_ amount: Int) {
    let d = defaults
    d?.set(pendingWater() + amount, forKey: "water_pending")
    d?.set(dayString(), forKey: "water_pending_day")
  }

  static func load() -> HabitsSnapshot {
    guard let d = defaults, d.object(forKey: "day") != nil else { return .placeholder }

    let savedDay = d.string(forKey: "day") ?? ""
    let isToday = savedDay == dayString()
    var heat = (d.string(forKey: "heat") ?? "")
      .split(separator: ",").compactMap { Int($0) }

    // لو التطبيق ماتفتحش من كام يوم: نزحلق الخريطة ونصفّر بيانات النهارده
    if !isToday, let saved = dayFormatter.date(from: savedDay) {
      let gap = Calendar.current.dateComponents(
        [.day], from: saved, to: Calendar.current.startOfDay(for: Date())
      ).day ?? 0
      if gap > 0 {
        heat = Array(heat.dropFirst(min(gap, heat.count))) + Array(repeating: 0, count: min(gap, 35))
      }
    }

    let goal = d.integer(forKey: "water_goal")
    let pending = pendingWater()
    let savedWater = isToday ? d.integer(forKey: "water_amount") : 0
    var score = isToday ? d.integer(forKey: "score") : 0

    // نحدّث النتيجة فوراً بعد الضغط على "+250" من غير ما نفتح التطبيق
    if pending > 0, goal > 0 {
      let parts = max(d.integer(forKey: "score_parts"), 3)
      let before = min(Double(savedWater) / Double(goal), 1)
      let after = min(Double(savedWater + pending) / Double(goal), 1)
      score = min(100, score + Int(((after - before) * 100 / Double(parts)).rounded()))
      if !heat.isEmpty { heat[heat.count - 1] = score }
    }

    return HabitsSnapshot(
      name: d.string(forKey: "name") ?? "",
      score: score,
      waterAmount: savedWater + pending,
      waterGoal: goal > 0 ? goal : 2000,
      sleepHours: isToday ? d.double(forKey: "sleep_hours") : 0,
      meals: isToday ? d.integer(forKey: "meals") : 0,
      tasksDone: isToday ? d.integer(forKey: "tasks_done") : 0,
      tasksTotal: isToday ? d.integer(forKey: "tasks_total") : 0,
      gymStreak: d.integer(forKey: "gym_streak"),
      activeStreak: d.integer(forKey: "active_streak"),
      heat: heat
    )
  }
}
