//
//  widgetControl.swift
//  widget
//
//  Created by Hyeonwoo Park on 7/3/25.
//

import AppIntents
import SwiftUI
import WidgetKit
import Network




struct widgetControl: ControlWidget {
    static let kind: String = "net.lative.helloudp.widget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "문열기",
                isOn: value.isRunning,
                action: NetworkCallIntent()
            ) { isRunning in
                Label(isRunning ? "통신중.." : "문열기", systemImage: "house")
            }
        }
        .displayName("문열기")
        .description("Open the door")
    }
}

extension widgetControl {
    struct Value {
        var isRunning: Bool
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: WidgetConfiguration) -> Value {
            widgetControl.Value(isRunning: false)
        }

        func currentValue(configuration: WidgetConfiguration) async throws -> Value {
            let isRunning = UserDefaults.standard.object(forKey: "isProcess") as? Bool ?? false;

            return widgetControl.Value(isRunning: isRunning)
        }
    }
}

struct WidgetConfiguration: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Door"
}

struct NetworkCallIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Door"

//    @Parameter(title: "Timer Name")
//    var name: String
//
    @Parameter(title: "통신 여부")
    var value: Bool

    init() {}


    func perform() async throws -> some IntentResult {
        if (value) { sendUDPPacket(); }
        
        return .result()
    }
    
    func sendUDPPacket() {
        let message: String = "open-door";
        let host = NWEndpoint.Host("10.3.60.118");
        let port = NWEndpoint.Port(rawValue: 12345)!;
        let connection = NWConnection(host: host, port: port, using: .udp)

        UserDefaults.standard.set(true, forKey: "isProcess")
        UserDefaults.standard.synchronize()

        connection.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Connection ready")
                let data = message.data(using: .utf8)!
                connection.send(content: data, completion: .contentProcessed { error in
                    if let error = error {
                        print("Send error: \(error)")
                    } else {
                        print("Message sent")
                    }
                    connection.cancel()
                })
            case .failed(let error):
                print("Connection failed: \(error)")
            default:
                break
            }
            
            UserDefaults.standard.set(false, forKey: "isProcess")
            UserDefaults.standard.synchronize()
        }

        connection.start(queue: .global())
    }

}
