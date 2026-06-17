import SwiftUI

struct ContentView: View {
    @StateObject private var manager = BluetoothManager()

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.12),
                         Color(red: 0.08, green: 0.04, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 主内容
            VStack(spacing: 28) {
                Spacer()

                // 图标
                Image(systemName: "headphones")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .teal],
                                       startPoint: .top, endPoint: .bottom)
                    )

                // 标题
                VStack(spacing: 8) {
                    Text("Aeroclip Connect")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(statusText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }

                // 状态卡片
                statusCard

                Spacer()

                // 提示
                Text("连上耳机后弹窗与灵动岛自动出现")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)

            // 连接弹窗
            if manager.showPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { manager.dismissPopup() }

                ConnectionPopupView(manager: manager)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: manager.showPopup)
    }

    private var statusText: String {
        switch manager.connectionState {
        case .idle:         return "初始化蓝牙..."
        case .scanning:     return "正在扫描 Aeroclip..."
        case .found:        return "发现设备，正在连接"
        case .connecting:   return "连接中..."
        case .connected:    return "已连接"
        case .disconnected: return "已断开，重新扫描中"
        }
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(manager.connectionState == .connected ? .green : .orange)
                .frame(width: 10, height: 10)
                .shadow(color: manager.connectionState == .connected ? .green : .orange,
                        radius: 4)

            Text(statusText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            if manager.connectionState == .scanning {
                ProgressView().tint(.white).scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
