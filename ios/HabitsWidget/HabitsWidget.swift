import SwiftUI
import WidgetKit

// MARK: - Timeline

struct HabitsEntry: TimelineEntry {
  let date: Date
  let data: HabitsSnapshot
}

struct HabitsProvider: TimelineProvider {
  func placeholder(in context: Context) -> HabitsEntry {
    HabitsEntry(date: Date(), data: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (HabitsEntry) -> Void) {
    completion(HabitsEntry(date: Date(), data: context.isPreview ? .placeholder : HabitsStore.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HabitsEntry>) -> Void) {
    // التطبيق بيعمل reload مع كل تغيير؛ وإحنا بنحدّث تلقائياً بعد نص الليل عشان اليوم الجديد
    let entry = HabitsEntry(date: Date(), data: HabitsStore.load())
    let midnight = Calendar.current.nextDate(
      after: Date(), matching: DateComponents(hour: 0, minute: 1), matchingPolicy: .nextTime
    ) ?? Date().addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(midnight)))
  }
}

// MARK: - Widget

struct HabitsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: habitsWidgetKind, provider: HabitsProvider()) { entry in
      HabitsWidgetView(entry: entry)
    }
    .configurationDisplayName("عاداتي")
    .description("نتيجة يومك، المياه، المهام وسلسلة الالتزام.")
    .supportedFamilies([
      .systemSmall, .systemMedium, .systemLarge,
      .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ])
  }
}

@main
struct HabitsWidgetBundle: WidgetBundle {
  var body: some Widget {
    HabitsWidget()
    RestTimerLiveActivity()
  }
}

// MARK: - Root view

struct HabitsWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: HabitsEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      CircularAccessory(data: entry.data)
        .widgetBackground(AccessoryWidgetBackground())
    case .accessoryRectangular:
      RectangularAccessory(data: entry.data)
        .widgetBackground(Color.clear)
    case .accessoryInline:
      Text("عاداتي • \(entry.data.score)% • 💧 \(Int(entry.data.waterFraction * 100))%")
        .widgetBackground(Color.clear)
    case .systemMedium:
      MediumView(data: entry.data)
        .homeScreenStyle(link: "habits://home?homeWidget")
    case .systemLarge:
      LargeView(data: entry.data, date: entry.date)
        .homeScreenStyle(link: "habits://home?homeWidget")
    default:
      SmallView(data: entry.data)
        .homeScreenStyle(link: "habits://home?homeWidget")
    }
  }
}

// MARK: - Home screen sizes

struct SmallView: View {
  let data: HabitsSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("نتيجة يومك")
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(.white.opacity(0.75))
        Spacer()
        Image(systemName: "sparkles")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(Color.brandSecondary)
          .widgetAccentable()
      }
      ScoreRing(score: data.score, lineWidth: 9, fontSize: 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      HStack(spacing: 6) {
        Chip(text: "🔥 \(data.gymStreak)")
        Chip(text: "💧 \(Int(data.waterFraction * 100))%")
      }
    }
  }
}

struct MediumView: View {
  let data: HabitsSnapshot

  var body: some View {
    HStack(spacing: 14) {
      VStack(spacing: 6) {
        ScoreRing(score: data.score, lineWidth: 10, fontSize: 30)
        Text("نتيجة يومك")
          .font(.system(size: 11, weight: .semibold, design: .rounded))
          .foregroundStyle(.white.opacity(0.7))
      }
      .frame(width: 112)

      VStack(spacing: 8) {
        WaterRow(data: data)
        HStack(spacing: 8) {
          StatTile(icon: "checkmark.circle.fill", value: "\(data.tasksDone)/\(data.tasksTotal)", label: "مهام", tint: .brandPrimary)
          StatTile(icon: "flame.fill", value: "\(data.gymStreak)", label: "سلسلة", tint: .brandWarning)
          StatTile(icon: "moon.zzz.fill", value: String(format: "%.1f", data.sleepHours), label: "نوم", tint: Color(hex: 0x818CF8))
        }
      }
    }
  }
}

struct LargeView: View {
  let data: HabitsSnapshot
  let date: Date

  private var greeting: String {
    let h = Calendar.current.component(.hour, from: date)
    let base = h < 12 ? "صباح الخير" : (h < 18 ? "مساء النور" : "مساء الخير")
    return data.name.isEmpty ? base : "\(base)، \(data.name)"
  }

  private var dateText: String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ar")
    f.dateFormat = "EEEE، d MMMM"
    return f.string(from: date)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(greeting)
          .font(.system(size: 17, weight: .heavy, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
        Text(dateText)
          .font(.system(size: 12, design: .rounded))
          .foregroundStyle(.white.opacity(0.55))
      }

      MediumView(data: data)
        .frame(height: 120)

      GlassPanel {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("خريطة العادات")
              .font(.system(size: 13, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
            Spacer()
            Text("🔥 \(data.activeStreak) يوم نشط")
              .font(.system(size: 11, weight: .semibold, design: .rounded))
              .foregroundStyle(.white.opacity(0.7))
          }
          HeatGrid(heat: data.heat)
        }
        .padding(12)
      }
    }
  }
}

// MARK: - Lock screen

struct CircularAccessory: View {
  let data: HabitsSnapshot

  var body: some View {
    Gauge(value: Double(data.score), in: 0...100) {
      Image(systemName: "sparkles")
    } currentValueLabel: {
      Text("\(data.score)")
        .font(.system(size: 16, weight: .bold, design: .rounded))
    }
    .gaugeStyle(.accessoryCircularCapacity)
    .widgetAccentable()
  }
}

