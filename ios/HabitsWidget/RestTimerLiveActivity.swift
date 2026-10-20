import ActivityKit
import SwiftUI
import WidgetKit

/// عداد الراحة في الـ Dynamic Island وشاشة القفل.
/// العدّ نفسه بيعمله النظام (Text(timerInterval:)) فمش محتاج تحديثات من التطبيق كل ثانية.
struct RestTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RestTimerAttributes.self) { context in
      RestLockScreenView(state: context.state, isStale: context.isStale)
        .environment(\.layoutDirection, .rightToLeft)
        .activityBackgroundTint(Color.bgStart.opacity(0.88))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let state = context.state
      let stale = context.isStale
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          RestRing(state: state, size: 52, lineWidth: 5)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          RestTimeText(state: state, isStale: stale)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(stale ? Color.green : .white)
            .frame(maxWidth: 110, alignment: .trailing)
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(spacing: 2) {
            Text(stale ? "خلصت الراحة 💪" : (state.isPaused ? "الراحة متوقفة" : "راحة بين الـ sets"))
              .font(.system(size: 14, weight: .bold, design: .rounded))
            Text(state.label)
              .font(.system(size: 12, design: .rounded))
              .foregroundStyle(.white.opacity(0.65))
              .lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          RestProgressBar(state: state)
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
      } compactLeading: {
        Image(systemName: state.isPaused ? "pause.fill" : "timer")
          .foregroundStyle(Color.brandSecondary)
      } compactTrailing: {
        RestTimeText(state: state, isStale: stale)
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundStyle(stale ? Color.green : Color.brandSecondary)
          .frame(width: 46)
      } minimal: {
        RestRing(state: state, size: 22, lineWidth: 3, showIcon: false)
      }
      .widgetURL(URL(string: "habits://gym?homeWidget"))
      .keylineTint(.brandSecondary)
    }
  }
}

// MARK: - Lock screen

struct RestLockScreenView: View {
  let state: RestTimerAttributes.ContentState
  let isStale: Bool

  var body: some View {
    HStack(spacing: 14) {
      RestRing(state: state, size: 54, lineWidth: 6)
      VStack(alignment: .leading, spacing: 3) {
        Text(isStale ? "خلصت الراحة — يلا الـ set الجاي 💪" : (state.isPaused ? "الراحة متوقفة ⏸" : "راحة بين الـ sets"))
          .font(.system(size: 15, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .lineLimit(1)
        Text(state.label)
          .font(.system(size: 12, design: .rounded))
          .foregroundStyle(.white.opacity(0.65))
          .lineLimit(1)
        RestProgressBar(state: state)
          .padding(.top, 4)
      }
      Spacer(minLength: 0)
      RestTimeText(state: state, isStale: isStale)
        .font(.system(size: 34, weight: .heavy, design: .rounded))
        .foregroundStyle(isStale ? Color.green : .white)
        .frame(width: 100, alignment: .trailing)
    }
    .padding(16)
  }
}

// MARK: - Components

/// الوقت المتبقي: بيعدّ لوحده لو شغال، ثابت لو واقف.
struct RestTimeText: View {
  let state: RestTimerAttributes.ContentState
  let isStale: Bool

  var body: some View {
    if let paused = state.pausedRemaining {
      Text(String(format: "%d:%02d", paused / 60, paused % 60))
        .monospacedDigit()
    } else if isStale || state.endsAt <= Date() {
      Text("0:00").monospacedDigit()
    } else {
      Text(timerInterval: state.startedAt...state.endsAt, countsDown: true)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
  }
}

struct RestRing: View {
  let state: RestTimerAttributes.ContentState
  let size: CGFloat
  let lineWidth: CGFloat
  var showIcon = true

  var body: some View {
    Group {
      if let paused = state.pausedRemaining {
        ProgressView(value: Double(paused), total: Double(max(state.totalSeconds, 1))) {
          EmptyView()
        } currentValueLabel: {
          icon("pause.fill")
        }
      } else {
        ProgressView(timerInterval: state.startedAt...state.endsAt, countsDown: true) {
          EmptyView()
        } currentValueLabel: {
          icon("timer")
        }
      }
    }
    .progressViewStyle(.circular)
    .tint(Color.brandSecondary)
    .frame(width: size, height: size)
  }

  @ViewBuilder
  private func icon(_ name: String) -> some View {
    if showIcon {
      Image(systemName: name)
        .font(.system(size: size * 0.32, weight: .bold))
        .foregroundStyle(.white)
    }
  }
}

struct RestProgressBar: View {
  let state: RestTimerAttributes.ContentState

  var body: some View {
    Group {
      if let paused = state.pausedRemaining {
        ProgressView(value: Double(paused), total: Double(max(state.totalSeconds, 1)))
      } else {
        ProgressView(timerInterval: state.startedAt...state.endsAt, countsDown: true) {
          EmptyView()
        } currentValueLabel: {
          EmptyView()
        }
      }
    }
    .progressViewStyle(.linear)
    .tint(LinearGradient(colors: [.brandPrimary, .brandSecondary], startPoint: .leading, endPoint: .trailing))
  }
}
