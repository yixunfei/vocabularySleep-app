import AVFoundation
import EventKit
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let systemSpeechChannelName = "vocabulary_sleep/system_speech"
  private let systemCalendarChannelName = "vocabulary_sleep/system_calendar"

  private var systemSpeechChannel: FlutterMethodChannel?
  private var systemCalendarChannel: FlutterMethodChannel?
  private let systemCalendarStore = EKEventStore()
  private let systemSpeechAudioEngine = AVAudioEngine()
  private var systemSpeechRecognizer: SFSpeechRecognizer?
  private var systemSpeechRequest: SFSpeechAudioBufferRecognitionRequest?
  private var systemSpeechTask: SFSpeechRecognitionTask?
  private var pendingSystemSpeechStopResult: FlutterResult?
  private var systemSpeechStopTimeoutWorkItem: DispatchWorkItem?
  private var systemSpeechTranscript = ""
  private var systemSpeechLocaleIdentifier: String?
  private var systemSpeechErrorCode: String?
  private var systemSpeechListening = false
  private var systemSpeechFinalized = false
  private var activeSystemSpeechSessionToken: Int?
  private var nextSystemSpeechSessionToken = 0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SystemSpeechBridge")
    let channel = FlutterMethodChannel(
      name: systemSpeechChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleSystemSpeech(call, result: result)
    }
    systemSpeechChannel = channel

    let calendarChannel = FlutterMethodChannel(
      name: systemCalendarChannelName,
      binaryMessenger: registrar.messenger()
    )
    calendarChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleSystemCalendar(call, result: result)
    }
    systemCalendarChannel = calendarChannel
  }

  deinit {
    cancelSystemSpeechRecognition(completePendingStop: false)
  }

  private func handleSystemSpeech(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startListening":
      startSystemSpeech(call.arguments as? [AnyHashable: Any], result: result)
    case "stopListening":
      stopSystemSpeech(result: result)
    case "cancelListening":
      cancelSystemSpeechRecognition()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleSystemCalendar(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "upsertTodoReminder":
      upsertSystemCalendarReminder(call.arguments as? [AnyHashable: Any], result: result)
    case "removeTodoReminder":
      removeSystemCalendarReminder(call.arguments as? [AnyHashable: Any], result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startSystemSpeech(
    _ arguments: [AnyHashable: Any]?,
    result: @escaping FlutterResult
  ) {
    if pendingSystemSpeechStopResult != nil || systemSpeechListening {
      result(buildSystemSpeechCommandResult(success: false, errorCode: "busy"))
      return
    }

    let languageTag = (arguments?["languageTag"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    requestSystemSpeechPermissions { [weak self] errorCode in
      guard let self else {
        result(["success": false, "errorCode": "failed"])
        return
      }
      if let errorCode {
        result(self.buildSystemSpeechCommandResult(success: false, errorCode: errorCode))
        return
      }
      self.beginSystemSpeech(languageTag: languageTag, result: result)
    }
  }

  private func beginSystemSpeech(languageTag: String?, result: @escaping FlutterResult) {
    cancelSystemSpeechRecognition(completePendingStop: false)
    clearSystemSpeechState()

    guard let (recognizer, localeIdentifier) = resolveSystemSpeechRecognizer(languageTag: languageTag) else {
      result(buildSystemSpeechCommandResult(success: false, errorCode: "unavailable"))
      return
    }

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.taskHint = .dictation

    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

      let inputNode = systemSpeechAudioEngine.inputNode
      inputNode.removeTap(onBus: 0)
      let format = inputNode.outputFormat(forBus: 0)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        self?.systemSpeechRequest?.append(buffer)
      }

      systemSpeechAudioEngine.prepare()
      try systemSpeechAudioEngine.start()
    } catch {
      finishSystemSpeechCapture(cancelTask: true)
      result(
        buildSystemSpeechCommandResult(
          success: false,
          errorCode: "start_failed",
          errorMessage: error.localizedDescription
        )
      )
      return
    }

    let sessionToken = nextSystemSpeechSessionToken + 1
    nextSystemSpeechSessionToken = sessionToken
    systemSpeechRecognizer = recognizer
    systemSpeechRequest = request
    systemSpeechLocaleIdentifier = localeIdentifier
    systemSpeechListening = true
    activeSystemSpeechSessionToken = sessionToken

    systemSpeechTask = recognizer.recognitionTask(with: request) { [weak self] recognitionResult, error in
      DispatchQueue.main.async {
        self?.handleSystemSpeechUpdate(
          sessionToken: sessionToken,
          result: recognitionResult,
          error: error
        )
      }
    }

    result(buildSystemSpeechCommandResult(success: true, errorCode: nil))
  }

  private func resolveSystemSpeechRecognizer(languageTag: String?) -> (SFSpeechRecognizer, String)? {
    let requested = normalizeSystemSpeechLocale(languageTag)
    let baseLanguage = Locale(identifier: requested).languageCode
    let candidates = [requested, Locale.current.identifier, baseLanguage]
      .compactMap { value -> String? in
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }

    var seen = Set<String>()
    for identifier in candidates where seen.insert(identifier).inserted {
      let locale = Locale(identifier: identifier)
      guard let recognizer = SFSpeechRecognizer(locale: locale) else {
        continue
      }
      return (recognizer, locale.identifier)
    }
    return nil
  }

  private func normalizeSystemSpeechLocale(_ languageTag: String?) -> String {
    let raw = (languageTag ?? "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "_", with: "-")
    if raw.isEmpty || raw.caseInsensitiveCompare("auto") == .orderedSame ||
      raw.caseInsensitiveCompare("system") == .orderedSame {
      return Locale.current.identifier
    }

    switch raw.lowercased() {
    case "en":
      return "en-US"
    case "en-gb":
      return "en-GB"
    case "zh", "zh-cn", "zh-hans":
      return "zh-CN"
    case "zh-tw", "zh-hk", "zh-hant":
      return "zh-TW"
    case "ja":
      return "ja-JP"
    case "ko":
      return "ko-KR"
    case "de":
      return "de-DE"
    case "fr":
      return "fr-FR"
    case "es":
      return "es-ES"
    case "pt":
      return "pt-BR"
    case "it":
      return "it-IT"
    case "ru":
      return "ru-RU"
    default:
      return raw
    }
  }

  private func stopSystemSpeech(result: @escaping FlutterResult) {
    if pendingSystemSpeechStopResult != nil {
      result(buildSystemSpeechRecognitionResult(errorCode: "busy"))
      return
    }

    if systemSpeechFinalized || (!systemSpeechTranscript.isEmpty && !systemSpeechListening) || systemSpeechErrorCode != nil {
      let response = buildSystemSpeechRecognitionResult()
      finishSystemSpeechCapture(cancelTask: true)
      clearSystemSpeechState()
      result(response)
      return
    }

    guard systemSpeechRequest != nil || systemSpeechTask != nil || systemSpeechAudioEngine.isRunning else {
      result(buildSystemSpeechRecognitionResult(errorCode: "not_listening"))
      return
    }

    pendingSystemSpeechStopResult = result
    systemSpeechListening = false
    stopSystemSpeechCaptureInput()

    let workItem = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.systemSpeechFinalized = true
      self.finishPendingSystemSpeechStop(force: true)
    }
    systemSpeechStopTimeoutWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
  }

  private func handleSystemSpeechUpdate(
    sessionToken: Int,
    result recognitionResult: SFSpeechRecognitionResult?,
    error: Error?
  ) {
    guard activeSystemSpeechSessionToken == sessionToken else {
      return
    }

    if let recognitionResult {
      let text = recognitionResult.bestTranscription.formattedString
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if !text.isEmpty {
        systemSpeechTranscript = text
      }
      if recognitionResult.isFinal {
        systemSpeechErrorCode = nil
        systemSpeechListening = false
        systemSpeechFinalized = true
        finishSystemSpeechCapture(cancelTask: false)
        finishPendingSystemSpeechStop(force: true)
        return
      }
    }

    if error != nil {
      systemSpeechErrorCode = "failed"
      systemSpeechListening = false
      systemSpeechFinalized = true
      finishSystemSpeechCapture(cancelTask: true)
      finishPendingSystemSpeechStop(force: true)
    }
  }

  private func finishPendingSystemSpeechStop(force: Bool) {
    guard force, let stopResult = pendingSystemSpeechStopResult else {
      return
    }
    cancelSystemSpeechStopTimeout()
    let response = buildSystemSpeechRecognitionResult()
    pendingSystemSpeechStopResult = nil
    finishSystemSpeechCapture(cancelTask: true)
    clearSystemSpeechState()
    stopResult(response)
  }

  private func requestSystemSpeechPermissions(_ completion: @escaping (String?) -> Void) {
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized:
      requestMicrophonePermission(completion)
    case .notDetermined:
      SFSpeechRecognizer.requestAuthorization { status in
        DispatchQueue.main.async {
          if status == .authorized {
            self.requestMicrophonePermission(completion)
          } else {
            completion("permission_denied")
          }
        }
      }
    case .denied, .restricted:
      completion("permission_denied")
    @unknown default:
      completion("unavailable")
    }
  }

  private func requestMicrophonePermission(_ completion: @escaping (String?) -> Void) {
    let audioSession = AVAudioSession.sharedInstance()
    switch audioSession.recordPermission {
    case .granted:
      completion(nil)
    case .undetermined:
      audioSession.requestRecordPermission { granted in
        DispatchQueue.main.async {
          completion(granted ? nil : "permission_denied")
        }
      }
    case .denied:
      completion("permission_denied")
    @unknown default:
      completion("unavailable")
    }
  }

  private func cancelSystemSpeechRecognition(completePendingStop: Bool = true) {
    cancelSystemSpeechStopTimeout()
    if completePendingStop, let stopResult = pendingSystemSpeechStopResult {
      systemSpeechErrorCode = "cancelled"
      systemSpeechFinalized = true
      let response = buildSystemSpeechRecognitionResult()
      pendingSystemSpeechStopResult = nil
      finishSystemSpeechCapture(cancelTask: true)
      clearSystemSpeechState()
      stopResult(response)
      return
    }

    pendingSystemSpeechStopResult = nil
    finishSystemSpeechCapture(cancelTask: true)
    clearSystemSpeechState()
  }

  private func stopSystemSpeechCaptureInput() {
    if systemSpeechAudioEngine.isRunning {
      systemSpeechAudioEngine.stop()
    }
    systemSpeechAudioEngine.inputNode.removeTap(onBus: 0)
    systemSpeechRequest?.endAudio()
  }

  private func finishSystemSpeechCapture(cancelTask: Bool) {
    stopSystemSpeechCaptureInput()
    if cancelTask {
      systemSpeechTask?.cancel()
    }
    systemSpeechTask = nil
    systemSpeechRequest = nil
    systemSpeechRecognizer = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func cancelSystemSpeechStopTimeout() {
    systemSpeechStopTimeoutWorkItem?.cancel()
    systemSpeechStopTimeoutWorkItem = nil
  }

  private func clearSystemSpeechState() {
    systemSpeechTranscript = ""
    systemSpeechLocaleIdentifier = nil
    systemSpeechErrorCode = nil
    systemSpeechListening = false
    systemSpeechFinalized = false
    activeSystemSpeechSessionToken = nil
  }

  private func upsertSystemCalendarReminder(
    _ arguments: [AnyHashable: Any]?,
    result: @escaping FlutterResult
  ) {
    requestSystemCalendarPermission { [weak self] errorCode in
      guard let self else {
        result(["success": false, "errorCode": "failed"])
        return
      }
      guard errorCode == nil else {
        result(self.buildSystemCalendarResult(success: false, errorCode: errorCode))
        return
      }
      result(self.upsertSystemCalendarReminderInternal(arguments))
    }
  }

  private func removeSystemCalendarReminder(
    _ arguments: [AnyHashable: Any]?,
    result: @escaping FlutterResult
  ) {
    requestSystemCalendarPermission { [weak self] errorCode in
      guard let self else {
        result(["success": false, "errorCode": "failed"])
        return
      }
      guard errorCode == nil else {
        result(self.buildSystemCalendarResult(success: false, errorCode: errorCode))
        return
      }
      result(self.removeSystemCalendarReminderInternal(arguments))
    }
  }

  private func requestSystemCalendarPermission(_ completion: @escaping (String?) -> Void) {
    if #available(iOS 17.0, *) {
      switch EKEventStore.authorizationStatus(for: .event) {
      case .fullAccess:
        completion(nil)
      case .writeOnly:
        systemCalendarStore.requestFullAccessToEvents { granted, _ in
          DispatchQueue.main.async {
            completion(granted ? nil : "permission_denied")
          }
        }
      case .notDetermined:
        systemCalendarStore.requestFullAccessToEvents { granted, error in
          DispatchQueue.main.async {
            if let error, !granted {
              completion(error.localizedDescription.isEmpty ? "permission_denied" : "failed")
              return
            }
            completion(granted ? nil : "permission_denied")
          }
        }
      case .denied, .restricted:
        completion("permission_denied")
      @unknown default:
        completion("unavailable")
      }
      return
    }

    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized:
      completion(nil)
    case .notDetermined:
      systemCalendarStore.requestAccess(to: .event) { granted, _ in
        DispatchQueue.main.async {
          completion(granted ? nil : "permission_denied")
        }
      }
    case .denied, .restricted:
      completion("permission_denied")
    @unknown default:
      completion("unavailable")
    }
  }

  private func upsertSystemCalendarReminderInternal(
    _ arguments: [AnyHashable: Any]?
  ) -> [String: Any?] {
    guard
      let arguments,
      let title = (arguments["title"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !title.isEmpty,
      let startAtMillis = (arguments["startAtMillis"] as? NSNumber)?.doubleValue
    else {
      return buildSystemCalendarResult(success: false, errorCode: "invalid_args")
    }

    let startDate = Date(timeIntervalSince1970: startAtMillis / 1000)
    let endAtMillis =
      ((arguments["endAtMillis"] as? NSNumber)?.doubleValue ?? (startAtMillis + 30 * 60 * 1000))
    let endDate = Date(timeIntervalSince1970: max(endAtMillis, startAtMillis + 60 * 1000) / 1000)
    let notes = (arguments["description"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let notificationOffsets = readSystemCalendarReminderOffsets(
      arguments["notificationOffsetsMinutes"]
    )
    let alarmOffsets = readSystemCalendarReminderOffsets(arguments["alarmOffsetsMinutes"])
    let reminderOffsets =
      (notificationOffsets + alarmOffsets).isNotEmpty
      ? Array(Set(notificationOffsets + alarmOffsets)).sorted()
      : readSystemCalendarReminderOffsets(arguments["reminderOffsetsMinutes"])
    let existingEventId = (arguments["eventId"] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let event: EKEvent
    if
      let existingEventId,
      !existingEventId.isEmpty,
      let existingEvent = systemCalendarStore.event(withIdentifier: existingEventId)
    {
      event = existingEvent
    } else {
      event = EKEvent(eventStore: systemCalendarStore)
      guard let defaultCalendar = systemCalendarStore.defaultCalendarForNewEvents else {
        return buildSystemCalendarResult(success: false, errorCode: "unavailable")
      }
      event.calendar = defaultCalendar
    }

    if event.calendar == nil {
      event.calendar = systemCalendarStore.defaultCalendarForNewEvents
    }
    guard event.calendar != nil else {
      return buildSystemCalendarResult(success: false, errorCode: "unavailable")
    }

    event.title = title
    event.notes = (notes?.isEmpty == false) ? notes : nil
    event.startDate = startDate
    event.endDate = endDate
    // EventKit exposes a single alarm channel, so notification and alarm offsets
    // are merged into the same event alarm list on iOS.
    event.alarms =
      reminderOffsets.isEmpty
      ? nil
      : reminderOffsets.map { offset in
          EKAlarm(relativeOffset: -TimeInterval(offset * 60))
        }

    do {
      try systemCalendarStore.save(event, span: .thisEvent, commit: true)
      return buildSystemCalendarResult(
        success: true,
        errorCode: nil,
        eventId: event.eventIdentifier
      )
    } catch {
      return buildSystemCalendarResult(
        success: false,
        errorCode: "failed",
        errorMessage: error.localizedDescription
      )
    }
  }

  private func removeSystemCalendarReminderInternal(
    _ arguments: [AnyHashable: Any]?
  ) -> [String: Any?] {
    guard
      let eventId = (arguments?["eventId"] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !eventId.isEmpty
    else {
      return buildSystemCalendarResult(success: true, errorCode: "not_found")
    }

    guard let event = systemCalendarStore.event(withIdentifier: eventId) else {
      return buildSystemCalendarResult(success: true, errorCode: "not_found")
    }

    do {
      try systemCalendarStore.remove(event, span: .thisEvent, commit: true)
      return buildSystemCalendarResult(success: true, errorCode: nil)
    } catch {
      return buildSystemCalendarResult(
        success: false,
        errorCode: "failed",
        errorMessage: error.localizedDescription
      )
    }
  }

  private func buildSystemCalendarResult(
    success: Bool,
    errorCode: String?,
    eventId: String? = nil,
    errorMessage: String? = nil
  ) -> [String: Any?] {
    var payload: [String: Any?] = [
      "success": success,
      "errorCode": errorCode,
      "eventId": eventId,
    ]
    if let errorMessage, !errorMessage.isEmpty {
      payload["errorMessage"] = errorMessage
    }
    return payload
  }

  private func readSystemCalendarReminderOffsets(_ raw: Any?) -> [Int] {
    guard let list = raw as? [Any] else {
      return []
    }

    var offsets = Set<Int>()
    for item in list {
      if let number = item as? NSNumber {
        offsets.insert(max(0, number.intValue))
        continue
      }
      if
        let text = (item as? String)?
          .trimmingCharacters(in: .whitespacesAndNewlines),
        let value = Int(text)
      {
        offsets.insert(max(0, value))
      }
    }
    return offsets.sorted()
  }

  private func buildSystemSpeechCommandResult(
    success: Bool,
    errorCode: String?,
    errorMessage: String? = nil
  ) -> [String: Any?] {
    var payload: [String: Any?] = [
      "success": success,
      "errorCode": errorCode,
    ]
    if let errorMessage, !errorMessage.isEmpty {
      payload["errorMessage"] = errorMessage
    }
    return payload
  }

  private func buildSystemSpeechRecognitionResult(
    errorCode: String? = nil,
    errorMessage: String? = nil
  ) -> [String: Any?] {
    let text = systemSpeechTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
    let resolvedErrorCode: String? = {
      if let errorCode, !errorCode.isEmpty {
        return errorCode
      }
      if !text.isEmpty {
        return nil
      }
      if let systemSpeechErrorCode, !systemSpeechErrorCode.isEmpty {
        return systemSpeechErrorCode
      }
      return "no_match"
    }()

    var payload: [String: Any?] = [
      "success": !text.isEmpty && resolvedErrorCode == nil,
      "text": text.isEmpty ? nil : text,
      "locale": systemSpeechLocaleIdentifier,
      "errorCode": resolvedErrorCode,
    ]
    if let errorMessage, !errorMessage.isEmpty {
      payload["errorMessage"] = errorMessage
    }
    return payload
  }
}
