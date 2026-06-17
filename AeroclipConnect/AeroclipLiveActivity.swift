import ActivityKit
import Foundation

struct AeroclipAttributes: ActivityAttributes {
    public typealias AeroclipStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var isConnected: Bool
        var batteryLeft: Int?
        var batteryRight: Int?
        var batteryCase: Int?
    }

    var deviceName: String
}
