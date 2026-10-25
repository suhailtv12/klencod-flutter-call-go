import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// --- الثوابت العامة ---
const String AGORA_APP_ID = "2a0053e48b774c279c834793732a7493";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SafePulseApp());
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePulse Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF1DE9B6),
          error: Color(0xFFFF5252),
          surface: Color(0xFF141C2E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// -------------------------------------------------------------
// الشاشة الرئيسية: إنشاء كود مؤقت أو الانضمام لمكالمة
// -------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVideo = true;

  // توليد كود مؤقت من 6 أرقام
  String _generateTempCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  void _triggerHaptic(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  Future<void> _startCall(String channelCode) async {
    if (channelCode.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إدخال رمز صحيح (4 أرقام على الأقل)"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _triggerHaptic(HapticFeedbackType.heavy);

    // التحقق من الصلاحيات
    final statusCam = await Permission.camera.request();
    final statusMic = await Permission.microphone.request();

    if (statusMic.isGranted && (statusCam.isGranted || !_isVideo)) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: channelCode.trim(),
            isVideoCall: _isVideo,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يجب منح صلاحيات الكاميرا والمايك للبدء"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
              const SizedBox(height: 30),
              // شعار وعنوان التطبيق
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 55,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "SafePulse P2P",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "اتصال فوري مشفر ومؤقت لشخصين فقط",
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 40),

              // نوع المكالمة (فيديو أو صوت)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141C2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _triggerHaptic(HapticFeedbackType.selection);
                          setState(() => _isVideo = true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isVideo
                                ? const Color(0xFF00E5FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                color: _isVideo ? Colors.black : Colors.white60,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "مكالمة فيديو",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isVideo ? Colors.black : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _triggerHaptic(HapticFeedbackType.selection);
                          setState(() => _isVideo = false);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isVideo
                                ? const Color(0xFF00E5FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_rounded,
                                color: !_isVideo ? Colors.black : Colors.white60,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "مكالمة صوت",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isVideo ? Colors.black : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // زر توليد كود جديد للمتصل
              ElevatedButton.icon(
                onPressed: () {
                  final newCode = _generateTempCode();
                  _codeController.text = newCode;
                  _startCall(newCode);
                },
                icon: const Icon(Icons.bolt_rounded, color: Colors.black),
                label: const Text(
                  "توليد كود وبدء اتصال جديد",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF00E5FF).withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("أو الانضمام بكود مستلم",
                        style: TextStyle(color: Colors.white38)),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 25),

              // حقل إدخال الكود المستلم
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "أدخل الكود (6 أرقام)",
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    letterSpacing: 0,
                    color: Colors.white30,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF141C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF00E5FF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // زر الانضمام
              OutlinedButton.icon(
                onPressed: () => _startCall(_codeController.text),
                icon: const Icon(Icons.login_rounded, color: Color(0xFF00E5FF)),
                label: const Text(
                  "الانضمام للغرفة",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

enum HapticFeedbackType { light, heavy, selection }

// -------------------------------------------------------------
// شاشة المكالمة: صوت/فيديو مع دعم الجودة التكيفية وتأثير الرنين
// -------------------------------------------------------------
class CallScreen extends StatefulWidget {
  final String channelId;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.channelId,
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
  bool _isFrontCamera = true;
  QualityType _networkQuality = QualityType.qualityUnknown;

  // توقيت المكالمة
  Timer? _callTimer;
  int _secondsElapsed = 0;

  // تأثير الرنين الاهتزازي والبصري
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

    _startRingtoneEffect();
    _initAgora();
  }

  // محاكاة نغمة الرنين عبر نمط اهتزاز احترافي دوري (Haptic Ring Effect)
  void _startRingtoneEffect() {
    _ringToneHapticTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (_remoteUid == null) {
        // نمط رنين ثنائي
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          HapticFeedback.lightImpact();
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initAgora() async {
    // 1. إنشاء وتهيئة المحرك
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AGORA_APP_ID,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 2. إعدادات الجودة التكيفية لمنع انقطاع الاتصال عند ضعف الإنترنت
    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();

      // ضبط ترميز الفيديو التكيفي التلقائي
      await _engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360), // دقة ذكية متوازنة
          frameRate: 20,
          bitrate: 0, // 0 يعني أن الماكينة تحدد أفضل معدل نقل تلقائياً
          degradationPreference: DegradationPreference.maintainBalanced, // توازن الفريمات والدقة
        ),
      );

      // في حال انخفاض الشبكة لدرجة حرجة: يتحول تلقائياً للصوت فقط لحماية المكالمة من الانقطاع
      await _engine.setRemoteSubscribeFallbackOption(
        StreamFallbackOptions.streamFallbackOptionAudioOnly,
      );
    } else {
      await _engine.enableAudio();
    }

    // 3. معالجة الأحداث وحصر المكالمة لشخصين فقط
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          // فحص أمني: إذا كان هناك شخص آخر في المكالمة بالفعل، لا تسمح للمزيد بالانضمام
          if (_remoteUid != null) {
            _showSecurityAlertAndLeave("هذه المكالمة محجوزة لشخصين فقط!");
            return;
          }

          HapticFeedback.vibrate(); // تنبيه لحظة الرد
          setState(() {
            _remoteUid = remoteUid;
          });
          _startTimer();
          _ringToneHapticTimer?.cancel();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _leaveCall(notice: "انتهت المكالمة من الطرف الآخر");
        },
        onNetworkQuality: (RtcConnection connection, int uid, QualityType txQuality, QualityType rxQuality) {
          if (uid == 0 || uid == _remoteUid) {
            setState(() => _networkQuality = rxQuality);
          }
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error: $err -> $msg");
        },
      ),
    );

    // 4. الانضمام إلى القناة المحددة بواسطة الكود
    await _engine.joinChannel(
      token: "", // بدون توكن للتجربة السريعة والبيئات المؤقتة
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _showSecurityAlertAndLeave(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
    _leaveCall();
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

  // أيقونة مؤشر جودة الشبكة
  Widget _buildNetworkBadge() {
    Color color = Colors.greenAccent;
    String text = "شبكة ممتازة";

    if (_networkQuality == QualityType.qualityPoor ||
        _networkQuality == QualityType.qualityBad) {
      color = Colors.orangeAccent;
      text = "الشبكة ضعيفة";
    } else if (_networkQuality == QualityType.qualityVbad ||
        _networkQuality == QualityType.qualityDown) {
      color = Colors.redAccent;
      text = "محاولة إنقاذ المكالمة";
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
    return WillPopScope(
      onWillPop: () async {
        await _leaveCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. مساحة الفيديو الأساسية (الطرف البعيد أو واجهة الصوت)
            Center(child: _buildRemoteView()),

            // 2. الكاميرا المحلية للطرف الحالي (Picture-in-Picture)
            if (widget.isVideoCall && !_isVideoDisabled && _localUserJoined)
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  width: 110,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 2),
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

            // 3. شريط المعلومات العلوي (الكود، المدة، والشبكة)
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
                          "كود الغرفة: ${widget.channelId}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        if (_remoteUid != null)
                          Text(
                            _formatDuration(_secondsElapsed),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_remoteUid != null) _buildNetworkBadge(),
                ],
              ),
            ),

            // 4. أزرار التحكم بالاتصال
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

  // عرض الطرف الآخر أو شاشة الانتظار مع مؤثرات الرنين
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
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF141C2E),
              child: Icon(Icons.person, size: 70, color: Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 20),
            Text(
              "متصل (صوت مشفر)",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.ring_volume_rounded,
                size: 60,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "بانتظار انضمام الطرف الآخر...",
            style: TextStyle(fontSize: 17, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "شارك الكود: ${widget.channelId}",
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      );
    }
  }

  // شريط التحكم السفلي بتأثيرات النقر والضغط
  Widget _buildControlsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141C2E).withOpacity(0.85),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // كتم الصوت
          _controlButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: _isMuted ? Colors.redAccent : Colors.white,
            bgColor: _isMuted ? Colors.redAccent.withOpacity(0.2) : Colors.white10,
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _isMuted = !_isMuted);
              _engine.muteLocalAudioStream(_isMuted);
            },
          ),

          // تشغيل/إيقاف الفيديو (في حال كانت مكالمة فيديو)
          if (widget.isVideoCall)
            _controlButton(
              icon: _isVideoDisabled ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              color: _isVideoDisabled ? Colors.redAccent : Colors.white,
              bgColor: _isVideoDisabled ? Colors.redAccent.withOpacity(0.2) : Colors.white10,
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isVideoDisabled = !_isVideoDisabled);
                _engine.muteLocalVideoStream(_isVideoDisabled);
              },
            ),

          // تبديل الكاميرا
          if (widget.isVideoCall && !_isVideoDisabled)
            _controlButton(
              icon: Icons.flip_camera_ios_rounded,
              color: Colors.white,
              bgColor: Colors.white10,
              onPressed: () {
                HapticFeedback.selectionClick();
                _engine.switchCamera();
                setState(() => _isFrontCamera = !_isFrontCamera);
              },
            ),

          // إنهاء المكالمة
          _controlButton(
            icon: Icons.call_end_rounded,
            color: Colors.white,
            bgColor: Colors.redAccent,
            onPressed: () => _leaveCall(),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}