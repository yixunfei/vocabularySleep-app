#include "include/flutter_tts/flutter_tts_plugin.h"
// This must be included before many other Windows headers.
#include <windows.h>
#include <ppltasks.h>
#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <queue>
#include <sstream>
#include <cstdarg>

typedef std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> FlutterResult;
//typedef flutter::MethodResult<flutter::EncodableValue>* PFlutterResult;

std::unique_ptr<flutter::MethodChannel<>> methodChannel;

static void DbgLog(const char* fmt, ...) {
	char buf[1024];
	va_list args;
	va_start(args, fmt);
	vsnprintf(buf, sizeof(buf), fmt, args);
	va_end(args);
	OutputDebugStringA(buf);
}

#if defined(WINAPI_FAMILY) && (WINAPI_FAMILY == WINAPI_FAMILY_DESKTOP_APP)
#include <winrt/Windows.Media.SpeechSynthesis.h>
#include <winrt/Windows.Media.Playback.h>
#include <winrt/Windows.Media.Core.h>
using namespace winrt;
using namespace Windows::Media::SpeechSynthesis;
using namespace Concurrency;
using namespace std::chrono_literals;
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
namespace {
	class FlutterTtsPlugin : public flutter::Plugin {
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
		explicit FlutterTtsPlugin(flutter::PluginRegistrarWindows* registrar);
		virtual ~FlutterTtsPlugin();
	private:
		// Called when a method is called on this plugin's channel from Dart.
		void HandleMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void speak(const std::string, FlutterResult);
		void pause();
		void continuePlay();
		void stop();
		void setVolume(const double);
		void setPitch(const double);
		void setRate(const double);
		void getVoices(flutter::EncodableList&);
		void setVoice(const std::string, const std::string, FlutterResult&);
		void getLanguages(flutter::EncodableList&);
		void setLanguage(const std::string, FlutterResult&);
		void addMplayer();
		winrt::Windows::Foundation::IAsyncAction asyncSpeak(const std::string);
		void PostToPlatformThread(std::function<void()> callback);
		std::optional<LRESULT> HandleWindowMessage(HWND hwnd, UINT message);
		HWND resolveTopLevelWindow() const;
		bool speaking();
		bool paused();
		SpeechSynthesizer synth;
		winrt::Windows::Media::Playback::MediaPlayer mPlayer;
		flutter::PluginRegistrarWindows* registrar_;
		HWND window_handle_;
		int window_proc_delegate_id_;
		std::mutex pending_callbacks_mutex_;
		std::queue<std::function<void()>> pending_callbacks_;
		bool isPaused;
		bool isSpeaking;
		bool awaitSpeakCompletion;
		FlutterResult speakResult;
		static constexpr UINT kDispatchCallbacksMessage = WM_APP + 0x6A31;
	};

