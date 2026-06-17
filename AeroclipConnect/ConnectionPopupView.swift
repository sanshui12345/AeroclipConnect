import SwiftUI

// MARK: - 电量指示器（弹窗 & 灵动岛共用）

struct BatteryCell: View {
    let level: Int?
    let label: String

    private var fill: Color {
        guard let l = level else { return .gray.opacity(0.3) }
        if l > 50 { return .green }
        if l > 20 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(width: 42, height: 18)
                if let l = level {
                    Capsule()
                        .fill(fill)
                        .frame(width: max(5, 42 * CGFloat(l) / 100), height: 18)
                }
                Capsule()
                    .fill(.white.opacity(0.18))
                    .frame(width: 3, height: 10)
                    .offset(x: 43)
            }
            Text(level.map { "\($0)%" } ?? "--")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.55))
        }
    }
}

// MARK: - 连接弹窗主体

struct ConnectionPopupView: View {
    @ObservedObject var manager: BluetoothManager
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            // 拖动条
            RoundedRectangle(cornerRadius: 3)
                .fill(.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            // 耳机图标 + 光晕
            ZStack {
                Circle()
                    .fill(.green.opacity(0.12))
                    .frame(width: pulse ? 100 : 80, height: pulse ? 100 : 80)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "headphones")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .teal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.bottom, 16)

            // 设备名
            Text("Soundcore Aeroclip")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // 状态
            Label("已连接", systemImage: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.green)
                .padding(.top, 4)
                .padding(.bottom, 20)

            // 分隔线
            Divider().background(.white.opacity(0.18))

            // 电量行
            HStack(spacing: 24) {
                BatteryCell(level: manager.battery.left,  label: "左")
                BatteryCell(level: manager.battery.right, label: "右")
                BatteryCell(level: manager.battery.case_, label: "仓")
            }
            .padding(.vertical, 16)
        }
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
        .onAppear { pulse = true }
        .onTapGesture { manager.dismissPopup() }
    }
}