struct RectangularAccessory: View {
  let data: HabitsSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("عاداتي • \(data.score)%")
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .widgetAccentable()
      Text("💧 \(data.waterAmount) / \(data.waterGoal) مل")
        .font(.system(size: 12, design: .rounded))
      Text("🔥 \(data.gymStreak) يوم  •  ✅ \(data.tasksDone)/\(data.tasksTotal)")
        .font(.system(size: 12, design: .rounded))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Components

struct ScoreRing: View {
  let score: Int
  let lineWidth: CGFloat
  let fontSize: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .stroke(.white.opacity(0.12), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: CGFloat(max(0, min(score, 100))) / 100)
        .stroke(
          AngularGradient(
            colors: [.brandPrimary, .brandSecondary, .brandPrimary],
            center: .center
          ),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .shadow(color: .brandSecondary.opacity(0.5), radius: 4)
        .widgetAccentable()
      Text("\(score)")
        .font(.system(size: fontSize, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .minimumScaleFactor(0.6)
    }
    .padding(lineWidth / 2)
  }
}

struct WaterRow: View {
  let data: HabitsSnapshot

  var body: some View {
    GlassPanel {
      HStack(spacing: 8) {
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 4) {
            Image(systemName: "drop.fill")
              .foregroundStyle(Color.brandSecondary)
              .widgetAccentable()
            Text("\(data.waterAmount) / \(data.waterGoal)")
              .font(.system(size: 12, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.7)
          }
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule().fill(.white.opacity(0.12))
              Capsule()
                .fill(LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing))
                .frame(width: geo.size.width * data.waterFraction)
                .widgetAccentable()
            }
          }
          .frame(height: 6)
        }
        AddWaterButton()
      }
      .padding(10)
    }
  }
}

/// iOS 17+: زرار تفاعلي بيضيف من غير فتح التطبيق. iOS 16: لينك بيفتح شاشة المياه.
struct AddWaterButton: View {
  private var label: some View {
    Text("+250")
      .font(.system(size: 12, weight: .heavy, design: .rounded))
      .foregroundStyle(.white)
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(
        Capsule().fill(LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
      )
      .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 0.5))
  }

  var body: some View {
    if #available(iOS 17.0, *) {
      Button(intent: AddWaterIntent(amount: 250)) { label }
        .buttonStyle(.plain)
    } else {
      Link(destination: URL(string: "habits://water?homeWidget")!) { label }
    }
  }
}

struct StatTile: View {
  let icon: String
  let value: String
  let label: String
  let tint: Color

  var body: some View {
    GlassPanel {
      VStack(spacing: 2) {
        Image(systemName: icon)
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(tint)
          .widgetAccentable()
        Text(value)
          .font(.system(size: 13, weight: .heavy, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        Text(label)
          .font(.system(size: 9, weight: .medium, design: .rounded))
          .foregroundStyle(.white.opacity(0.6))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
    }
  }
}

struct Chip: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.system(size: 11, weight: .bold, design: .rounded))
      .foregroundStyle(.white)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Capsule().fill(.white.opacity(0.12)))
      .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 0.5))
  }
}

/// لوح "زجاجي": شفافية + حدّ فاتح (الـ Widgets مابتدعمش blur حقيقي للي وراها).
struct GlassPanel<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    content
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(.white.opacity(0.08))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(.white.opacity(0.16), lineWidth: 0.7)
      )
  }
}

/// 5 أسابيع × 7 أيام، كل عمود أسبوع والأحدث في الآخر.
struct HeatGrid: View {
  let heat: [Int]

  private func color(_ score: Int) -> Color {
    switch score {
    case ..<1: return .white.opacity(0.08)
    case ..<25: return .brandPrimary.opacity(0.35)
    case ..<50: return .brandPrimary.opacity(0.6)
    case ..<75: return .brandPrimary.opacity(0.9)
    default: return .brandSecondary
    }
  }

  var body: some View {
    let cells = Array(heat.suffix(35))
    let padded = Array(repeating: 0, count: max(0, 35 - cells.count)) + cells
    HStack(spacing: 4) {
      ForEach(0..<5, id: \.self) { week in
        VStack(spacing: 4) {
          ForEach(0..<7, id: \.self) { day in
            let i = week * 7 + day
            RoundedRectangle(cornerRadius: 3, style: .continuous)
              .fill(color(padded[i]))
              .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                  .stroke(i == 34 ? Color.brandSecondary : .clear, lineWidth: 1.2)
              )
              .aspectRatio(1, contentMode: .fit)
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Background helpers

/// الخلفية: نفس "الأورورا" اللي في التطبيق.
struct AuroraWidgetBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(colors: [.bgStart, .bgMid, .bgEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
      RadialGradient(colors: [Color.brandPrimary.opacity(0.45), .clear], center: .topLeading, startRadius: 0, endRadius: 180)
      RadialGradient(colors: [Color.brandSecondary.opacity(0.35), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 170)
    }
  }
}

extension View {
  /// containerBackground على iOS 17+، و background + padding على iOS 16.
  @ViewBuilder
  func widgetBackground<B: View>(_ background: B) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      self.padding(14).background(background)
    }
  }

  /// ستايل الشاشة الرئيسية: عربي (RTL) + خلفية الأورورا + لينك للتطبيق.
  func homeScreenStyle(link: String) -> some View {
    self
      .environment(\.layoutDirection, .rightToLeft)
      .widgetURL(URL(string: link))
      .widgetBackground(AuroraWidgetBackground())
  }
}
