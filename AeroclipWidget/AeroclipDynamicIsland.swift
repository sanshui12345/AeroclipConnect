import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - 锁屏 / 通知横幅视图

struct AeroclipLockScreenView: View {
    let context: ActivityViewContext<AeroclipAttributes>

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "headphones")
                .font(.system(size: 28))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.deviceName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if context.state.isConnected {
                    HStack(spacing: 12) {
                        BatteryPill(label: "L", level: context.state.batteryLeft)
                        BatteryPill(label: "R", level: context.state.batteryRight)
                        BatteryPill(label: "仓", level: context.state.batteryCase)
                    }
                } else {
                    Text("已断开连接")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(.black.opacity(0.8))
    }
}

// MARK: - 灵动岛内嵌电量胶囊

struct BatteryPill: View {
    let label: String
    let level: Int?

    var color: Color {
        guard let l = level else { return .gray }
        if l > 50 { return .green }
        if l > 20 { return .yellow }
        return .red
    }

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Text(level.map { "\($0)%" } ?? "--")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - 灵动岛展开视图（电量大卡片）

struct AeroclipExpandedView: View {
    let context: ActivityViewContext<AeroclipAttributes>

    var body: some View {
        VStack(spacing: 6) {
            // 顶部：图标 + 名称 + 状态
            HStack(spacing: 10) {
                Image(systemName: "headphones")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
                Text(context.attributes.deviceName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Label(context.state.isConnected ? "已连接" : "已断开",
                      systemImage: context.state.isConnected
                        ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(context.state.isConnected ? .green : .gray)
            }

            Divider().background(.white.opacity(0.15))

            // 底部：三格电量
            HStack(spacing: 0) {
                Spacer()
                BatteryCell(level: context.state.batteryLeft,  label: "左")
                Spacer()
                BatteryCell(level: context.state.batteryRight, label: "右")
                Spacer()
                BatteryCell(level: context.state.batteryCase,  label: "仓")
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - 灵动岛 Widget 主体

struct AeroclipLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AeroclipAttributes.self) { context in
            // 锁屏 / 横幅
            AeroclipLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开区域
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "headphones")
                        .font(.system(size: 22))
                        .foregroundStyle(.green)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Label(context.state.isConnected ? "已连接" : "断开",
                              systemImage: context.state.isConnected
                                ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(context.state.isConnected ? .green : .gray)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.deviceName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 28) {
                        BatteryCell(level: context.state.batteryLeft,  label: "左")
                        BatteryCell(level: context.state.batteryRight, label: "右")
                        BatteryCell(level: context.state.batteryCase,  label: "仓")
                    }
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // 收起状态左侧：耳机图标
                Image(systemName: "headphones")
                    .foregroundStyle(.green)
                    .font(.system(size: 14, weight: .medium))
            } compactTrailing: {
                // 收起状态右侧：最低电量
                let minBat = [context.state.batteryLeft,
                              context.state.batteryRight].compactMap { $0 }.min()
                if let b = minBat {
                    Text("\(b)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(b > 20 ? .green : .red)
                } else {
                    Image(systemName: "headphones")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                }
            } minimal: {
                // 最小状态
                Image(systemName: "headphones")
                    .foregroundStyle(.green)
            }
            .keylineTint(.green)
        }
    }
}
