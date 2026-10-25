import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- معرّف التطبيق الخاص بك في Agora ---
const String AGORA_APP_ID = "2a0053e48b774c279c834793732a7493";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SafePulseApp());
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Go P2P',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF1DE9B6),
          error: Color(0xFFFF5252),
          surface: Color(0xFF131B2E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// -------------------------------------------------------------
// الشاشة الرئيسية
// -------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _isVideo = true;
  bool _showTokenField = false;

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('saved_agora_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setState(() {
        _tokenController.text = savedToken;
        _showTokenField = true;
      });
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_agora_token', token.trim());
  }

  String _generateTempCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _startCall(String channelCode) async {
    final code = channelCode.trim();
    if (code.length < 3) {
      _showSnackbar("يرجى إدخال رمز اتصال صالح (3 خانات على الأقل)", Colors.redAccent);
      return;
    }

    HapticFeedback.heavyImpact();
    await _saveToken(_tokenController.text);

    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      if (_isVideo) Permission.camera,
    ].request();

    bool micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    bool camGranted = !_isVideo || (statuses[Permission.camera]?.isGranted ?? false);

    if (micGranted && camGranted) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: code,
            token: _tokenController.text.trim(),
            isVideoCall: _isVideo,
          ),
        ),
      );
    } else {
      _showSnackbar("يجب منح صلاحيات الصوت والكاميرا للمتابعة", Colors.redAccent);
    }
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.35), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined, size: 55, color: Color(0xFF00E5FF)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Call Go P2P",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              const Text(
                "اتصال فوري ومؤمن لشخصين فقط",
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 30),

              // اختيار نوع المكالمة (فيديو أو صوت)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isVideo = true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isVideo ? const Color(0xFF00E5FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_rounded, color: _isVideo ? Colors.black : Colors.white60, size: 20),
                              const SizedBox(width: 8),
                              Text("مكالمة فيديو", style: TextStyle(fontWeight: FontWeight.bold, color: _isVideo ? Colors.black : Colors.white60)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isVideo = false);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isVideo ? const Color(0xFF00E5FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_rounded, color: !_isVideo ? Colors.black : Colors.white60, size: 20),
                              const SizedBox(width: 8),
                              Text("مكالمة صوت", style: TextStyle(fontWeight: FontWeight.bold, color: !_isVideo ? Colors.black : Colors.white60)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // زر توليد كود جديد للمتصل
              ElevatedButton.icon(
                onPressed: () {
                  final newCode = _generateTempCode();
                  _codeController.text = newCode;
                  _startCall(newCode);
                },
                icon: const Icon(Icons.bolt_rounded, color: Colors.black),
                label: const Text("توليد كود وبدء اتصال جديد", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("أو الانضمام بكود الغرفة", style: TextStyle(color: Colors.white38, fontSize: 13))),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 20),

              // حقل إدخال الكود
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "أدخل الكود (مثال: 458920)",
                  hintStyle: const TextStyle(fontSize: 14, letterSpacing: 0, color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF131B2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // زر الانضمام بكود
              OutlinedButton.icon(
                onPressed: () => _startCall(_codeController.text),
                icon: const Icon(Icons.login_rounded, color: Color(0xFF00E5FF)),
                label: const Text("الانضمام للغرفة", style: TextStyle(fontSize: 16, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),

              // قسم التوكن (لحالات مشاريع App Certificate)
              TextButton.icon(
                onPressed: () => setState(() => _showTokenField = !_showTokenField),
                icon: Icon(_showTokenField ? Icons.keyboard_arrow_up : Icons.security, size: 16, color: Colors.white38),
                label: Text(
                  _showTokenField ? "إخفاء حقل Token" : "إعدادات الأمان المتقدمة (Agora Token)",
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
              if (_showTokenField)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _tokenController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: "الصق هنا الـ Token المشفر (إذا كان مشروعك يتطلب توكن)",
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF131B2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// شاشة المكالمة: صوت/فيديو مع دعم الجودة التكيفية ومؤثرات الرنين
// -------------------------------------------------------------
class CallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.token,
    required this.isVideoCall,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _isSpeaker = true;
  String _statusMessage = "جاري الاتصال بخوادم Agora...";
  String? _errorMessage;
  QualityType _networkQuality = QualityType.qualityUnknown;

  Timer? _callTimer;
  int _secondsElapsed = 0;
  late AnimationController _pulseController;
  Timer? _ringToneHapticTimer;

  @override
  void initState() {
    super.initState();
    _isVideoDisabled = !widget.isVideoCall;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startRingtoneHaptic();
    _initAgora();
  }

  void _startRingtoneHaptic() {
    _ringToneHapticTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_remoteUid == null) {
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: AGORA_APP_ID,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            setState(() {
              _localUserJoined = true;
              _statusMessage = "تم الانضمام للغرفة! بانتظار الطرف الآخر...";
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            // أمان الغرفة: شخصان فقط (إذا دخل طرف ثالث يخرج تلقائياً)
            if (_remoteUid != null) {
              _leaveCall(notice: "الغرفة محجوزة لشخصين فقط!");
              return;
            }

            HapticFeedback.vibrate();
            if (!mounted) return;
            setState(() {
              _remoteUid = remoteUid;
              _statusMessage = "تم الاتصال بنجاح";
            });
            _startTimer();
            _ringToneHapticTimer?.cancel();
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _leaveCall(notice: "انتهت المكالمة من الطرف الآخر");
          },
          onNetworkQuality: (RtcConnection connection, int uid, QualityType txQuality, QualityType rxQuality) {
            if (uid == 0 || uid == _remoteUid) {
              if (mounted) setState(() => _networkQuality = rxQuality);
            }
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            if (state == ConnectionStateType.connectionStateFailed) {
              if (mounted) {
                setState(() {
                  _errorMessage = "فشل الاتصال ($reason). تأكد من صحة التوكن أو إعدادات المشروع!";
                });
              }
            }
          },
          onError: (ErrorCodeType err, String msg) {
            if (err == ErrorCodeType.errInvalidToken || err == ErrorCodeType.errTokenExpired) {
              if (mounted) {
                setState(() {
                  _errorMessage = "مشروعك يتطلب Token! يرجى إدخال التوكن في الشاشة الرئيسية أو تعطيل App Certificate في Agora.";
                });
              }
            }
          },
        ),
      );

      // تفعيل الصوت وضبط السماعة الخارجية افتراضياً
      await _engine.enableAudio();
      await _engine.setEnableSpeakerphone(_isSpeaker);

      // تفعيل الكاميرا وإعدادات الجودة التكيفية لمنع انقطاع المكالمة
      if (widget.isVideoCall) {
        await _engine.enableVideo();
        await _engine.startPreview();

        await _engine.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 360),
            frameRate: 15,
            bitrate: 0,
            degradationPreference: DegradationPreference.maintainBalanced,
          ),
        );

        // إذا انخفضت سرعة الإنترنت جداً يتم التحول تلقائياً للصوت فقط لحماية الاتصال من الانقطاع
        await _engine.setRemoteSubscribeFallbackOption(
          StreamFallbackOptions.streamFallbackOptionAudioOnly,
        );
      }

      // الانضمام ونشر مسارات الصوت والكاميرا صراحةً
      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channelId,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: widget.isVideoCall,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: widget.isVideoCall,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "حدث خطأ أثناء الاتصال: $e";
        });
      }
    }
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _leaveCall({String? notice}) async {
    HapticFeedback.heavyImpact();
    _callTimer?.cancel();
    _ringToneHapticTimer?.cancel();

    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (_) {}

    if (!mounted) return;
    if (notice != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
    }
    Navigator.pop(context);
  }

  Widget _buildNetworkBadge() {
    Color color = Colors.greenAccent;
    String text = "شبكة ممتازة";

    if (_networkQuality == QualityType.qualityPoor || _networkQuality == QualityType.qualityBad) {
      color = Colors.orangeAccent;
      text = "الشبكة ضعيفة";
    } else if (_networkQuality == QualityType.qualityVbad || _networkQuality == QualityType.qualityDown) {
      color = Colors.redAccent;
      text = "جودة منخفضة (حماية الاتصال)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _ringToneHapticTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // مساحة عرض الطرف البعيد أو شاشة الانتظار
            Center(child: _buildRemoteView()),

            // الكاميرا المحلية للمتصل (نافذة مصغرة)
            if (widget.isVideoCall && !_isVideoDisabled && _localUserJoined)
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  width: 105,
                  height: 155,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),

            // شريط المعلومات العلوي
            Positioned(
              top: 50,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "غرفة: ${widget.channelId}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), fontSize: 14),
                        ),
                        if (_remoteUid != null)
                          Text(
                            _formatDuration(_secondsElapsed),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_remoteUid != null) _buildNetworkBadge(),
                ],
              ),
            ),

            // شريط كشف الأخطاء التنبيهي إن وُجد
            if (_errorMessage != null)
              Positioned(
                top: 130,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // شريط أزرار التحكم
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildControlsBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteView() {
    if (_remoteUid != null) {
      if (widget.isVideoCall) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.channelId),
          ),
        );
      } else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF131B2E),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.person, size: 70, color: Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 20),
            const Text(
              "مكالمة صوتية مشفرة",
              style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }
    } else {
      // شاشة انتظار الطرف الآخر مع حركة نبضية
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.15).animate(
              CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.12),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.ring_volume_rounded, size: 55, color: Color(0xFF00E5FF)),
            ),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "شارك الرمز: ${widget.channelId}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), letterSpacing: 2),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildControlsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // كتم الميكروفون
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
            color: _isMuted ? Colors.redAccent : Colors.white,
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isMuted = !_isMuted);
              _engine.muteLocalAudioStream(_isMuted);
            },
          ),

          // تشغيل/إيقاف الكاميرا
          if (widget.isVideoCall)
            IconButton(
              icon: Icon(_isVideoDisabled ? Icons.videocam_off_rounded : Icons.videocam_rounded),
              color: _isVideoDisabled ? Colors.redAccent : Colors.white,
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isVideoDisabled = !_isVideoDisabled);
                _engine.muteLocalVideoStream(_isVideoDisabled);
              },
            ),

          // تبديل الكاميرا (أمامية / خلفية)
          if (widget.isVideoCall && !_isVideoDisabled)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
              onPressed: () {
                HapticFeedback.selectionClick();
                _engine.switchCamera();
              },
            ),

          // التبديل بين سماعة الأذن ومكبر الصوت
          IconButton(
            icon: Icon(_isSpeaker ? Icons.volume_up_rounded : Icons.phone_in_talk_rounded),
            color: _isSpeaker ? const Color(0xFF00E5FF) : Colors.white70,
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isSpeaker = !_isSpeaker);
              _engine.setEnableSpeakerphone(_isSpeaker);
            },
          ),

          // إنهاء المكالمة
          FloatingActionButton.small(
            backgroundColor: Colors.redAccent,
            elevation: 2,
            onPressed: () => _leaveCall(),
            child: const Icon(Icons.call_end_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}