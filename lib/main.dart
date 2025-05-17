// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'services/volumio_service.dart';
import 'services/wled_service.dart';
import 'services/mqtt_service.dart';
import 'screens/splash_screen.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'services/language_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final customTextTheme = Theme.of(context).textTheme.copyWith(
          displayLarge: const TextStyle(
            fontFamily: 'SourceSansPro-Regular',
            fontSize: 60,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          displayMedium: const TextStyle(
            fontFamily: 'SourceSansPro-Regular',
            fontSize: 50,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'SourceSansPro-Regular',
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'SourceSansPro-Regular',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'SourceSansPro-Regular',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
          ),
        );

    return MaterialApp(
      title: 'Nautineros App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: customTextTheme,
        fontFamily: 'SourceSansPro-Regular',
      ),
      home: const SplashScreenWrapper(),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FixedSizeApp()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class FixedSizeApp extends StatefulWidget {
  const FixedSizeApp({super.key});

  @override
  State<FixedSizeApp> createState() => _FixedSizeAppState();
}

class _FixedSizeAppState extends State<FixedSizeApp>
    with TickerProviderStateMixin {
  bool isButton1Active = false; // oświetlenie mesy
  bool isButton2Active = false; // oświetlenie zewnętrzne
  bool isButton3Active = false; // punktowe oświetlenie mesy
  bool isButton4Active = false; // oświetlenie kuchni
  bool isButton5Active = false; // oświetlenie kuchni
  bool isButton6Active = false; // oświetlenie pomieszczeń technicznych
  bool isSecondLampActive = false;

  bool isProfileOverlayVisible = false;
  String profileCode = '3467854';
  String profileCodeTopic = 'nautiner/profile/code';
  late AnimationController _profileSlideController;
  late Animation<double> _profileSlideAnimation;

  double volume = 0.5;
  double _previousVolume = 0.5;
  bool isNightModeActive = false;
  int currentPage = 0;
  bool isPlaying = false;
  late PageController pageController;

  WebViewController? webViewController;
  bool isWebViewLoading = true;
  bool webViewError = false;

  WeatherModel? weatherData;
  bool isLoadingWeather = true;
  bool weatherError = false;

  bool showWindInBft = false;

  Timer? _weatherRefreshTimer;

  final VolumioService _volumioService = VolumioService();
  String currentSongTitle = 'Tytuł utworu';
  String currentSongArtist = 'Artysta';
  String currentAlbumArt = '';
  bool isVolumioPending = false;
  Timer? _playerUpdateTimer;

  late WLEDService _wledService;

  Color ambientColor = const Color.fromRGBO(67, 83, 255, 1);
  int colorTemperature = 4000;
  int brightness = 255;
  bool useColorMode = true;
  bool syncInterfaceColor = false;
  bool isAmbientOverlayVisible = false;

  final MQTTService _mqttService = MQTTService();
  StreamSubscription? _mqttSubscription;

  bool isSettingsOverlayVisible = false;
  bool isPinPromptVisible = false;
  String enteredPin = '';
  final String settingsPin = '2137';

  String mqttBrokerIp = '';
  String mqttBrokerPort = '1883';
  String mqttUsername = '';
  String mqttPassword = '';
  String cabinLightTopic = '';
  String nightLightTopic = '';
  String ambientLightTopic = '';
  String button4Topic = '';
  String button5Topic = '';
  String button6Topic = '';
  String volumioIp = '';
  String wledIp = '';
  String wledSecondaryIp = '';

  final TextEditingController mqttBrokerController = TextEditingController();
  final TextEditingController mqttPortController = TextEditingController();
  final TextEditingController mqttUsernameController = TextEditingController();
  final TextEditingController mqttPasswordController = TextEditingController();
  final TextEditingController cabinLightTopicController =
      TextEditingController();
  final TextEditingController nightLightTopicController =
      TextEditingController();
  final TextEditingController ambientLightTopicController =
      TextEditingController();
  final TextEditingController button4TopicController = TextEditingController();
  final TextEditingController button5TopicController = TextEditingController();
  final TextEditingController button6TopicController = TextEditingController();
  final TextEditingController volumioController = TextEditingController();
  final TextEditingController wledController = TextEditingController();
  final TextEditingController wledSecondaryController = TextEditingController();

  bool isVolumeControlLocked = false;
  bool isVolumeNotificationVisible = false;
  bool isNightModeConfirmationVisible = false;
  Timer? _volumeNotificationTimer;
  Timer? _volumeControlTimer;
  Color? _nightModeWarningColor;

  late AnimationController _volumeSlideController;
  late Animation<double> _volumeSlideAnimation;

  late AnimationController _nightModeSlideController;
  late Animation<double> _nightModeSlideAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isLanguageOverlayVisible = false;

  late StreamSubscription _languageSubscription;

  String _currentTime = ''; // Zmienna dla aktualnego czasu
  late Timer _clockTimer; // Timer do aktualizacji zegara

  double cleanWaterLevel = 90;
  double greyWaterLevel = 80;
  double blackWaterLevel = 70;
  double fuelLevel = 60;

  String cleanWaterTopic = 'nautiner/tanks/clean_water';
  String greyWaterTopic = 'nautiner/tanks/grey_water';
  String blackWaterTopic = 'nautiner/tanks/black_water';
  String fuelTopic = 'nautiner/tanks/fuel';

  final TextEditingController cleanWaterTopicController =
      TextEditingController();
  final TextEditingController greyWaterTopicController =
      TextEditingController();
  final TextEditingController blackWaterTopicController =
      TextEditingController();
  final TextEditingController fuelTopicController = TextEditingController();

  double engineRoomTemp = 35.2;
  double chargerTemp = 28.7;
  double leftBatteryTemp = 42.3;
  double rightBatteryTemp = 31.5;

  String engineRoomTempTopic = 'nautiner/temperature/engine_room';
  String chargerTempTopic = 'nautiner/temperature/charger';
  String leftBatteryTempTopic = 'nautiner/temperature/left_battery';
  String rightBatteryTempTopic = 'nautiner/temperature/right_battery';

  final TextEditingController engineRoomTempTopicController =
      TextEditingController();
  final TextEditingController chargerTempTopicController =
      TextEditingController();
  final TextEditingController leftBatteryTempTopicController =
      TextEditingController();
  final TextEditingController rightBatteryTempTopicController =
      TextEditingController();

  double battery12VLevel = 90;
  double battery12VVoltage = 12.4;
  double battery24VLevel = 85;
  double battery24VVoltage = 24.2;
  double battery48VLevel = 80;
  double battery48VVoltage = 47.8;

  String battery12VLevelTopic = 'nautiner/batteries/12v/level';
  String battery12VVoltageTopic = 'nautiner/batteries/12v/voltage';
  String battery24VLevelTopic = 'nautiner/batteries/24v/level';
  String battery24VVoltageTopic = 'nautiner/batteries/24v/voltage';
  String battery48VLevelTopic = 'nautiner/batteries/48v/level';
  String battery48VVoltageTopic = 'nautiner/batteries/48v/voltage';

  final TextEditingController battery12VLevelTopicController =
      TextEditingController();
  final TextEditingController battery12VVoltageTopicController =
      TextEditingController();
  final TextEditingController battery24VLevelTopicController =
      TextEditingController();
  final TextEditingController battery24VVoltageTopicController =
      TextEditingController();
  final TextEditingController battery48VLevelTopicController =
      TextEditingController();
  final TextEditingController battery48VVoltageTopicController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    LanguageService.initialize();

    _languageSubscription = LanguageService.languageStream.listen((_) {
      if (mounted) setState(() {});
    });

    _profileSlideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _profileSlideAnimation = Tween<double>(
      begin: -357.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _profileSlideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _mqttService.subscribeToTopic(profileCodeTopic, (topic, message) {
      if (mounted) {
        setState(() {
          profileCode = message;
        });
      }
    });

    ambientColor = const Color.fromRGBO(67, 83, 255, 1);
    syncInterfaceColor = true;
    pageController = PageController(initialPage: 0, viewportFraction: 1.0);

    _volumeSlideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _volumeSlideAnimation = Tween<double>(
      begin: -357.0, // wysokość kontenera powiadomienia
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _volumeSlideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _nightModeSlideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _nightModeSlideAnimation = Tween<double>(
      begin: -468.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _nightModeSlideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // Usunięto podwójną inicjalizację kontrolera animacji profilu

    _initializeWebView();

    _fetchWeatherData();

    _weatherRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _fetchWeatherData();
    });

    _updateVolumiPlayerState();

    _playerUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateVolumiPlayerState();
    });

    _initializeMQTT();

    mqttBrokerController.text = _mqttService.host;
    volumioController.text = _volumioService.host;

    _wledService = WLEDService(ip: '192.168.68.70');
    wledController.text = _wledService.ip;

    _initializeWLED();

    _initializeVolumeControl();

    _loadClickSound();

    cleanWaterTopicController.text = cleanWaterTopic;
    greyWaterTopicController.text = greyWaterTopic;
    blackWaterTopicController.text = blackWaterTopic;
    fuelTopicController.text = fuelTopic;

    engineRoomTempTopicController.text = engineRoomTempTopic;
    chargerTempTopicController.text = chargerTempTopic;
    leftBatteryTempTopicController.text = leftBatteryTempTopic;
    rightBatteryTempTopicController.text = rightBatteryTempTopic;

    battery12VLevelTopicController.text = battery12VLevelTopic;
    battery12VVoltageTopicController.text = battery12VVoltageTopic;
    battery24VLevelTopicController.text = battery24VLevelTopic;
    battery24VVoltageTopicController.text = battery24VVoltageTopic;
    battery48VLevelTopicController.text = battery48VLevelTopic;
    battery48VVoltageTopicController.text = battery48VVoltageTopic;

    _mqttService.subscribeToTopic(profileCodeTopic, (topic, message) {
      if (mounted) {
        setState(() {
          profileCode = message;
        });
      }
    });

    // Inicjalizacja zegara
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  Future<void> _loadClickSound() async {
    await _audioPlayer.setSource(AssetSource('sounds/click.mp3'));
    await _audioPlayer.setVolume(0.5);
  }

  void _playClickSound() async {
    await _audioPlayer.stop();
    await _audioPlayer.resume();
  }

  @override
  void dispose() {
    _languageSubscription.cancel();
    LanguageService.dispose();

    pageController.dispose();
    _weatherRefreshTimer?.cancel();
    _playerUpdateTimer?.cancel();

    _mqttSubscription?.cancel();
    _mqttService.dispose();

    mqttBrokerController.dispose();
    volumioController.dispose();
    wledController.dispose();

    _volumeNotificationTimer?.cancel();
    _volumeControlTimer?.cancel();

    _volumeSlideController.dispose();
    _nightModeSlideController.dispose();
    _profileSlideController.dispose();

    cleanWaterTopicController.dispose();
    greyWaterTopicController.dispose();
    blackWaterTopicController.dispose();
    fuelTopicController.dispose();

    engineRoomTempTopicController.dispose();
    chargerTempTopicController.dispose();
    leftBatteryTempTopicController.dispose();
    rightBatteryTempTopicController.dispose();

    battery12VLevelTopicController.dispose();
    battery12VVoltageTopicController.dispose();
    battery24VLevelTopicController.dispose();
    battery24VVoltageTopicController.dispose();
    battery48VLevelTopicController.dispose();
    battery48VVoltageTopicController.dispose();

    _clockTimer.cancel();

    super.dispose();
  }

  void _initializeWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..enableZoom(true)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  isWebViewLoading = true;
                  webViewError = false;
                });
              }
              print('WebView - Strona zaczęła się ładować: $url');
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  isWebViewLoading = false;
                });
              }
              print('WebView - Strona załadowana: $url');
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  webViewError = true;
                  isWebViewLoading = false;
                });
              }
              print(
                  'WebView - Błąd: ${error.description}, Kod: ${error.errorCode}, URL: ${error.url}');
            },
          ),
        )
        ..loadRequest(Uri.parse('https://www.windy.com/?52.248,21.003,5'));

      if (mounted) {
        setState(() {
          webViewController = controller;
        });
      }
    } catch (e) {
      print('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          webViewError = true;
        });
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      isLoadingWeather = true;
      weatherError = false;
    });

    try {
      final data = await WeatherService.getWeatherData();
      if (mounted) {
        setState(() {
          weatherData = data;
          isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          weatherError = true;
          isLoadingWeather = false;
        });
      }
      print('Failed to fetch weather data: $e');
    }
  }

  Future<void> _updateVolumiPlayerState() async {
    try {
      final trackInfo = await _volumioService.getCurrentTrack();

      if (mounted) {
        setState(() {
          currentSongTitle = trackInfo['title'];
          currentSongArtist = trackInfo['artist'];

          final albumArt = trackInfo['albumart'] ?? '';
          currentAlbumArt = albumArt;

          isPlaying = trackInfo['status'] == 'play';

          if (!isVolumioPending) {
            volume = trackInfo['volume'] / 100;
          }
        });
      }
    } catch (e) {
      print('Nie można zaktualizować stanu odtwarzacza: $e');
    }
  }

  Future<void> _initializeMQTT() async {
    try {
      await _mqttService.connect();

      _mqttSubscription = _mqttService.stateStream.listen((lightStates) {
        print('Received MQTT states: $lightStates but not updating UI state');
      });

      _mqttService.subscribeToTopic(cleanWaterTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            cleanWaterLevel = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania poziomu wody czystej: $e');
        }
      });

      _mqttService.subscribeToTopic(greyWaterTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            greyWaterLevel = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania poziomu wody szarej: $e');
        }
      });

      _mqttService.subscribeToTopic(blackWaterTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            blackWaterLevel = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania poziomu fekaliów: $e');
        }
      });

      _mqttService.subscribeToTopic(fuelTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            fuelLevel = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania poziomu paliwa: $e');
        }
      });

      _mqttService.subscribeToTopic(engineRoomTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            engineRoomTemp = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania temperatury silnika: $e');
        }
      });

      _mqttService.subscribeToTopic(chargerTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            chargerTemp = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania temperatury ładowarki: $e');
        }
      });

      _mqttService.subscribeToTopic(leftBatteryTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            leftBatteryTemp = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania temperatury baterii lewej: $e');
        }
      });

      _mqttService.subscribeToTopic(rightBatteryTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            rightBatteryTemp = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania temperatury baterii prawej: $e');
        }
      });

      _mqttService.subscribeToTopic(battery12VLevelTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            battery12VLevel = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania poziomu baterii 12V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery12VVoltageTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            battery12VVoltage = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania napięcia baterii 12V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery24VLevelTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            battery24VLevel = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania poziomu baterii 24V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery24VVoltageTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            battery24VVoltage = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania napięcia baterii 24V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery48VLevelTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            battery48VLevel = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania poziomu baterii 48V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery48VVoltageTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            battery48VVoltage = value;
          });
        } catch (e) {
          print('Błąd podczas parsowania napięcia baterii 48V: $e');
        }
      });
    } catch (e) {
      print('Cannot connect to MQTT broker: $e');
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _initializeMQTT();
        }
      });
    }
  }

  void _showAmbientOverlay() {
    setState(() {
      isAmbientOverlayVisible = true;
    });
  }

  void _closeAmbientOverlay() {
    setState(() {
      isAmbientOverlayVisible = false;
    });
  }

  Future<void> _initializeWLED() async {
    try {
      print('Testowanie połączenia z WLED...');
      if (isSecondLampActive) {
        await _updateWLEDState();
      }
      print('Połączenie z WLED nawiązane pomyślnie');
    } catch (e) {
      print('Błąd podczas inicjalizacji WLED: $e');
      Future.delayed(const Duration(seconds: 10), _initializeWLED);
    }
  }

  void _initializeVolumeControl() {
    _volumeControlTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();

      if (now.hour == 21 && now.minute == 55) {
        _showVolumeNotification();
        setState(() {
          _nightModeWarningColor = const Color.fromRGBO(255, 204, 0, 0.91);
        });
      }

      if (now.hour == 22 && now.minute == 0) {
        _reduceVolume();
      }

      if (now.hour == 0 && now.minute == 0) {
        _muteAndLockVolume();
      }

      setState(() {
        isVolumeControlLocked = now.hour >= 0 && now.hour < 6;
        if (isVolumeControlLocked) {
          _nightModeWarningColor = const Color.fromRGBO(255, 0, 0, 1);
        } else if (now.hour < 21 || now.hour >= 6) {
          _nightModeWarningColor = null;
        }
      });
    });
  }

  void _reduceVolume() async {
    if (!mounted) return;

    setState(() {
      _previousVolume = volume;
      volume = volume * 0.5;
    });

    try {
      await _volumioService.setVolume((volume * 100).round());
    } catch (e) {
      print('Błąd podczas zmniejszania głośności: $e');
    }
  }

  void _muteAndLockVolume() async {
    if (!mounted) return;

    setState(() {
      _previousVolume = volume;
      volume = 0;
      isVolumeControlLocked = true;
    });

    try {
      await _volumioService.setVolume(0);
    } catch (e) {
      print('Błąd podczas wyciszania: $e');
    }
  }

  void _showVolumeNotification() {
    setState(() {
      isVolumeNotificationVisible = true;
    });
    _volumeSlideController.reset();
    _volumeSlideController.forward();

    _volumeNotificationTimer?.cancel();
    _volumeNotificationTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _volumeSlideController.reverse().then((_) {
          setState(() {
            isVolumeNotificationVisible = false;
          });
        });
      }
    });
  }

  void _showNightModeConfirmation() {
    setState(() {
      isNightModeConfirmationVisible = true;
    });
    _nightModeSlideController.reset();
    _nightModeSlideController.forward();
  }

  void _closeNightModeConfirmation() {
    _nightModeSlideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          isNightModeConfirmationVisible = false;
        });
      }
    });
  }

  void _disableNightMode() {
    _nightModeSlideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          isVolumeControlLocked = false;
          volume = _previousVolume;
          isNightModeConfirmationVisible = false;
        });

        try {
          _volumioService.setVolume((volume * 100).round());
        } catch (e) {
          print('Błąd podczas przywracania głośności: $e');
        }
      }
    });
  }

  void _showSettingsOverlay() {
    // Pokaż najpierw ekran z kodem PIN
    setState(() {
      isPinPromptVisible = true;
      enteredPin = '';
    });
  }

  void _verifyPin() {
    if (enteredPin == settingsPin) {
      setState(() {
        isPinPromptVisible = false;
        isSettingsOverlayVisible = true;

        // Wypełnij pola konfiguracyjne aktualnymi wartościami
        mqttBrokerController.text = _mqttService.host;
        mqttPortController.text = _mqttService.port.toString();
        mqttUsernameController.text = _mqttService.username;
        mqttPasswordController.text = _mqttService.password;
        cabinLightTopicController.text = _mqttService.cabinLightTopic;
        nightLightTopicController.text = _mqttService.nightLightTopic;
        ambientLightTopicController.text = _mqttService.ambientLightTopic;
        button4TopicController.text = _mqttService.button4Topic;
        button5TopicController.text = _mqttService.button5Topic;
        button6TopicController.text = _mqttService.button6Topic;
        volumioController.text = _volumioService.host;
        wledController.text = _wledService.ip;
        wledSecondaryController.text = _wledService.secondaryIp;
        cleanWaterTopicController.text = cleanWaterTopic;
        greyWaterTopicController.text = greyWaterTopic;
        blackWaterTopicController.text = blackWaterTopic;
        fuelTopicController.text = fuelTopic;
        engineRoomTempTopicController.text = engineRoomTempTopic;
        chargerTempTopicController.text = chargerTempTopic;
        leftBatteryTempTopicController.text = leftBatteryTempTopic;
        rightBatteryTempTopicController.text = rightBatteryTempTopic;
        battery12VLevelTopicController.text = battery12VLevelTopic;
        battery12VVoltageTopicController.text = battery12VVoltageTopic;
        battery24VLevelTopicController.text = battery24VLevelTopic;
        battery24VVoltageTopicController.text = battery24VVoltageTopic;
        battery48VLevelTopicController.text = battery48VLevelTopic;
        battery48VVoltageTopicController.text = battery48VVoltageTopic;
      });
    } else {
      // Pokaż komunikat o nieprawidłowym PINie
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nieprawidłowy kod PIN'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        enteredPin = '';
      });
    }
  }

  void _closeSettingsOverlay() {
    setState(() {
      isSettingsOverlayVisible = false;
    });
  }

  void _addPinDigit(String digit) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += digit;
      });

      if (enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _removePinDigit() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  void _saveSettings() {
    setState(() {
      // Aktualizacja konfiguracji MQTT
      _mqttService.updateHost(mqttBrokerController.text);
      _mqttService.updatePort(int.tryParse(mqttPortController.text) ?? 1883);
      _mqttService.updateCredentials(
          mqttUsernameController.text, mqttPasswordController.text);
      _mqttService.updateTopics(
        cabinLight: cabinLightTopicController.text,
        nightLight: nightLightTopicController.text,
        ambientLight: ambientLightTopicController.text,
        button4: button4TopicController.text,
        button5: button5TopicController.text,
        button6: button6TopicController.text,
      );

      // Aktualizacja tematów zbiorników
      cleanWaterTopic = cleanWaterTopicController.text;
      greyWaterTopic = greyWaterTopicController.text;
      blackWaterTopic = blackWaterTopicController.text;
      fuelTopic = fuelTopicController.text;

      // Aktualizacja tematów temperatur
      engineRoomTempTopic = engineRoomTempTopicController.text;
      chargerTempTopic = chargerTempTopicController.text;
      leftBatteryTempTopic = leftBatteryTempTopicController.text;
      rightBatteryTempTopic = rightBatteryTempTopicController.text;

      // Aktualizacja tematów baterii
      battery12VLevelTopic = battery12VLevelTopicController.text;
      battery12VVoltageTopic = battery12VVoltageTopicController.text;
      battery24VLevelTopic = battery24VLevelTopicController.text;
      battery24VVoltageTopic = battery24VVoltageTopicController.text;
      battery48VLevelTopic = battery48VLevelTopicController.text;
      battery48VVoltageTopic = battery48VVoltageTopicController.text;

      // Aktualizacja konfiguracji Volumio
      _volumioService.updateHost(volumioController.text);

      // Aktualizacja konfiguracji WLED
      _wledService.updateIp(wledController.text);
      _wledService.updateSecondaryIp(wledSecondaryController.text);

      isSettingsOverlayVisible = false;
    });

    // Ponowne połączenie z usługami
    _initializeMQTT();
    _updateVolumiPlayerState();
    _initializeWLED();
  }

  void updateVolume(double newVolume) async {
    if (isVolumeControlLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Regulacja głośności jest zablokowana w godzinach 00:00 - 06:00'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      volume = newVolume;
      isVolumioPending = true;
    });

    try {
      await _volumioService.setVolume((volume * 100).round());
    } catch (e) {
      print('Błąd podczas ustawiania głośności: $e');
    } finally {
      if (mounted) {
        setState(() {
          isVolumioPending = false;
        });
      }
    }
  }

  void togglePlayPause() async {
    try {
      await _volumioService.togglePlay();
      _updateVolumiPlayerState();
    } catch (e) {
      print('Błąd podczas przełączania odtwarzania: $e');
    }
  }

  void previousTrack() async {
    try {
      await _volumioService.previous();
      _updateVolumiPlayerState();
    } catch (e) {
      print('Błąd podczas przejścia do poprzedniego utworu: $e');
    }
  }

  void nextTrack() async {
    try {
      await _volumioService.next();
      _updateVolumiPlayerState();
    } catch (e) {
      print('Błąd podczas przejścia do następnego utworu: $e');
    }
  }

  void toggleNightMode() {
    final now = DateTime.now();
    final isNightMode = now.hour >= 22 || now.hour < 6;

    if (isNightMode) {
      _showNightModeConfirmation();
    } else if (now.hour >= 6 &&
        now.hour < 22 &&
        !(now.hour == 21 && now.minute >= 55)) {
      _showVolumeNotification();
    }
  }

  Future<void> _updateWLEDState() async {
    if (!isSecondLampActive) return;

    try {
      if (useColorMode) {
        await _wledService.setColor(ambientColor, brightness: brightness);
      } else {
        await _wledService.setWhiteTemperature(colorTemperature,
            brightness: brightness);
      }
    } catch (e) {
      print('Błąd aktualizacji stanu WLED: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd sterowania oświetleniem: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateColor(Color color) {
    setState(() {
      ambientColor = color;
      useColorMode = true;

      if (syncInterfaceColor) {
        // Synchronizacja kolorów interfejsu już obsłużona przez getInterfaceColor i getInterfaceIconColor
      }
    });

    if (isSecondLampActive) {
      _wledService
          .setColor(ambientColor, brightness: brightness)
          .catchError((e) {
        print('Błąd aktualizacji koloru WLED: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd aktualizacji koloru: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _updateColorTemperature(int kelvin) {
    setState(() {
      colorTemperature = kelvin;
      useColorMode = false;

      if (syncInterfaceColor) {
        // Synchronizacja kolorów interfejsu już obsłużona przez getInterfaceColor i getInterfaceIconColor
      }
    });

    if (isSecondLampActive) {
      _wledService
          .setWhiteTemperature(colorTemperature, brightness: brightness)
          .catchError((e) {
        print('Błąd aktualizacji temperatury barwowej WLED: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd aktualizacji temperatury barwowej: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _updateBrightness(int value) {
    setState(() {
      brightness = value;
    });

    if (isSecondLampActive) {
      if (useColorMode) {
        _wledService
            .setColor(ambientColor, brightness: brightness)
            .catchError((e) {
          print('Błąd aktualizacji jasności (tryb koloru) WLED: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd aktualizacji jasności: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        });
      } else {
        _wledService
            .setWhiteTemperature(colorTemperature, brightness: brightness)
            .catchError((e) {
          print('Błąd aktualizacji jasności (tryb temperatury) WLED: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd aktualizacji jasności: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        });
      }
    }
  }

  void _toggleSyncInterface(bool value) {
    setState(() {
      syncInterfaceColor = value;
    });
  }

  Color getInterfaceColor(bool isActive) {
    if (!isActive) {
      return const Color.fromRGBO(161, 161, 161, 0.3);
    }

    if (syncInterfaceColor) {
      if (useColorMode) {
        return ambientColor.withOpacity(0.3);
      } else {
        final hue = (colorTemperature - 1000) / 6000.0 * 30.0;
        return HSVColor.fromAHSV(0.3, hue, 0.7, 1.0).toColor();
      }
    } else {
      return const Color.fromRGBO(67, 83, 255, 0.3);
    }
  }

  Color getInterfaceIconColor(bool isActive) {
    if (!isActive) {
      return const Color.fromRGBO(111, 112, 116, 1);
    }

    if (syncInterfaceColor) {
      if (useColorMode) {
        return ambientColor;
      } else {
        final hue = (colorTemperature - 1000) / 6000.0 * 30.0;
        return HSVColor.fromAHSV(1.0, hue, 0.7, 1.0).toColor();
      }
    } else {
      return const Color.fromRGBO(67, 83, 255, 1);
    }
  }

  void _showLanguageOverlay() {
    setState(() {
      isLanguageOverlayVisible = true;
    });
  }

  // Te metody zostały przeniesione do innej części kodu

  Widget buildLanguageOverlay() {
    return GestureDetector(
      onTap: () => setState(() => isLanguageOverlayVisible = false),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 30, 30, 1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LanguageService.translate('language'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                for (var lang in ['pl', 'en', 'de', 'nl', 'it'])
                  TextButton(
                    onPressed: () {
                      _playClickSound();
                      LanguageService.setLanguage(lang);
                      setState(() {
                        isLanguageOverlayVisible = false;
                      });
                    },
                    child: Text(
                      {
                        'pl': 'Polski',
                        'en': 'English',
                        'de': 'Deutsch',
                        'nl': 'Nederlands',
                        'it': 'Italiano'
                      }[lang]!,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTankGauge({
    required String title,
    required double level,
    required double width,
    Color gaugeColor = const Color(0xFF64D2FF),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: width * 0.6,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${level.toInt()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        SizedBox(
          width: width,
          height: 15,
          child: SfLinearGauge(
            minimum: 0,
            maximum: 100,
            showLabels: false,
            showTicks: false,
            orientation: LinearGaugeOrientation.horizontal,
            axisTrackStyle: LinearAxisTrackStyle(
              thickness: 12.59,
              borderWidth: 0,
              color: Colors.white.withOpacity(0.3),
              edgeStyle: LinearEdgeStyle.bothCurve,
            ),
            barPointers: [
              LinearBarPointer(
                value: level,
                thickness: 12.59,
                color: gaugeColor,
                edgeStyle: LinearEdgeStyle.bothCurve,
              )
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16.40,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '100',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16.40,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget buildBatteryGauge({
    required String title,
    required double level,
    required double voltage,
    required double width,
  }) {
    Color getBatteryColor(double level) {
      if (level > 70) {
        return const Color(0xFF00FF48);
      } else if (level > 30) {
        return const Color(0xFFFFA500);
      } else {
        return const Color(0xFFFF0000);
      }
    }

    return Container(
      width: width,
      margin: const EdgeInsets.only(
          bottom: 4.0), // Zmniejszony odstęp między bateriami
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nazwa baterii
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.90,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Wartość procentowa - przeniesiona tutaj
              Text(
                '${level.toInt()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25.79,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(
              height:
                  2), // Zmniejszono z 4 na 2 odległość między tytułem a wykresem soc
          SizedBox(
            width: width,
            height: 12.60,
            child: SfLinearGauge(
              minimum: 0,
              maximum: 100,
              showLabels: false,
              showTicks: false,
              orientation: LinearGaugeOrientation.horizontal,
              axisTrackStyle: LinearAxisTrackStyle(
                thickness: 12.60,
                borderWidth: 0,
                color: Colors.white.withOpacity(0.3),
                edgeStyle: LinearEdgeStyle.bothCurve,
              ),
              barPointers: [
                LinearBarPointer(
                  value: level,
                  thickness: 12.60,
                  color: getBatteryColor(level),
                  edgeStyle: LinearEdgeStyle.bothCurve,
                )
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Zamienione miejscami napięcie i tekst "Napięcie baterii"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Napięcie baterii',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16.41,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${voltage.toStringAsFixed(1)} V',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16.41,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTemperatureGauge({
    required String title,
    required double temperature,
    required double width,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: width * 0.6,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${temperature.toStringAsFixed(1)}°C',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        SizedBox(
          width: width,
          height: 15,
          child: Stack(
            children: [
              Container(
                width: width,
                height: 15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.3),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0000AA), // Granatowy

                      Color(0xFF000000), // Czarny

                      Color(0xFFFF0000), // Czerwony
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              SfLinearGauge(
                minimum: 0,
                maximum: 60,
                showLabels: false,
                showTicks: false,
                orientation: LinearGaugeOrientation.horizontal,
                axisTrackStyle: const LinearAxisTrackStyle(
                  thickness: 12.59,
                  borderWidth: 0,
                  color: Colors.transparent,
                ),
                markerPointers: [
                  LinearShapePointer(
                    value: temperature,
                    width: 4,
                    height: 15,
                    color: Colors.white,
                    shapeType: LinearShapePointerType.rectangle,
                    position: LinearElementPosition.cross,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0°C',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '60°C',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  // Funkcja aktualizująca czas
  void _updateTime() {
    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _currentTime = formattedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Użyjmy stałego współczynnika skalowania, aby zachować proporcje
          final buttonScale = math.min(width / 1920, height / 1080);
          final fontSize = buttonScale * 29.0;

          // Obliczamy odsunięcia, żeby wycentrować interface
          final horizontalOffset = (width - 1920 * buttonScale) / 2;
          final verticalOffset = (height - 1080 * buttonScale) / 2;

          // Oryginalne wymiary
          final buttonWidth = 153 * buttonScale;
          final buttonHeight = 147 * buttonScale;
          // Zmienna buttonSpacing nie jest już potrzebna

          // Wymiary paneli bocznych
          final sideContainerWidth = 540 * buttonScale;
          final batteryContainerHeight = 310 * buttonScale;
          final tanksContainerHeight = 215 * buttonScale;
          final tempContainerHeight = 215 * buttonScale;

          // Wymiary i pozycje paneli
          final screenCenter = width / 2;

          // Obliczamy najpierw pionowe odstępy
          final verticalGapBetweenContainers = (height -
                  verticalOffset * 2 -
                  200 * buttonScale -
                  batteryContainerHeight -
                  tanksContainerHeight -
                  tempContainerHeight) /
              2;

          // Wymiary centralnego panelu
          final centralContainerWidth = (540 + 120) * buttonScale;
          final centralContainerHeight = batteryContainerHeight +
              tanksContainerHeight +
              tempContainerHeight +
              115;

          // Pozycja centralnego panelu
          final centralContainerX = screenCenter - (centralContainerWidth / 2);

          // Wymiary paska głośności
          final volumeBarWidth = 500 * buttonScale;
          final volumeBarHeight = 130 * buttonScale;

          // Pozycja paska głośności i przycisków
          final volumeBarX =
              centralContainerX + centralContainerWidth + 50 * buttonScale;

          // Standardowe odstępy
          final standardSpacing = 30 * buttonScale;

          return Container(
            width: width,
            height: height,
            color: const Color.fromARGB(255, 0, 0, 0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Górny pasek z logo itp.
                Positioned(
                  top: verticalOffset,
                  left: horizontalOffset,
                  child: Container(
                    width: 1920 * buttonScale,
                    height: 162 * buttonScale,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/Outline.png"),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: const Stack(),
                  ),
                ),

                // Przyciski języka i ustawień
                Positioned(
                  top: verticalOffset + height * 0.025,
                  left: horizontalOffset + width * 0.015,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      _showLanguageOverlay();
                    },
                    child: Container(
                      width: 175 * buttonScale,
                      height: 71 * buttonScale,
                      decoration: ShapeDecoration(
                        color: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25 * buttonScale),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 3.0,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.language,
                          color: Colors.white,
                          size: 45 * buttonScale,
                        ),
                      ),
                    ),
                  ),
                ),
                // Przycisk profilu
                Positioned(
                  top: verticalOffset + height * 0.025,
                  right: horizontalOffset + width * 0.015,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        isProfileOverlayVisible = true;
                      });
                      // Uruchamiamy animację pokazującą overlay profilu
                      _profileSlideController.forward();
                    },
                    child: Container(
                      width: 175 * buttonScale,
                      height: 71 * buttonScale,
                      decoration: ShapeDecoration(
                        color: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25 * buttonScale),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 3.0,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 35 * buttonScale,
                        ),
                      ),
                    ),
                  ),
                ),
                // Profile Overlay
                // Profile overlay with backdrop
                if (isProfileOverlayVisible)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // Backdrop for closing on tap outside
                          GestureDetector(
                            onTap: () {
                              _profileSlideController.reverse().then((_) {
                                setState(() {
                                  isProfileOverlayVisible = false;
                                });
                              });
                            },
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                          // Sliding centered profile dialog
                          Center(
                            child: Transform.translate(
                              offset: Offset(0, _profileSlideAnimation.value),
                              child: Material(
                                color: Colors.transparent,
                                elevation: 8,
                                borderRadius: BorderRadius.circular(34),
                                child: Container(
                                  width: 635,
                                  height: 360,
                                  decoration: const ShapeDecoration(
                                    color: Color(0xFF262626),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(34)),
                                    ),
                                  ),

                                  child: Stack(
                                    children: [
                                      const Positioned(
                                        left: 56,
                                        top: 56,
                                        child: SizedBox(
                                          width: 518,
                                          child: Text(
                                            'Aby się zalogować, \nwpisz poniższy kod w aplikacji mobilnej',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w700,
                                        height: 1.21,
                                        letterSpacing: -0.40,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 220,
                                  top: 159,
                                  child: Text(
                                    profileCode,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w600,
                                      height: 0.71,
                                      letterSpacing: -0.40,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 32,
                                  top: 239,
                                  child: Container(
                                    width: 567,
                                    height: 81,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x3F000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 4),
                                          spreadRadius: 0,
                                        )
                                      ],
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        _profileSlideController.reverse().then((_) {
                                          if (mounted) {
                                            setState(() {
                                              isProfileOverlayVisible = false;
                                            });
                                          }
                                        });
                                      },
                                      child: const Center(
                                        child: Text(
                                          'OK',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 34,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w600,
                                            height: 1.21,
                                            letterSpacing: 0.60,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Positioned(
                  bottom: verticalOffset + height * 0.025,
                  left: horizontalOffset + width * 0.015,
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    color: Colors.white,
                    iconSize: 30 * buttonScale,
                    onPressed: () {
                      _playClickSound();
                      _showSettingsOverlay();
                    },
                  ),
                ),

                // Panel boczny z bateriami
                Positioned(
                  top: verticalOffset + 200 * buttonScale,
                  left: horizontalOffset +
                      centralContainerX -
                      sideContainerWidth -
                      100 * buttonScale,
                  child: Container(
                    width: sideContainerWidth,
                    height: batteryContainerHeight,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF6F7074),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(27.88 * buttonScale),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Zawartość panelu baterii
                        Positioned(
                          left: 34 * buttonScale,
                          top: 15 * buttonScale,
                          child: SizedBox(
                            width: 120 * buttonScale,
                            height: 30 * buttonScale,
                            child: Text(
                              LanguageService.translate('batteries'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28 * buttonScale,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 40 * buttonScale,
                          top: 50 * buttonScale,
                          child: SizedBox(
                            width: sideContainerWidth -
                                80 * buttonScale, // Dostosowana szerokość
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildBatteryGauge(
                                  title:
                                      LanguageService.translate('battery_12v'),
                                  level: battery12VLevel,
                                  voltage: battery12VVoltage,
                                  width: sideContainerWidth - 80 * buttonScale,
                                ),
                                SizedBox(
                                    height:
                                        3 * buttonScale), // Zmniejszony odstęp
                                buildBatteryGauge(
                                  title:
                                      LanguageService.translate('battery_24v'),
                                  level: battery24VLevel,
                                  voltage: battery24VVoltage,
                                  width: sideContainerWidth - 80 * buttonScale,
                                ),
                                SizedBox(
                                    height:
                                        3 * buttonScale), // Zmniejszony odstęp
                                buildBatteryGauge(
                                  title:
                                      LanguageService.translate('battery_48v'),
                                  level: battery48VLevel,
                                  voltage: battery48VVoltage,
                                  width: sideContainerWidth - 80 * buttonScale,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Panel boczny ze zbiornikami
                Positioned(
                  top: verticalOffset +
                      155 * buttonScale +
                      batteryContainerHeight +
                      verticalGapBetweenContainers,
                  left: horizontalOffset +
                      centralContainerX -
                      sideContainerWidth -
                      100 * buttonScale,
                  child: Container(
                    width: sideContainerWidth,
                    height: tanksContainerHeight,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF6F7074),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(27.87 * buttonScale),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 29 * buttonScale,
                          top: 12 * buttonScale,
                          child: SizedBox(
                            width: 175.10 * buttonScale,
                            height: 27.01 * buttonScale,
                            child: Text(
                              LanguageService.translate('tanks'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25 * buttonScale,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 29 * buttonScale,
                          top: 47 * buttonScale,
                          child: SizedBox(
                            width: 220.14 * buttonScale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildTankGauge(
                                  title:
                                      LanguageService.translate('clean_water'),
                                  level: cleanWaterLevel,
                                  width: 220.22 * buttonScale,
                                  gaugeColor: const Color(0xFF64D2FF),
                                ),
                                buildTankGauge(
                                  title:
                                      LanguageService.translate('grey_water'),
                                  level: greyWaterLevel,
                                  width: 219.22 * buttonScale,
                                  gaugeColor: const Color(0xFF64D2FF),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 291.61 * buttonScale,
                          top: 47 * buttonScale,
                          child: SizedBox(
                            width: 220.14 * buttonScale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildTankGauge(
                                  title:
                                      LanguageService.translate('black_water'),
                                  level: blackWaterLevel,
                                  width: 220.22 * buttonScale,
                                  gaugeColor: const Color(0xFF64D2FF),
                                ),
                                buildTankGauge(
                                  title: LanguageService.translate('fuel'),
                                  level: fuelLevel,
                                  width: 219.22 * buttonScale,
                                  gaugeColor: const Color(0xFF64D2FF),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Panel boczny z temperaturami
                Positioned(
                  top: verticalOffset +
                      110 * buttonScale +
                      batteryContainerHeight +
                      verticalGapBetweenContainers +
                      tanksContainerHeight +
                      verticalGapBetweenContainers,
                  left: horizontalOffset +
                      centralContainerX -
                      sideContainerWidth -
                      100 * buttonScale,
                  child: Container(
                    width: sideContainerWidth,
                    height: tempContainerHeight,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF6F7074),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(27.87 * buttonScale),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 29 * buttonScale,
                          top: 12 * buttonScale,
                          child: SizedBox(
                            width: 480 * buttonScale,
                            height: 27.01 * buttonScale,
                            child: Text(
                              LanguageService.translate('tech_rooms_temps'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22 * buttonScale,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 29 * buttonScale,
                          top: 47 * buttonScale,
                          child: SizedBox(
                            width: 220.14 * buttonScale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildTemperatureGauge(
                                  title:
                                      LanguageService.translate('engine_room'),
                                  temperature: engineRoomTemp,
                                  width: 220.22 * buttonScale,
                                ),
                                buildTemperatureGauge(
                                  title:
                                      LanguageService.translate('charger_room'),
                                  temperature: chargerTemp,
                                  width: 219.22 * buttonScale,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 291.61 * buttonScale,
                          top: 47 * buttonScale,
                          child: SizedBox(
                            width: 220.14 * buttonScale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildTemperatureGauge(
                                  title:
                                      LanguageService.translate('left_battery'),
                                  temperature: leftBatteryTemp,
                                  width: 220.22 * buttonScale,
                                ),
                                buildTemperatureGauge(
                                  title: LanguageService.translate(
                                      'right_battery'),
                                  temperature: rightBatteryTemp,
                                  width: 219.22 * buttonScale,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Centralny panel - aktualizacja pozycji Positioned
                Positioned(
                  top: verticalOffset +
                      180 * buttonScale, // Ta sama wysokość co kontener baterii
                  left: centralContainerX,
                  width: centralContainerWidth,
                  height: centralContainerHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(161, 161, 161, 0.01),
                      borderRadius: BorderRadius.circular(28.39 * buttonScale),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: pageController,
                            onPageChanged: (index) {
                              setState(() {
                                currentPage = index % 3;
                              });
                            },
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              final pageIndex = index % 3;
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: currentPage == pageIndex ? 1.0 : 0.0,
                                child: IgnorePointer(
                                  ignoring: currentPage != pageIndex,
                                  child: Builder(
                                    builder: (context) {
                                      switch (pageIndex) {
                                        case 0:
                                          return buildMusicWidget();
                                        case 1:
                                          return buildWeatherWidget();
                                        case 2:
                                          return buildWebViewWidget();
                                        default:
                                          return buildMusicWidget();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12.0,
                            top: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (index) => GestureDetector(
                                onTap: () {
                                  pageController.animateToPage(
                                    (pageController.page?.toInt() ?? 0) -
                                        (pageController.page?.toInt() ?? 0) %
                                            3 +
                                        index,
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: currentPage == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dodanie linii rozdzielającej między kolumnami przycisków
                Positioned(
                  top: verticalOffset + 205 * buttonScale,
                  left: 1642 * buttonScale,
                  child: Container(
                    width: 3,
                    height: buttonHeight * 2.54 +
                        (buttonHeight + fontSize * 1 + standardSpacing),
                    color: Colors.white.withOpacity(1),
                  ),
                ),

                // Pierwszy przycisk - Oświetlenie mesy
                Positioned(
                  top: verticalOffset + 200 * buttonScale,
                  left: volumeBarX,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        isButton1Active = !isButton1Active;
                        _mqttService.sendCommand(3, isButton1Active ? 1 : 0);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: buttonWidth,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            color: isButton1Active
                                ? getInterfaceColor(true)
                                : getInterfaceColor(false),
                            borderRadius:
                                BorderRadius.circular(28.39 * buttonScale),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.light_mode,
                                size: 45 * buttonScale,
                                color: isButton1Active
                                    ? getInterfaceIconColor(true)
                                    : getInterfaceIconColor(false),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.006),
                        Text(
                          LanguageService.translate('mess_light'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize * 0.75,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Drugi przycisk - Oświetlenie zewnętrzne
                Positioned(
                  top: verticalOffset + 200 * buttonScale,
                  left: volumeBarX + volumeBarWidth - buttonWidth,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        isButton2Active = !isButton2Active;
                        _mqttService.sendCommand(2, isButton2Active ? 1 : 0);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: buttonWidth,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            color: isButton2Active
                                ? getInterfaceColor(true)
                                : getInterfaceColor(false),
                            borderRadius:
                                BorderRadius.circular(28.39 * buttonScale),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.light_mode,
                                size: 45 * buttonScale,
                                color: isButton2Active
                                    ? getInterfaceIconColor(true)
                                    : getInterfaceIconColor(false),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.006),
                        Text(
                          LanguageService.translate('external_light'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize * 0.75,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Trzeci przycisk - Punktowe oświetlenie mesy
                Positioned(
                  top: verticalOffset +
                      200 * buttonScale +
                      buttonHeight +
                      fontSize * 1.5 +
                      standardSpacing,
                  left: volumeBarX,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        isButton3Active = !isButton3Active;
                        _mqttService.sendCommand(4, isButton3Active ? 1 : 0);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: buttonWidth,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            color: isButton3Active
                                ? getInterfaceColor(true)
                                : getInterfaceColor(false),
                            borderRadius:
                                BorderRadius.circular(28.39 * buttonScale),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.light_mode,
                                size: 45 * buttonScale,
                                color: isButton3Active
                                    ? getInterfaceIconColor(true)
                                    : getInterfaceIconColor(false),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.006),
                        Text(
                          LanguageService.translate('individual_mess_light'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize * 0.75,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Czwarty przycisk - Oświetlenie pomieszczeń technicznych
                Positioned(
                  top: verticalOffset +
                      200 * buttonScale +
                      buttonHeight +
                      fontSize * 1.5 +
                      standardSpacing,
                  left: volumeBarX + volumeBarWidth - buttonWidth,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        isButton6Active = !isButton6Active;
                        _mqttService.sendCommand(6, isButton6Active ? 1 : 0);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: buttonWidth,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            color: isButton6Active
                                ? getInterfaceColor(true)
                                : getInterfaceColor(false),
                            borderRadius:
                                BorderRadius.circular(28.39 * buttonScale),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.engineering,
                                size: 45 * buttonScale,
                                color: isButton6Active
                                    ? getInterfaceIconColor(true)
                                    : getInterfaceIconColor(false),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.006),
                        Text(
                          LanguageService.translate('tech_rooms_light'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize * 0.75,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Piąty przycisk - Ambient
                Positioned(
                  top: verticalOffset +
                      200 * buttonScale +
                      2 * (buttonHeight + fontSize * 1.5 + standardSpacing),
                  left: volumeBarX,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        isSecondLampActive = !isSecondLampActive;
                        if (isSecondLampActive) {
                          _wledService.setPower(true);
                          _updateWLEDState();
                        } else {
                          _wledService.setPower(false);
                        }
                      });
                    },
                    onLongPress: () {
                      _playClickSound();
                      _showAmbientOverlay();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: buttonWidth,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            color: isSecondLampActive
                                ? getInterfaceColor(true)
                                : getInterfaceColor(false),
                            borderRadius:
                                BorderRadius.circular(28.39 * buttonScale),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                size: 45 * buttonScale,
                                color: isSecondLampActive
                                    ? getInterfaceIconColor(true)
                                    : getInterfaceIconColor(false),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.006),
                        Text(
                          'Ambient',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize * 0.75,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Szósty przycisk - Oświetlenie kuchni
                Positioned(
                  top: verticalOffset +
                      200 * buttonScale +
                      2 * (buttonHeight + fontSize * 1.5 + standardSpacing),
                  left: volumeBarX + volumeBarWidth - buttonWidth,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      setState(() {
                        isButton4Active = !isButton4Active;
                        _mqttService.sendCommand(5, isButton4Active ? 1 : 0);
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: buttonWidth,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            color: isButton4Active
                                ? getInterfaceColor(true)
                                : getInterfaceColor(false),
                            borderRadius:
                                BorderRadius.circular(28.39 * buttonScale),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.kitchen,
                                size: 45 * buttonScale,
                                color: isButton4Active
                                    ? getInterfaceIconColor(true)
                                    : getInterfaceIconColor(false),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.006),
                        Text(
                          LanguageService.translate('kitchen_light'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize * 0.75,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Panel z głośnością i przyciskiem nocnym
                Positioned(
                  bottom: verticalOffset + 90 * buttonScale,
                  left: volumeBarX,
                  child: Container(
                    width: volumeBarWidth,
                    height: volumeBarHeight,
                    padding: EdgeInsets.symmetric(
                        vertical: 20 * buttonScale,
                        horizontal: 15 * buttonScale),
                    decoration: BoxDecoration(
                      color: syncInterfaceColor
                          ? getInterfaceColor(true)
                          : const Color.fromRGBO(67, 83, 255, 0.3),
                      borderRadius: BorderRadius.circular(28.39 * buttonScale),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Material(
                          color: const Color.fromRGBO(255, 255, 255, 0),
                          child: InkWell(
                            onTap: null,
                            child: Container(
                              width: volumeBarWidth * 0.7,
                              height:
                                  90 * buttonScale, // Dokładnie 90px wysokości
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255)
                                    .withOpacity(1.0),
                                borderRadius:
                                    BorderRadius.circular(28.39 * buttonScale),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      double newVolume = volume - 0.05 < 0.0 ? 0.0 : volume - 0.05;
                                      updateVolume(newVolume);
                                    },
                                    child: Icon(
                                      Icons.volume_down_rounded,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      size:
                                          55 * buttonScale, // Zwiększona ikona
                                    ),
                                  ),
                                  Text(
                                    '${(volume * 100).round()}%',
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      fontSize:
                                          fontSize * 1.3, // Zwiększony tekst
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      double newVolume = volume + 0.05 > 1.0 ? 1.0 : volume + 0.05;
                                      updateVolume(newVolume);
                                    },
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                      size:
                                          55 * buttonScale, // Zwiększona ikona
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: volumeBarWidth * 0.025), // Zwiększony odstęp
                        GestureDetector(
                          onTap: toggleNightMode,
                          child: Container(
                            width: volumeBarWidth * 0.19,
                            height:
                                90 * buttonScale, // Dokładnie 90px wysokości
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(28.39 * buttonScale),
                            ),
                            child: Center(
                              child: Icon(
                                MdiIcons.weatherNight,
                                color: isNightModeActive
                                    ? _nightModeWarningColor ??
                                        const Color.fromARGB(255, 0, 0, 0)
                                    : const Color.fromARGB(255, 0, 0, 0),
                                size: 55 * buttonScale, // Zwiększona ikona
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pozostałe elementy - logo, zegar, pogoda
                Positioned(
                  top: verticalOffset + 40 * buttonScale,
                  left: horizontalOffset + 520 * buttonScale,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Icon(
                      weatherData?.getWeatherIcon() ?? Icons.wb_sunny,
                      color: weatherData?.getIconColor() ?? Colors.yellow,
                      size: 60 * buttonScale,
                    ),
                  ),
                ),
                Positioned(
                  top: verticalOffset + 40 * buttonScale,
                  left: horizontalOffset + 570 * buttonScale,
                  child: GestureDetector(
                    onTap: () {
                      _playClickSound();
                      pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: SizedBox(
                      width: 130 * buttonScale,
                      height: 60 * buttonScale,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  weatherData?.temperature.toStringAsFixed(0) ??
                                      '--',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48 * buttonScale,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                                height: 0.85,
                                letterSpacing: -0.40,
                              ),
                            ),
                            TextSpan(
                              text: '°C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48 * buttonScale,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                height: 0.85,
                                letterSpacing: -0.40,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: verticalOffset + 40 * buttonScale,
                  left: horizontalOffset + 863 * buttonScale,
                  child: Container(
                    width: 193.22 * buttonScale,
                    height: 83 * buttonScale,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/logo.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: verticalOffset + 40 * buttonScale,
                  left: horizontalOffset + 1220 * buttonScale,
                  child: SizedBox(
                    width: 130 * buttonScale,
                    height: 60 * buttonScale,
                    child: Text(
                      _currentTime,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48 * buttonScale,
                        fontWeight: FontWeight.w600,
                        height: 0.85,
                        letterSpacing: -0.40,
                      ),
                    ),
                  ),
                ),
                // Elementy overlay
                if (isAmbientOverlayVisible)
                  Positioned.fill(
                    child: buildAmbientLightOverlay(),
                  ),
                if (isSettingsOverlayVisible)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            width: width * 0.3,
                            padding: EdgeInsets.all(20 * buttonScale),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(30, 30, 30, 1),
                              borderRadius:
                                  BorderRadius.circular(28.39 * buttonScale),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      LanguageService.translate('settings'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.025),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: mqttBrokerController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'mqtt_broker_ip'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller: mqttPortController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'mqtt_broker_port'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller: volumioController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'volumio_ip'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller: wledController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'wled_ip'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller: wledSecondaryController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'wled_secondary_ip'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: mqttUsernameController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'mqtt_username'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller: mqttPasswordController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'mqtt_password'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                cabinLightTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'cabin_light_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                nightLightTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'night_light_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                ambientLightTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'ambient_light_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.025),
                                Text(
                                  "Dodatkowe przyciski",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize * 0.7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: height * 0.018),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: button4TopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText: 'Przycisk 4 Topic',
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller: button5TopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText: 'Przycisk 5 Topic',
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: button6TopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText: 'Przycisk 6 Topic',
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.025),
                                Text(
                                  LanguageService.translate('tank_topics'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize * 0.7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: height * 0.018),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller:
                                                cleanWaterTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'clean_water_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                greyWaterTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'grey_water_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller:
                                                blackWaterTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'black_water_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller: fuelTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'fuel_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.025),
                                Text(
                                  LanguageService.translate(
                                      'temperature_topics'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize * 0.7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: height * 0.018),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller:
                                                engineRoomTempTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'engine_temp_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                chargerTempTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'charger_temp_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller:
                                                leftBatteryTempTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'left_battery_temp_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                rightBatteryTempTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'right_battery_temp_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.025),
                                Text(
                                  "Tematy baterii",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize * 0.7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: height * 0.018),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller:
                                                battery12VLevelTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Temat poziom baterii 12V',
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                battery12VVoltageTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: LanguageService.translate(
                                                  'battery_12v_voltage_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                battery24VLevelTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Temat poziom baterii 24V',
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller:
                                                battery24VVoltageTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: LanguageService.translate(
                                                  'battery_24v_voltage_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                battery48VLevelTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Temat poziom baterii 48V',
                                              labelStyle: TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                battery48VVoltageTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: LanguageService.translate(
                                                  'battery_48v_voltage_topic'),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white70),
                                              enabledBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white54),
                                              ),
                                              focusedBorder:
                                                  const UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: _closeSettingsOverlay,
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(120, 45),
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        LanguageService.translate('cancel'),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        _saveSettings();
                                        _closeSettingsOverlay();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(120, 45),
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        elevation: 2,
                                      ),
                                      child: Text(
                                        LanguageService.translate('save'),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isPinPromptVisible)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      child: Center(
                        child: Container(
                          width: width * 0.3,
                          padding: EdgeInsets.all(20 * buttonScale),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(30, 30, 30, 1),
                            borderRadius:
                                BorderRadius.circular(28.39 * buttonScale),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    LanguageService.translate('enter_pin'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        isPinPromptVisible = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.025),
                              Text(
                                enteredPin,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: height * 0.025),
                              GridView.builder(
                                shrinkWrap: true,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2,
                                ),
                                itemCount: 12,
                                itemBuilder: (context, index) {
                                  if (index == 9) {
                                    return TextButton(
                                      onPressed: _removePinDigit,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Icon(
                                        Icons.backspace,
                                        size: 24,
                                      ),
                                    );
                                  } else if (index == 10) {
                                    return TextButton(
                                      onPressed: () => _addPinDigit('0'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        '0',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  } else {
                                    final digit = (index + 1).toString();
                                    return TextButton(
                                      onPressed: () => _addPinDigit(digit),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        digit,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isVolumeNotificationVisible)
                  Positioned(
                    top: _volumeSlideAnimation.value,
                    left: (width - 631) / 2,
                    child: GestureDetector(
                      onTap: () => null,
                      child: SizedBox(
                        width: 631,
                        height: 357,
                        child: Stack(
                          children: [
                            Container(
                              width: 631,
                              height: 357,
                              decoration: const ShapeDecoration(
                                color: Color(0xFF262626),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(34),
                                    bottomRight: Radius.circular(34),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 65,
                              top: 128,
                              child: SizedBox(
                                width: 518,
                                child: Text(
                                  LanguageService.translate(
                                      'volume_notification'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontFamily: 'SourceSansPro-Regular',
                                    fontWeight: FontWeight.w700,
                                    height: 1.42,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 263,
                              top: 25,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(0, 255, 255, 255),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.warning_rounded,
                                  size: 100,
                                  color: Color.fromARGB(200, 255, 204, 0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isNightModeConfirmationVisible)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        _nightModeSlideController.reverse().then((_) {
                          setState(() {
                            isNightModeConfirmationVisible = false;
                          });
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: AnimatedBuilder(
                          animation: _nightModeSlideController,
                          builder: (context, child) {
                            return Positioned(
                              top: _nightModeSlideAnimation.value,
                              left: (width - 631) / 2,
                              child: GestureDetector(
                                onTap: () => null,
                                child: SizedBox(
                                  width: 631,
                                  height: 468,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: Container(
                                          width: 631,
                                          height: 442,
                                          decoration: const ShapeDecoration(
                                            color: Color(0xFF262626),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(34),
                                                bottomRight:
                                                    Radius.circular(34),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 65,
                                        top: 149.67,
                                        child: SizedBox(
                                          width: 518,
                                          height: 238.54,
                                          child: Text(
                                            LanguageService.translate(
                                                'night_mode_warning'),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w700,
                                              height: 1.42,
                                              letterSpacing: -0.40,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 179,
                                        top: 368,
                                        child: SizedBox(
                                          width: 274,
                                          height: 39.76,
                                          child: Text(
                                            LanguageService.translate(
                                                'continue_question'),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFFFF0000),
                                              fontSize: 24,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w600,
                                              height: 1.42,
                                              letterSpacing: -0.40,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 20,
                                        bottom: 20,
                                        child: Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed:
                                                  _closeNightModeConfirmation,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(290, 60),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                LanguageService.translate('no'),
                                                style: const TextStyle(
                                                    fontSize: 24),
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            ElevatedButton(
                                              onPressed: _disableNightMode,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: Text(
                                                LanguageService.translate(
                                                    'yes'),
                                                style: const TextStyle(
                                                    fontSize: 24),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                if (isLanguageOverlayVisible) buildLanguageOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildMusicWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Stack(
        children: [
          if (currentAlbumArt.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.39),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _getFullAlbumArtUrl(currentAlbumArt),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10.0,
                        sigmaY: 10.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(28.39),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 46),
              SizedBox(
                width: 300,
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28.39),
                  child: Container(
                    width: 300,
                    height: 300,
                    color: Colors.transparent,
                    child: currentAlbumArt.isNotEmpty
                        ? Image.network(
                            _getFullAlbumArtUrl(currentAlbumArt),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading album art: $error');
                              return _buildDefaultAlbumArt();
                            },
                          )
                        : _buildDefaultAlbumArt(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            currentSongTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentSongArtist,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 22,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.fast_rewind_rounded,
                                color: Colors.white,
                                size: 65,
                              ),
                              onPressed: previousTrack,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 40),
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 70,
                              ),
                              onPressed: togglePlayPause,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 40),
                            IconButton(
                              icon: const Icon(
                                Icons.fast_forward_rounded,
                                color: Colors.white,
                                size: 65,
                              ),
                              onPressed: nextTrack,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFullAlbumArtUrl(String albumArtPath) {
    if (albumArtPath.startsWith('http')) {
      return albumArtPath;
    }

    String baseUrl = 'http://${_volumioService.host}:${_volumioService.port}';

    if (albumArtPath.isNotEmpty && albumArtPath.startsWith('/')) {
      return '$baseUrl$albumArtPath';
    } else if (albumArtPath.isNotEmpty) {
      return '$baseUrl/$albumArtPath';
    } else {
      return '$baseUrl/default_album_art.png'; // Domyślny obrazek w przypadku braku ścieżki
    }
  }

  Widget _buildDefaultAlbumArt() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color.fromRGBO(50, 50, 50, 1),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.album,
          size: 80,
          color:
              syncInterfaceColor ? getInterfaceIconColor(true) : Colors.white54,
        ),
        Positioned(
          bottom: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              LanguageService.translate('media_disabled'),
              style: TextStyle(
                color: syncInterfaceColor
                    ? getInterfaceIconColor(true)
                    : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildWeatherWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: isLoadingWeather
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            LanguageService.translate('loading_weather'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : weatherError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                LanguageService.translate('weather_error'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _fetchWeatherData,
                                child: Text(
                                    LanguageService.translate('try_again')),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Icon(
                                  weatherData?.getWeatherIcon() ??
                                      Icons.wb_sunny,
                                  color: weatherData?.getIconColor() ??
                                      Colors.yellow,
                                ),
                              ),
                            ),
                            Text(
                              '${weatherData?.temperature.toStringAsFixed(1) ?? ""}°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              weatherData?.description ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  buildWeatherDetail(
                                    Icons.water_drop,
                                    '${weatherData?.humidity ?? ""}%',
                                    'humidity',
                                  ),
                                  buildWindDetail(),
                                  buildWeatherDetail(
                                    Icons.compress,
                                    '${weatherData?.pressure ?? ""} hPa',
                                    'pressure',
                                  ),
                                  buildWeatherDetail(
                                    Icons.waves,
                                    '${weatherData?.waterTemperature.toStringAsFixed(1) ?? ""}°C',
                                    'water_temp',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          LanguageService.translate(label),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget buildWindDetail() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              showWindInBft = !showWindInBft;
            });
          },
          child: const Icon(
            Icons.air,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () {
            setState(() {
              showWindInBft = !showWindInBft;
            });
          },
          child: Text(
            showWindInBft
                ? weatherData?.getWindSpeedInBft() ?? ""
                : '${weatherData?.getWindSpeedInKmh() ?? ""} km/h',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          LanguageService.translate('wind'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget buildWebViewWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.39),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  webViewError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                LanguageService.translate('webview_error'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isWebViewLoading = true;
                                  });
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    _initializeWebView();
                                  });
                                },
                                child: Text(
                                    LanguageService.translate('try_again')),
                              ),
                            ],
                          ),
                        )
                      : Positioned.fill(
                          child: webViewController != null
                              ? WebViewWidget(
                                  controller: webViewController!,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                  if (isWebViewLoading)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAmbientLightOverlay() {
    return GestureDetector(
      onTap: _closeAmbientOverlay,
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 800,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(30, 30, 30, 1),
                borderRadius: BorderRadius.circular(28.39),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LanguageService.translate('ambient_settings'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _closeAmbientOverlay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        LanguageService.translate('color_temp'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Switch(
                        value: useColorMode,
                        onChanged: (value) {
                          setState(() {
                            useColorMode = value;
                          });
                        },
                        activeColor: ambientColor,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                      ),
                      Text(
                        LanguageService.translate('rgb_color'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Opacity(
                      opacity: useColorMode ? 1.0 : 0.3,
                      child: AbsorbPointer(
                        absorbing: !useColorMode,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 20,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 15,
                              elevation: 4,
                            ),
                            overlayColor: Colors.white.withOpacity(0.2),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 25,
                            ),
                          ),
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.red,
                                  Colors.yellow,
                                  Colors.green,
                                  Colors.cyan,
                                  Colors.blue,
                                  Colors.purple,
                                  Colors.red,
                                ],
                              ),
                            ),
                            child: Slider(
                              value: HSVColor.fromColor(ambientColor).hue,
                              min: 0,
                              max: 360,
                              onChanged: (value) {
                                final hsv = HSVColor.fromColor(ambientColor);
                                final newColor = hsv.withHue(value).toColor();
                                _updateColor(newColor);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Opacity(
                      opacity: useColorMode ? 0.3 : 1.0,
                      child: AbsorbPointer(
                        absorbing: useColorMode,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 20,
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 15,
                              elevation: 4,
                            ),
                            overlayColor: Colors.white.withOpacity(0.2),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 25,
                            ),
                          ),
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF5F00),
                                  Color(0xFFFFD6AA),
                                  Color(0xFFFFFFFF),
                                  Color(0xFFD6E7FF),
                                  Color(0xFF9CB9FF),
                                ],
                              ),
                            ),
                            child: Slider(
                              value: colorTemperature.toDouble(),
                              min: 2000,
                              max: 10000,
                              onChanged: (value) {
                                _updateColorTemperature(value.toInt());
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 1,
                      color: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          LanguageService.translate('brightness'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 20,
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 15,
                                elevation: 4,
                              ),
                              overlayColor: Colors.white.withOpacity(0.2),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 25,
                              ),
                            ),
                            child: Slider(
                              value: brightness.toDouble(),
                              min: 0,
                              max: 255,
                              onChanged: (value) {
                                _updateBrightness(value.toInt());
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${(brightness / 255 * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Switch(
                        value: syncInterfaceColor,
                        onChanged: _toggleSyncInterface,
                        activeColor: ambientColor,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        LanguageService.translate('sync_interface'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileOverlay() {
    return SizedBox(
      width: 631,
      height: 357,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 631,
              height: 357,
              decoration: const ShapeDecoration(
                color: Color(0xFF262626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(34),
                    bottomRight: Radius.circular(34),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 56,
            top: 56,
            child: SizedBox(
              width: 518,
              child: Text(
                'Aby się zalogować, \nwpisz poniższy kod w aplikacji mobilnej',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 1.21,
                  letterSpacing: -0.40,
                ),
              ),
            ),
          ),
          Positioned(
            left: 220,
            top: 159,
            child: Text(
              profileCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                height: 0.71,
                letterSpacing: -0.40,
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 239,
            child: Container(
              width: 567,
              height: 81,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 78.64,
                    top: 20,
                    child: SizedBox(
                      width: 403.52,
                      child: Text(
                        'OK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 34,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          height: 1.21,
                          letterSpacing: 0.60,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