	void FlutterTtsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
		methodChannel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "flutter_tts",
				&flutter::StandardMethodCodec::GetInstance());
		auto plugin = std::make_unique<FlutterTtsPlugin>(registrar);
		plugin->window_proc_delegate_id_ =
			registrar->RegisterTopLevelWindowProcDelegate(
				[plugin_pointer = plugin.get()](
					HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam)
					-> std::optional<LRESULT> {
					return plugin_pointer->HandleWindowMessage(hwnd, message);
				});

		methodChannel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
			plugin_pointer->HandleMethodCall(call, std::move(result));
		});
		registrar->AddPlugin(std::move(plugin));
	}

	void FlutterTtsPlugin::addMplayer() {
		mPlayer = winrt::Windows::Media::Playback::MediaPlayer::MediaPlayer();
		auto mEndedToken =
			mPlayer.MediaEnded([this](Windows::Media::Playback::MediaPlayer const& sender,
				Windows::Foundation::IInspectable const& args)
				{
					PostToPlatformThread([this]() {
						methodChannel->InvokeMethod("speak.onComplete", nullptr);
						if (awaitSpeakCompletion && speakResult) {
							speakResult->Success(1);
							speakResult.reset();
						}
						isSpeaking = false;
					});
				});
	}

	bool FlutterTtsPlugin::speaking() {
		try {
			const auto playback_state = mPlayer.PlaybackSession().PlaybackState();
			return playback_state ==
					winrt::Windows::Media::Playback::MediaPlaybackState::Opening ||
				playback_state ==
					winrt::Windows::Media::Playback::MediaPlaybackState::Buffering ||
				playback_state ==
					winrt::Windows::Media::Playback::MediaPlaybackState::Playing;
		}
		catch (...) {
			return isSpeaking && !isPaused;
		}
	}

	bool FlutterTtsPlugin::paused() {
		return isPaused;
	}

	winrt::Windows::Foundation::IAsyncAction FlutterTtsPlugin::asyncSpeak(const std::string text) {
		SpeechSynthesisStream speechStream{
		  co_await synth.SynthesizeTextToStreamAsync(to_hstring(text))
		};
		winrt::param::hstring cType = L"Audio";
		winrt::Windows::Media::Core::MediaSource source =
			winrt::Windows::Media::Core::MediaSource::CreateFromStream(speechStream, cType);
		mPlayer.Source(source);
		mPlayer.Play();
	}

	void FlutterTtsPlugin::speak(const std::string text, FlutterResult result) {
		isSpeaking = true;
		auto my_task{ asyncSpeak(text) };
		methodChannel->InvokeMethod("speak.onStart", NULL);
        if (awaitSpeakCompletion) speakResult = std::move(result);
        else result->Success(1);
	};

	void FlutterTtsPlugin::pause() {
		mPlayer.Pause();
		isPaused = true;
		methodChannel->InvokeMethod("speak.onPause", NULL);
	}

	void FlutterTtsPlugin::continuePlay() {
		mPlayer.Play();
		isPaused = false;
		methodChannel->InvokeMethod("speak.onContinue", NULL);
	}

	void FlutterTtsPlugin::stop() {
	    methodChannel->InvokeMethod("speak.onCancel", NULL);
        if (awaitSpeakCompletion && speakResult) {
            speakResult->Success(1);
			speakResult.reset();
        }

		mPlayer.Close();
		addMplayer();
		isSpeaking = false;
		isPaused = false;
	}
	void FlutterTtsPlugin::setVolume(const double newVolume) { synth.Options().AudioVolume(newVolume); }

	void FlutterTtsPlugin::setPitch(const double newPitch) { synth.Options().AudioPitch(newPitch); }

	void FlutterTtsPlugin::setRate(const double newRate) { synth.Options().SpeakingRate(newRate + 0.5); }

	void FlutterTtsPlugin::getVoices(flutter::EncodableList& voices) {
		auto synthVoices = synth.AllVoices();
		std::for_each(begin(synthVoices), end(synthVoices), [&voices](const VoiceInformation& voice)
			{
				flutter::EncodableMap voiceInfo;
				voiceInfo[flutter::EncodableValue("locale")] = to_string(voice.Language());
				voiceInfo[flutter::EncodableValue("name")] = to_string(voice.DisplayName());
				//  Convert VoiceGender to string
				std::string gender;
				switch (voice.Gender()) {
					case VoiceGender::Male:
						gender = "male";
						break;
					case VoiceGender::Female:
						gender = "female";
						break;
					default:
						gender = "unknown";
						break;
				}
				voiceInfo[flutter::EncodableValue("gender")] = gender; 
				// Identifier example "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens\MSTTS_V110_enUS_MarkM"
				voiceInfo[flutter::EncodableValue("identifier")] = to_string(voice.Id());
				voices.push_back(flutter::EncodableMap(voiceInfo));
			});
	}

	void FlutterTtsPlugin::setVoice(const std::string voiceLanguage, const std::string voiceName, FlutterResult& result) {
		bool found = false;
		auto voices = synth.AllVoices();
		VoiceInformation newVoice = synth.Voice();
		std::for_each(begin(voices), end(voices), [&voiceLanguage, &voiceName, &found, &newVoice](const VoiceInformation& voice)
			{
				if (to_string(voice.Language()) == voiceLanguage && to_string(voice.DisplayName()) == voiceName)
				{
					newVoice = voice;
					found = true;
				}
			});
		synth.Voice(newVoice);
		if (found) result->Success(1);
		else result->Success(0);
	}

	void FlutterTtsPlugin::getLanguages(flutter::EncodableList& languages) {
		auto synthVoices = synth.AllVoices();
		std::set<flutter::EncodableValue> languagesSet = {};
		std::for_each(begin(synthVoices), end(synthVoices), [&languagesSet](const VoiceInformation& voice)
			{
				languagesSet.insert(flutter::EncodableValue(to_string(voice.Language())));
			});
		std::for_each(begin(languagesSet), end(languagesSet), [&languages](const flutter::EncodableValue value)
			{
				languages.push_back(value);
			});
	}
	void FlutterTtsPlugin::setLanguage(const std::string voiceLanguage, FlutterResult& result) {
		bool found = false;
		auto voices = synth.AllVoices();
		VoiceInformation newVoice = synth.Voice();
		std::for_each(begin(voices), end(voices), [&voiceLanguage, &newVoice, &found](const VoiceInformation& voice)
			{
				if (to_string(voice.Language()) == voiceLanguage) newVoice = voice;
				found = true;
			});
		synth.Voice(newVoice);
		if (found) result->Success(1);
		else result->Success(0);
	}

	HWND FlutterTtsPlugin::resolveTopLevelWindow() const {
		if (window_handle_ != nullptr) {
			return window_handle_;
		}
		if (registrar_ == nullptr || registrar_->GetView() == nullptr) {
			return nullptr;
		}
		const HWND native_window = registrar_->GetView()->GetNativeWindow();
		if (native_window == nullptr) {
			return nullptr;
		}
		const HWND root = GetAncestor(native_window, GA_ROOT);
		return root != nullptr ? root : native_window;
	}


	FlutterTtsPlugin::FlutterTtsPlugin(
		flutter::PluginRegistrarWindows* registrar)
		: registrar_(registrar),
		  window_handle_(nullptr),
		  window_proc_delegate_id_(-1) {
		synth = SpeechSynthesizer();
		addMplayer();
		isPaused = false;
		isSpeaking = false;
		awaitSpeakCompletion = false;
		speakResult = FlutterResult();
		window_handle_ = resolveTopLevelWindow();
	}

	FlutterTtsPlugin::~FlutterTtsPlugin() {
		if (registrar_ != nullptr && window_proc_delegate_id_ >= 0) {
			registrar_->UnregisterTopLevelWindowProcDelegate(
				window_proc_delegate_id_);
		}
		mPlayer.Close();
	}

	void FlutterTtsPlugin::PostToPlatformThread(
		std::function<void()> callback) {
		const HWND target_window = resolveTopLevelWindow();
		if (target_window == nullptr) {
			callback();
			return;
		}
		{
			std::lock_guard<std::mutex> lock(pending_callbacks_mutex_);
			pending_callbacks_.push(std::move(callback));
		}
		window_handle_ = target_window;
		PostMessage(target_window, kDispatchCallbacksMessage, 0, 0);
	}

	std::optional<LRESULT> FlutterTtsPlugin::HandleWindowMessage(
		HWND hwnd, UINT message) {
		if (hwnd != nullptr) {
			window_handle_ = hwnd;
		}
		if (message != kDispatchCallbacksMessage) {
			return std::nullopt;
		}
		std::queue<std::function<void()>> pending_callbacks;
		{
			std::lock_guard<std::mutex> lock(pending_callbacks_mutex_);
			pending_callbacks.swap(pending_callbacks_);
		}
		while (!pending_callbacks.empty()) {
			pending_callbacks.front()();
			pending_callbacks.pop();
		}
		return 0;
	}

	void FlutterTtsPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		FlutterResult result) {
		if (method_call.method_name().compare("getPlatformVersion") == 0) {
			std::ostringstream version_stream;
			version_stream << "Windows UWP";
			result->Success(flutter::EncodableValue(version_stream.str()));
		}

#else
#include <string>
#include <atlstr.h>
#include <array>
#include <sapi.h>
#pragma warning(disable:4996)
#include <sphelper.h>
#pragma warning(default: 4996)
namespace {

	// SAPI path — uses ISpVoice::SetNotifyWindowMessage() so that the
	// SPEI_END_INPUT_STREAM event is delivered directly as a Windows
	// message on the platform/UI thread.  No thread-pool threads, no
	// RegisterWaitForSingleObject, no COM threading issues.
	class FlutterTtsPlugin : public flutter::Plugin {
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
		explicit FlutterTtsPlugin(flutter::PluginRegistrarWindows* registrar);
		virtual ~FlutterTtsPlugin();
	private:
		// Called when a method is called on this plugin's channel from Dart.
		void HandleMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

		void speak(const std::string, FlutterResult);
		void pause();
		void continuePlay();
		void stop();
		void setVolume(const double);
		void setPitch(const double);
		void setRate(const double);
		void getVoices(flutter::EncodableList&);
		void setVoice(const std::string, const std::string, FlutterResult&);
		void getLanguages(flutter::EncodableList&);
		void setLanguage(const std::string, FlutterResult&);
		std::optional<LRESULT> HandleWindowMessage(HWND hwnd, UINT message);
		void drainSapiEvents();
		void ensureSapiNotifyBound(HWND hwnd);
		HWND resolveTopLevelWindow() const;

		flutter::PluginRegistrarWindows* registrar_;
		int window_proc_delegate_id_;

		// The top-level HWND captured from the first HandleWindowMessage call.
		// At plugin construction time the Flutter view child HWND has not yet
		// been parented, so GetAncestor() cannot find the top-level window.
		// We lazily bind SAPI notifications on the first message we receive.
		HWND top_level_hwnd_;
		bool sapi_notify_bound_;

		// Custom Windows message sent by SAPI when a speech event fires.
		static constexpr UINT kSapiNotifyMessage = WM_APP + 0x6A33;

		ISpVoice* pVoice;
		bool awaitSpeakCompletion = false;
		bool isPaused;
		bool isSpeaking;
		double pitch;
		bool speaking();
		bool paused();
		FlutterResult speakResult;
	};

	void FlutterTtsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
		methodChannel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "flutter_tts",
				&flutter::StandardMethodCodec::GetInstance());
		auto plugin = std::make_unique<FlutterTtsPlugin>(registrar);
		plugin->window_proc_delegate_id_ =
			registrar->RegisterTopLevelWindowProcDelegate(
				[plugin_pointer = plugin.get()](
					HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam)
					-> std::optional<LRESULT> {
					return plugin_pointer->HandleWindowMessage(hwnd, message);
				});
		methodChannel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
			plugin_pointer->HandleMethodCall(call, std::move(result));
		});

		registrar->AddPlugin(std::move(plugin));
	}

	FlutterTtsPlugin::FlutterTtsPlugin(
		flutter::PluginRegistrarWindows* registrar)
		: registrar_(registrar),
		  window_proc_delegate_id_(-1),
		  top_level_hwnd_(nullptr),
		  sapi_notify_bound_(false) {
		DbgLog("[flutter_tts] CONSTRUCTOR: begin\n");
		isPaused = false;
		isSpeaking = false;
		speakResult = NULL;
		pVoice = NULL;
		HRESULT hr;
		hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
		if (FAILED(hr))
		{
			DbgLog("[flutter_tts] CONSTRUCTOR: CoInitializeEx FAILED hr=0x%08lX\n", hr);
			throw std::exception("TTS init failed");
		}
		DbgLog("[flutter_tts] CONSTRUCTOR: CoInitializeEx OK\n");

		hr = CoCreateInstance(CLSID_SpVoice, NULL, CLSCTX_ALL, IID_ISpVoice, (void**)&pVoice);
		if (FAILED(hr))
		{
			DbgLog("[flutter_tts] CONSTRUCTOR: CoCreateInstance FAILED hr=0x%08lX\n", hr);
			throw std::exception("TTS create instance failed");
		}
		DbgLog("[flutter_tts] CONSTRUCTOR: ISpVoice created OK pVoice=%p\n", pVoice);
		pitch = 0;

		// We only care about end-of-stream events.
		hr = pVoice->SetInterest(SPFEI(SPEI_END_INPUT_STREAM), SPFEI(SPEI_END_INPUT_STREAM));
		DbgLog("[flutter_tts] CONSTRUCTOR: SetInterest hr=0x%08lX\n", hr);

		// NOTE: We do NOT call SetNotifyWindowMessage here.
		// At construction time the Flutter view HWND has not been parented
		// to the top-level window yet, so GetAncestor(child, GA_ROOT) returns
		// the child itself — the wrong HWND.  Instead, we lazily bind on the
		// first HandleWindowMessage call (which gives us the real top-level HWND).
		DbgLog("[flutter_tts] CONSTRUCTOR: done (SAPI notify will be bound lazily)\n");
	}

	FlutterTtsPlugin::~FlutterTtsPlugin() {
		if (pVoice != nullptr) {
			pVoice->SetNotifyWindowMessage(NULL, 0, 0, 0);
			pVoice->Release();
			pVoice = nullptr;
		}
		if (registrar_ != nullptr && window_proc_delegate_id_ >= 0) {
			registrar_->UnregisterTopLevelWindowProcDelegate(
				window_proc_delegate_id_);
		}
		::CoUninitialize();
	}

	void FlutterTtsPlugin::ensureSapiNotifyBound(HWND hwnd) {
		if (sapi_notify_bound_) return;
		if (hwnd == nullptr || pVoice == nullptr) {
			DbgLog("[flutter_tts] ensureSapiNotifyBound: SKIP hwnd=%p pVoice=%p\n", hwnd, pVoice);
			return;
		}
		top_level_hwnd_ = hwnd;
		HRESULT hr = pVoice->SetNotifyWindowMessage(
			top_level_hwnd_, kSapiNotifyMessage, 0, 0);
		sapi_notify_bound_ = true;
		DbgLog("[flutter_tts] ensureSapiNotifyBound: BOUND hwnd=%p msg=0x%X hr=0x%08lX\n",
			top_level_hwnd_, kSapiNotifyMessage, hr);
	}

	HWND FlutterTtsPlugin::resolveTopLevelWindow() const {
		if (top_level_hwnd_ != nullptr) {
			return top_level_hwnd_;
		}
		if (registrar_ == nullptr || registrar_->GetView() == nullptr) {
			return nullptr;
		}
		const HWND native_window = registrar_->GetView()->GetNativeWindow();
		if (native_window == nullptr) {
			return nullptr;
		}
		const HWND root = GetAncestor(native_window, GA_ROOT);
		return root != nullptr ? root : native_window;
	}

	std::optional<LRESULT> FlutterTtsPlugin::HandleWindowMessage(
		HWND hwnd, UINT message) {
		// Lazily bind SAPI notifications to the first HWND we see.
		// This is the top-level HWND from FlutterWindow::MessageHandler,
		// which is exactly where RegisterTopLevelWindowProcDelegate fires.
		ensureSapiNotifyBound(hwnd);

		if (message == kSapiNotifyMessage) {
			DbgLog("[flutter_tts] HandleWindowMessage: GOT kSapiNotifyMessage hwnd=%p\n", hwnd);
			// SAPI sent us a notification — drain and process events.
			drainSapiEvents();
			return 0;
		}
		return std::nullopt;
	}

	void FlutterTtsPlugin::drainSapiEvents() {
		if (pVoice == nullptr) {
			DbgLog("[flutter_tts] drainSapiEvents: pVoice is NULL, skip\n");
			return;
		}
		SPEVENT event;
		memset(&event, 0, sizeof(event));
		int eventCount = 0;
		while (pVoice->GetEvents(1, &event, NULL) == S_OK) {
			eventCount++;
			DbgLog("[flutter_tts] drainSapiEvents: event #%d eEventId=%lu\n", eventCount, (unsigned long)event.eEventId);
			if (event.eEventId == SPEI_END_INPUT_STREAM) {
				DbgLog("[flutter_tts] drainSapiEvents: GOT SPEI_END_INPUT_STREAM! Firing speak.onComplete\n");
				isSpeaking = false;
				methodChannel->InvokeMethod("speak.onComplete", NULL);
				if (awaitSpeakCompletion && speakResult) {
					speakResult->Success(1);
					speakResult.reset();
				}
			}
			memset(&event, 0, sizeof(event));
		}
		if (eventCount == 0) {
			DbgLog("[flutter_tts] drainSapiEvents: no events in queue\n");
		}
	}

	bool FlutterTtsPlugin::speaking()
	{
		// Query SAPI engine directly for real-time status instead of
		// relying on the isSpeaking flag (which depends on callbacks).
		SPVOICESTATUS status;
		memset(&status, 0, sizeof(status));
		HRESULT hr = pVoice->GetStatus(&status, NULL);
		bool result;
		if (SUCCEEDED(hr)) {
			result = status.dwRunningState == SPRS_IS_SPEAKING;
		} else {
			result = isSpeaking;
		}
		DbgLog("[flutter_tts] speaking(): hr=0x%08lX dwRunningState=%lu isSpeaking=%d result=%d\n",
			hr, SUCCEEDED(hr) ? status.dwRunningState : 0, isSpeaking ? 1 : 0, result ? 1 : 0);
		return result;
	}
	bool FlutterTtsPlugin::paused() { return isPaused; }


	void FlutterTtsPlugin::speak(const std::string text, FlutterResult result) {
		DbgLog("[flutter_tts] speak(): begin text='%.60s' isSpeaking=%d isPaused=%d sapi_notify_bound=%d hwnd=%p\n",
			text.c_str(), isSpeaking ? 1 : 0, isPaused ? 1 : 0, sapi_notify_bound_ ? 1 : 0, top_level_hwnd_);

		// Ensure SAPI completion notifications are bound before the utterance
		// starts so the very first playback unit can still deliver onComplete.
		ensureSapiNotifyBound(resolveTopLevelWindow());

		// Stop any in-flight speech first.
		if (isSpeaking) {
			DbgLog("[flutter_tts] speak(): stopping in-flight speech\n");
			stop();
		}

		HRESULT hr;
		const std::string arg = "<PITCH MIDDLE = '" + std::to_string(int((pitch - 1) * 10 * (1 + (pitch < 1)) )) + "'/>" + text;

		int wchars_num = MultiByteToWideChar(CP_UTF8, 0, arg.c_str(), -1, NULL, 0);
		wchar_t* wstr = new wchar_t[wchars_num];
		MultiByteToWideChar(CP_UTF8, 0, arg.c_str(), -1, wstr, wchars_num);

		// SPF_ASYNC (1) | SPF_PURGEBEFORESPEAK (2) = 3
		// Purge ensures any leftover speech is cleared and we get a clean
		// SPEI_END_INPUT_STREAM for this new utterance.
		hr = pVoice->Speak(wstr, SPF_ASYNC | SPF_PURGEBEFORESPEAK, NULL);
		delete[] wstr;

		DbgLog("[flutter_tts] speak(): Speak() hr=0x%08lX\n", hr);

		if (FAILED(hr)) {
			DbgLog("[flutter_tts] speak(): Speak FAILED, returning error\n");
			isSpeaking = false;
			result->Success(0);
			return;
		}

		isSpeaking = true;
		DbgLog("[flutter_tts] speak(): firing speak.onStart\n");
		methodChannel->InvokeMethod("speak.onStart", NULL);

		if (awaitSpeakCompletion){
		    speakResult = std::move(result);
			DbgLog("[flutter_tts] speak(): awaitSpeakCompletion=true, result deferred\n");
		}
		else {
			result->Success(1);
			DbgLog("[flutter_tts] speak(): awaitSpeakCompletion=false, result->Success(1)\n");
		}
	}
	void FlutterTtsPlugin::pause()
	{
		if (isPaused == false)
		{
			pVoice->Pause();
			isPaused = true;
		}
	    methodChannel->InvokeMethod("speak.onPause", NULL);
	}
	void FlutterTtsPlugin::continuePlay()
	{
		isPaused = false;
		pVoice->Resume();
	    methodChannel->InvokeMethod("speak.onContinue", NULL);
	}
	void FlutterTtsPlugin::stop()
	{
		DbgLog("[flutter_tts] stop(): begin isSpeaking=%d isPaused=%d\n", isSpeaking ? 1 : 0, isPaused ? 1 : 0);
		// Purge all queued/active speech.  SPF_PURGEBEFORESPEAK with empty
		// string stops immediately and will *not* fire SPEI_END_INPUT_STREAM.
		HRESULT hr = pVoice->Speak(L"", SPF_ASYNC | SPF_PURGEBEFORESPEAK, NULL);
		DbgLog("[flutter_tts] stop(): purge Speak hr=0x%08lX\n", hr);
		pVoice->Resume();
		isPaused = false;
		isSpeaking = false;
	    methodChannel->InvokeMethod("speak.onCancel", NULL);
	    if (awaitSpeakCompletion && speakResult) {
	        speakResult->Success(1);
	        speakResult.reset();
	    }
		DbgLog("[flutter_tts] stop(): done\n");
	}
	void FlutterTtsPlugin::setVolume(const double newVolume)
	{
		const USHORT volume = (short)(100 * newVolume);
		pVoice->SetVolume(volume);
	}
	void FlutterTtsPlugin::setPitch(const double newPitch) {pitch = newPitch;}
	void FlutterTtsPlugin::setRate(const double newRate)
	{
		const long speechRate = (long)((newRate - 0.5) * 15);
		pVoice->SetRate(speechRate);
	}
	void FlutterTtsPlugin::getVoices(flutter::EncodableList& voices) {
		HRESULT hr;
		IEnumSpObjectTokens* cpEnum = NULL;
		hr = SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum);
		if (FAILED(hr)) return;

 		ULONG ulCount = 0;
		// Get the number of voices.
		hr = cpEnum->GetCount(&ulCount);
		if (FAILED(hr)) return;
		ISpObjectToken* cpVoiceToken = NULL;
		while (ulCount--)
		{
			cpVoiceToken = NULL;
			hr = cpEnum->Next(1, &cpVoiceToken, NULL);
			if (FAILED(hr)) return;
			CComPtr<ISpDataKey> cpAttribKey;
			hr = cpVoiceToken->OpenKey(L"Attributes", &cpAttribKey);
			if (FAILED(hr)) return;
			WCHAR* psz = NULL;
			hr = cpAttribKey->GetStringValue(L"Language", &psz);
		    wchar_t locale[25];
            LCIDToLocaleName((LCID)std::strtol(CW2A(psz), NULL, 16), locale, 25, 0);
            ::CoTaskMemFree(psz);
            std::string language = CW2A(locale);
            psz = NULL;
            cpAttribKey->GetStringValue(L"Name", &psz);
			std::string name = CW2A(psz);
			::CoTaskMemFree(psz);
            flutter::EncodableMap voiceInfo;
            voiceInfo[flutter::EncodableValue("locale")] = language;
            voiceInfo[flutter::EncodableValue("name")] = name;
            voices.push_back(flutter::EncodableMap(voiceInfo));
			cpVoiceToken->Release();
		}
	}
	void FlutterTtsPlugin::setVoice(const std::string voiceLanguage, const std::string voiceName, FlutterResult& result) {
		HRESULT hr;
		IEnumSpObjectTokens* cpEnum = NULL;
		hr = SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum);
		if (FAILED(hr)) { result->Success(0); return; }
		ULONG ulCount = 0;
		hr = cpEnum->GetCount(&ulCount);
		if (FAILED(hr)) { result->Success(0); return; }
		ISpObjectToken* cpVoiceToken = NULL;
		bool success = false;
		while (ulCount--)
		{
			cpVoiceToken = NULL;
			hr = cpEnum->Next(1, &cpVoiceToken, NULL);
			if (FAILED(hr)) { result->Success(0); return; }
			CComPtr<ISpDataKey> cpAttribKey;
			hr = cpVoiceToken->OpenKey(L"Attributes", &cpAttribKey);
			if (FAILED(hr)) { result->Success(0); return; }
			WCHAR* psz = NULL;
			hr = cpAttribKey->GetStringValue(L"Name", &psz);
			if (FAILED(hr)) { result->Success(0); return; }
			std::string name = CW2A(psz);
			::CoTaskMemFree(psz);
			psz = NULL;
			hr = cpAttribKey->GetStringValue(L"Language", &psz);
		    wchar_t locale[25];
            LCIDToLocaleName((LCID)std::strtol(CW2A(psz), NULL, 16), locale, 25, 0);
            ::CoTaskMemFree(psz);
            std::string language = CW2A(locale);
			if (name == voiceName && language == voiceLanguage)
			{
				pVoice->SetVoice(cpVoiceToken);
				success = true;
			}
			cpVoiceToken->Release();
		}
		result->Success(success ? 1 : 0);
	}
	void FlutterTtsPlugin::getLanguages(flutter::EncodableList& languages)
	{
		HRESULT hr;
		IEnumSpObjectTokens* cpEnum = NULL;
		hr = SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum);
		if (FAILED(hr)) return;

 		ULONG ulCount = 0;
		// Get the number of voices.
		hr = cpEnum->GetCount(&ulCount);
		if (FAILED(hr)) return;
		ISpObjectToken* cpVoiceToken = NULL;
        std::set<flutter::EncodableValue> languagesSet = {};
		while (ulCount--)
		{
			cpVoiceToken = NULL;
			hr = cpEnum->Next(1, &cpVoiceToken, NULL);
			if (FAILED(hr)) return;
			CComPtr<ISpDataKey> cpAttribKey;
			hr = cpVoiceToken->OpenKey(L"Attributes", &cpAttribKey);
			if (FAILED(hr)) return;

			WCHAR* psz = NULL;
			hr = cpAttribKey->GetStringValue(L"Language", &psz);
		    wchar_t locale[25];
            LCIDToLocaleName((LCID)std::strtol(CW2A(psz), NULL, 16), locale, 25, 0);
            std::string language = CW2A(locale);
			languagesSet.insert(flutter::EncodableValue(language));
			::CoTaskMemFree(psz);
			cpVoiceToken->Release();
		}
        std::for_each(begin(languagesSet), end(languagesSet), [&languages](const flutter::EncodableValue value)
            {
                languages.push_back(value);
            });
	}

	void FlutterTtsPlugin::setLanguage(const std::string voiceLanguage, FlutterResult& result) {
		HRESULT hr;
		IEnumSpObjectTokens* cpEnum = NULL;
		hr = SpEnumTokens(SPCAT_VOICES, NULL, NULL, &cpEnum);
		if (FAILED(hr)) { result->Success(0); return; }
		ULONG ulCount = 0;
		hr = cpEnum->GetCount(&ulCount);
		if (FAILED(hr)) { result->Success(0); return; }
		ISpObjectToken* cpVoiceToken = NULL;
		bool found = false;
		while (ulCount--)
		{
			cpVoiceToken = NULL;
			hr = cpEnum->Next(1, &cpVoiceToken, NULL);
			if (FAILED(hr)) { result->Success(0); return; }
			CComPtr<ISpDataKey> cpAttribKey;
			hr = cpVoiceToken->OpenKey(L"Attributes", &cpAttribKey);
			if (FAILED(hr)) { result->Success(0); return; }

			WCHAR* psz = NULL;
			hr = cpAttribKey->GetStringValue(L"Language", &psz);
		    wchar_t locale[25];
            LCIDToLocaleName((LCID)std::strtol(CW2A(psz), NULL, 16), locale, 25, 0);
            std::string language = CW2A(locale);
			if (language == voiceLanguage)
			{
				pVoice->SetVoice(cpVoiceToken);
				found = true;
			}
			::CoTaskMemFree(psz);
			cpVoiceToken->Release();
		}
		if (found) result->Success(1);
		else result->Success(0);
	}


	void FlutterTtsPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		FlutterResult result) {

		if (method_call.method_name().compare("getPlatformVersion") == 0) {
			std::ostringstream version_stream;
			version_stream << "Windows ";
			if (IsWindows10OrGreater()) {
				version_stream << "10+";
			}
			else if (IsWindows8OrGreater()) {
				version_stream << "8";
			}
			else if (IsWindows7OrGreater()) {
				version_stream << "7";
			}
			result->Success(flutter::EncodableValue(version_stream.str()));
		}
#endif
		else if (method_call.method_name().compare("awaitSpeakCompletion") == 0) {
            const flutter::EncodableValue arg = method_call.arguments()[0];
            if (std::holds_alternative<bool>(arg)) {
                awaitSpeakCompletion = std::get<bool>(arg);
                result->Success(1);
            }
            else result->Success(0);
        }
		else if (method_call.method_name().compare("speak") == 0) {
			if (isPaused) {
				DbgLog("[flutter_tts] HandleMethodCall(speak): isPaused=true, stopping first then speaking new text\n");
				stop();
			}
			const flutter::EncodableValue arg = method_call.arguments()[0];
			if (std::holds_alternative<std::string>(arg)) {
				const std::string text = std::get<std::string>(arg);
				DbgLog("[flutter_tts] HandleMethodCall(speak): text='%.60s'\n", text.c_str());
				speak(text, std::move(result));
			}
			else {
				DbgLog("[flutter_tts] HandleMethodCall(speak): arg is not string\n");
				result->Success(0);
			}
		}
		else if (method_call.method_name().compare("isSpeaking") == 0) {
			result->Success(flutter::EncodableValue(speaking()));
		}
		else if (method_call.method_name().compare("pause") == 0) {
			FlutterTtsPlugin::pause();
			result->Success(1);
		}
		else if (method_call.method_name().compare("setLanguage") == 0) {
			const flutter::EncodableValue arg = method_call.arguments()[0];
			if (std::holds_alternative<std::string>(arg)) {
				const std::string lang = std::get<std::string>(arg);
				setLanguage(lang, result);
			}
			else result->Success(0);
		}
		else if (method_call.method_name().compare("setVolume") == 0) {
			const flutter::EncodableValue arg = method_call.arguments()[0];
			if (std::holds_alternative<double>(arg)) {
				const double newVolume = std::get<double>(arg);
				setVolume(newVolume);
				result->Success(1);
			}
			else result->Success(0);

		}
		else if (method_call.method_name().compare("setSpeechRate") == 0) {
			const flutter::EncodableValue arg = method_call.arguments()[0];
			if (std::holds_alternative<double>(arg)) {
				const double newRate = std::get<double>(arg);
				setRate(newRate);
				result->Success(1);
			}
			else result->Success(0);

		}
        else if (method_call.method_name().compare("setPitch") == 0) {
            const flutter::EncodableValue arg = method_call.arguments()[0];
            if (std::holds_alternative<double>(arg)) {
                const double newPitch = std::get<double>(arg);
                setPitch(newPitch);
                result->Success(1);
            }
            else result->Success(0);
        }
		else if (method_call.method_name().compare("setVoice") == 0) {
			const flutter::EncodableValue arg = method_call.arguments()[0];
			if (std::holds_alternative<flutter::EncodableMap>(arg)) {
				const flutter::EncodableMap voiceInfo = std::get<flutter::EncodableMap>(arg);
				std::string voiceLanguage = "";
				std::string voiceName = "";
				auto voiceLanguage_it = voiceInfo.find(flutter::EncodableValue("locale"));
				if (voiceLanguage_it != voiceInfo.end()) voiceLanguage = std::get<std::string>(voiceLanguage_it->second);
				auto voiceName_it = voiceInfo.find(flutter::EncodableValue("name"));
				if (voiceName_it != voiceInfo.end()) voiceName = std::get<std::string>(voiceName_it->second);
				setVoice(voiceLanguage, voiceName, result);
			}
			else result->Success(0);
		}
		else if (method_call.method_name().compare("stop") == 0) {
			stop();
			result->Success(1);
		}
		else if (method_call.method_name().compare("getLanguages") == 0) {
			flutter::EncodableList l;
			getLanguages(l);
			result->Success(l);
		}
		else if (method_call.method_name().compare("getVoices") == 0) {
			flutter::EncodableList l;
			getVoices(l);
			result->Success(l);
		}
		else {
			result->NotImplemented();
		}
	}
}

void FlutterTtsPluginRegisterWithRegistrar(
	FlutterDesktopPluginRegistrarRef registrar) {
	FlutterTtsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
