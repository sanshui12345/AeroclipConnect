import SwiftUI

/// 主 App 和 Widget Extension 共用的电量指示器
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
