import ActivityKit
import Combine
import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject {
    @Published var connectionState: ConnectionState = .idle
    @Published var showPopup = false
    @Published var battery = BatteryInfo()

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var liveActivity: Activity<AeroclipAttributes>?

    private let batteryServiceUUID   = CBUUID(string: "180F")
    private let batteryLevelUUID     = CBUUID(string: "2A19")
    private let nameKeywords         = ["aeroclip", "soundcore aeroclip"]

    enum ConnectionState { case idle, scanning, found, connecting, connected, disconnected }

    struct BatteryInfo {
        var left:  Int? = nil
        var right: Int? = nil
        var case_: Int? = nil
    }

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - 公开操作

    func startScan() {
        guard central.state == .poweredOn else { return }
        connectionState = .scanning
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func connect() {
        guard let p = peripheral else { return }
        connectionState = .connecting
        central.stopScan()
        central.connect(p, options: nil)
    }

    func disconnect() {
        guard let p = peripheral else { return }
        central.cancelPeripheralConnection(p)
    }

    func dismissPopup() {
        withAnimation(.spring(response: 0.35)) { showPopup = false }
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs  = AeroclipAttributes(deviceName: "Soundcore Aeroclip")
        let state  = makeContentState()
        do {
            liveActivity = try Activity.request(
                attributes: attrs,
                contentState: state,
                pushType: nil
            )
        } catch {
            print("[LiveActivity] start error: \(error)")
        }
    }

    private func updateLiveActivity() {
        Task {
            await liveActivity?.update(using: makeContentState())
        }
    }

    private func stopLiveActivity() {
        Task {
            let state = AeroclipAttributes.ContentState(isConnected: false)
            await liveActivity?.end(using: state, dismissalPolicy: .after(.now + 3))
            liveActivity = nil
        }
    }

    private func makeContentState() -> AeroclipAttributes.ContentState {
        .init(isConnected: true,
              batteryLeft:  battery.left,
              batteryRight: battery.right,
              batteryCase:  battery.case_)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn { startScan() }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let name = (peripheral.name ?? "").lowercased()
        guard nameKeywords.contains(where: { name.contains($0) }),
              self.peripheral == nil else { return }
        self.peripheral   = peripheral
        connectionState   = .found
        connect()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionState = .connected
        peripheral.delegate = self
        peripheral.discoverServices([batteryServiceUUID])
        battery = BatteryInfo()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { showPopup = true }
        startLiveActivity()
        // 5 秒后自动收起弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.dismissPopup()
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        self.peripheral = nil
        startScan()
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        self.peripheral = nil
        battery = BatteryInfo()
        stopLiveActivity()
        startScan()
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for svc in services where svc.uuid == batteryServiceUUID {
            peripheral.discoverCharacteristics([batteryLevelUUID], for: svc)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for c in chars where c.uuid == batteryLevelUUID {
            peripheral.readValue(for: c)
            peripheral.setNotifyValue(true, for: c)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == batteryLevelUUID,
              let data = characteristic.value,
              let level = data.first.map({ Int($0) }) else { return }

        // 简单分配：第一次 → 左，第二次 → 右，第三次 → 仓
        if battery.left == nil {
            battery.left = level
        } else if battery.right == nil {
            battery.right = level
        } else if battery.case_ == nil {
            battery.case_ = level
        }
        updateLiveActivity()
    }
}
