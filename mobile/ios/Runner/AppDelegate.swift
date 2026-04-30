import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let converter = AudioConverter()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "mp3craft/audio_converter",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "convertToWav":
                self.handleConvert(call: call, result: result)
            case "crop":
                self.handleCrop(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func handleConvert(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let source = args["sourcePath"] as? String,
              let target = args["targetPath"] as? String
        else {
            result(FlutterError(code: "BAD_ARGS", message: "sourcePath/targetPath required", details: nil))
            return
        }
        Task {
            do {
                let r = try await converter.convertToWav(sourcePath: source, targetPath: target)
                await MainActor.run {
                    result(["path": r.path, "durationMs": r.durationMs])
                }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "CONVERT_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handleCrop(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let source = args["sourcePath"] as? String,
              let target = args["targetPath"] as? String,
              let startMs = args["startMs"] as? Int,
              let endMs = args["endMs"] as? Int
        else {
            result(FlutterError(code: "BAD_ARGS", message: "sourcePath/targetPath/startMs/endMs required", details: nil))
            return
        }
        Task {
            do {
                let path = try await converter.crop(sourcePath: source, targetPath: target, startMs: startMs, endMs: endMs)
                await MainActor.run { result(["path": path]) }
            } catch {
                await MainActor.run {
                    result(FlutterError(code: "CROP_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
}
