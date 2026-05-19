#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <windows.h>

#include <functional>
#include <memory>
#include <mutex>

using namespace flutter;

constexpr UINT kAudioplayersWindowsPlatformThreadMessage = WM_APP + 0x0457;

inline bool HandleAudioplayersWindowsPlatformThreadMessage(
    UINT message,
    LPARAM lparam,
    LRESULT* result) {
  if (message != kAudioplayersWindowsPlatformThreadMessage) {
    return false;
  }

  std::unique_ptr<std::function<void()>> task(
      reinterpret_cast<std::function<void()>*>(lparam));
  if (task) {
    (*task)();
  }
  if (result) {
    *result = 0;
  }
  return true;
}

inline LRESULT CALLBACK AudioplayersWindowsPlatformThreadWindowProc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  LRESULT result = 0;
  if (HandleAudioplayersWindowsPlatformThreadMessage(message, lparam,
                                                     &result)) {
    return result;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

inline HWND GetOrCreateAudioplayersWindowsPlatformThreadWindow() {
  static std::once_flag once;
  static HWND platform_window = nullptr;
  std::call_once(once, []() {
    constexpr wchar_t kWindowClassName[] =
        L"AudioplayersWindowsPlatformThreadWindow";
    WNDCLASSW window_class = {};
    window_class.lpfnWndProc = AudioplayersWindowsPlatformThreadWindowProc;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.lpszClassName = kWindowClassName;
    RegisterClassW(&window_class);
    platform_window =
        CreateWindowExW(0, kWindowClassName, L"", 0, 0, 0, 0, 0,
                        HWND_MESSAGE, nullptr, window_class.hInstance, nullptr);
  });
  return platform_window;
}

template <typename T = EncodableValue>
class EventStreamHandler : public StreamHandler<T> {
 public:
  explicit EventStreamHandler(HWND platform_window = nullptr)
      : platform_window_(platform_window == nullptr
                             ? GetOrCreateAudioplayersWindowsPlatformThreadWindow()
                             : platform_window),
        platform_thread_id_(GetCurrentThreadId()) {}

  virtual ~EventStreamHandler() = default;

  void Success(std::unique_ptr<T> _data) {
    T payload = *_data.get();
    RunOnPlatformThread([this, payload]() {
      std::unique_lock<std::mutex> _ul(m_mtx);
      if (m_sink.get()) {
        m_sink.get()->Success(payload);
      }
    });
  }

  void Error(const std::string& error_code,
             const std::string& error_message,
             const T& error_details) {
    RunOnPlatformThread(
        [this, error_code, error_message, error_details]() {
          std::unique_lock<std::mutex> _ul(m_mtx);
          if (m_sink.get()) {
            m_sink.get()->Error(error_code, error_message, error_details);
          }
        });
  }

 protected:
  std::unique_ptr<StreamHandlerError<T>> OnListenInternal(
      const T* arguments,
      std::unique_ptr<EventSink<T>>&& events) override {
    std::unique_lock<std::mutex> _ul(m_mtx);
    m_sink = std::move(events);
    return nullptr;
  }

  std::unique_ptr<StreamHandlerError<T>> OnCancelInternal(
      const T* arguments) override {
    std::unique_lock<std::mutex> _ul(m_mtx);
    m_sink.release();
    return nullptr;
  }

 private:
  void RunOnPlatformThread(std::function<void()> task) {
    if (GetCurrentThreadId() == platform_thread_id_) {
      task();
      return;
    }

    auto* posted_task = new std::function<void()>(std::move(task));
    if (platform_window_ == nullptr ||
        !PostMessage(platform_window_,
                     kAudioplayersWindowsPlatformThreadMessage, 0,
                     reinterpret_cast<LPARAM>(posted_task))) {
      delete posted_task;
    }
  }

  std::mutex m_mtx;
  std::unique_ptr<EventSink<T>> m_sink;
  HWND platform_window_;
  DWORD platform_thread_id_;
};
