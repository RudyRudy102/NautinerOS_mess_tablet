import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'services/volumio_service.dart';
import 'services/wled_service.dart';
import 'services/mqtt_service_fixed.dart';
import 'screens/splash_screen.dart';
import 'widgetpanels.dart';
import 'sensors.dart';
import 'headerelements.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'services/language_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      title: 'YachtOS Mess',
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
  String profileCode = '213742069';
  String profileCodeTopic = 'nautiner/profile/code';
  late AnimationController _profileSlideController;
  late Animation<double> _profileSlideAnimation;

  bool isMultiroomOverlayVisible = false;
  late AnimationController _multiroomSlideController;
  late Animation<double> _multiroomSlideAnimation;

  // Multiroom state
  bool isMessActive = true; // Mesa jest domyślnie aktywna
  bool isBridgeActive = false; // Mostek jest nieaktywny

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

  // Instancja do obsługi paneli widgetów
  late WidgetPanels _widgetPanels;

  // Instancja do obsługi paneli sensorów
  late SensorPanels _sensorPanels;

  // Instancja do obsługi elementów nagłówka
  late HeaderElements _headerElements;

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
  String mesaMultiroomTopic = 'nautiner/multiroom/mesa';
  String bridgeMultiroomTopic = 'nautiner/multiroom/bridge';
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
  final TextEditingController mesaMultiroomTopicController =
      TextEditingController();
  final TextEditingController bridgeMultiroomTopicController =
      TextEditingController();
  final TextEditingController volumioController = TextEditingController();
  final TextEditingController wledController = TextEditingController();
  final TextEditingController wledSecondaryController = TextEditingController();
  final TextEditingController profileCodeTopicController =
      TextEditingController();
  final TextEditingController waterTemperatureTopicController =
      TextEditingController();

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

  String cleanWaterTopic = 'N2K/Tank0';
  String greyWaterTopic = 'N2K/Tank3';
  String blackWaterTopic = 'N2K/Tank1';
  String fuelTopic = 'N2K/Tank2';

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

  // Temperatura wody z MQTT
  double waterTemperature = 15.0;
  String waterTemperatureTopic = 'N2K/WaterTemp';

  String engineRoomTempTopic = 'N2K/Temp1';
  String chargerTempTopic = 'N2K/Temp0';
  String leftBatteryTempTopic = 'N2K/Temp2';
  String rightBatteryTempTopic = 'N2K/Temp3';

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

  String battery12VLevelTopic = 'N2K/12V/SOC';
  String battery12VVoltageTopic = 'N2K/12V/Voltage';
  String battery24VLevelTopic = 'N2K/24V/SOC';
  String battery24VVoltageTopic = 'N2K/24V/Voltage';
  String battery48VLevelTopic = 'Battery/SOC';
  String battery48VVoltageTopic = 'Battery/Voltage';

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

    // Inicjalizacja kontrolera animacji profilu
    _profileSlideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _profileSlideAnimation = Tween<double>(
      begin: -357.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _profileSlideController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

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
      begin:
          -480.0, // wysokość kontenera powiadomienia (450) + dodatkowy margines - zwiększona dla animacji z góry
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
      begin: -520.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _nightModeSlideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

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

    _multiroomSlideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _multiroomSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _multiroomSlideController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

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
    profileCodeTopicController.text = profileCodeTopic;
    waterTemperatureTopicController.text = waterTemperatureTopic;
    mesaMultiroomTopicController.text = mesaMultiroomTopic;
    bridgeMultiroomTopicController.text = bridgeMultiroomTopic;

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

    // Inicjalizacja paneli widgetów
    _initializeWidgetPanels();

    // Inicjalizacja paneli sensorów
    _initializeSensorPanels();

    // Inicjalizacja elementów nagłówka
    _initializeHeaderElements();
  }

  void _initializeWidgetPanels() {
    _widgetPanels = WidgetPanels(
      currentAlbumArt: currentAlbumArt,
      currentSongTitle: currentSongTitle,
      currentSongArtist: currentSongArtist,
      isPlaying: isPlaying,
      volumioService: _volumioService,
      getFullAlbumArtUrl: _getFullAlbumArtUrl,
      buildDefaultAlbumArt: _buildDefaultAlbumArt,
      togglePlayPause: togglePlayPause,
      previousTrack: previousTrack,
      nextTrack: nextTrack,
      weatherData: weatherData,
      isLoadingWeather: isLoadingWeather,
      weatherError: weatherError,
      showWindInBft: showWindInBft,
      fetchWeatherData: _fetchWeatherData,
      setShowWindInBft: (bool value) {
        setState(() {
          showWindInBft = value;
        });
      },
      webViewController: webViewController,
      webViewError: webViewError,
      isWebViewLoading: isWebViewLoading,
      initializeWebView: () {
        setState(() {
          isWebViewLoading = true;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          _initializeWebView();
        });
      },
      syncInterfaceColor: syncInterfaceColor,
      getInterfaceIconColor: getInterfaceIconColor,
    );
  }

  void _updateWidgetPanels() {
    _widgetPanels = WidgetPanels(
      currentAlbumArt: currentAlbumArt,
      currentSongTitle: currentSongTitle,
      currentSongArtist: currentSongArtist,
      isPlaying: isPlaying,
      volumioService: _volumioService,
      getFullAlbumArtUrl: _getFullAlbumArtUrl,
      buildDefaultAlbumArt: _buildDefaultAlbumArt,
      togglePlayPause: togglePlayPause,
      previousTrack: previousTrack,
      nextTrack: nextTrack,
      weatherData: weatherData,
      isLoadingWeather: isLoadingWeather,
      weatherError: weatherError,
      showWindInBft: showWindInBft,
      fetchWeatherData: _fetchWeatherData,
      setShowWindInBft: (bool value) {
        setState(() {
          showWindInBft = value;
        });
      },
      webViewController: webViewController,
      webViewError: webViewError,
      isWebViewLoading: isWebViewLoading,
      initializeWebView: () {
        setState(() {
          isWebViewLoading = true;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          _initializeWebView();
        });
      },
      syncInterfaceColor: syncInterfaceColor,
      getInterfaceIconColor: getInterfaceIconColor,
    );
  }

  void _initializeSensorPanels() {
    _sensorPanels = SensorPanels(
      battery12VLevel: battery12VLevel,
      battery12VVoltage: battery12VVoltage,
      battery24VLevel: battery24VLevel,
      battery24VVoltage: battery24VVoltage,
      battery48VLevel: battery48VLevel,
      battery48VVoltage: battery48VVoltage,
      cleanWaterLevel: cleanWaterLevel,
      greyWaterLevel: greyWaterLevel,
      blackWaterLevel: blackWaterLevel,
      fuelLevel: fuelLevel,
      engineRoomTemp: engineRoomTemp,
      chargerTemp: chargerTemp,
      leftBatteryTemp: leftBatteryTemp,
      rightBatteryTemp: rightBatteryTemp,
      getInterfaceColor: getInterfaceColor,
    );
  }

  void _updateSensorPanels() {
    _sensorPanels = SensorPanels(
      battery12VLevel: battery12VLevel,
      battery12VVoltage: battery12VVoltage,
      battery24VLevel: battery24VLevel,
      battery24VVoltage: battery24VVoltage,
      battery48VLevel: battery48VLevel,
      battery48VVoltage: battery48VVoltage,
      cleanWaterLevel: cleanWaterLevel,
      greyWaterLevel: greyWaterLevel,
      blackWaterLevel: blackWaterLevel,
      fuelLevel: fuelLevel,
      engineRoomTemp: engineRoomTemp,
      chargerTemp: chargerTemp,
      leftBatteryTemp: leftBatteryTemp,
      rightBatteryTemp: rightBatteryTemp,
      getInterfaceColor: getInterfaceColor,
    );
  }

  void _initializeHeaderElements() {
    _headerElements = HeaderElements(
      weatherData: weatherData,
      currentTime: _currentTime,
      profileCode: profileCode,
      isProfileOverlayVisible: isProfileOverlayVisible,
      profileSlideController: _profileSlideController,
      profileSlideAnimation: _profileSlideAnimation,
      isNightModeActive: isVolumeControlLocked,
      nightModeWarningColor: _nightModeWarningColor,
      showLanguageOverlay: _showLanguageOverlay,
      showProfileOverlay: _showProfileOverlay,
      closeProfileOverlay: _closeProfileOverlay,
      toggleNightMode: toggleNightMode,
      playClickSound: _playClickSound,
      navigateToPage: (int page) {
        pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _updateHeaderElements() {
    _headerElements = HeaderElements(
      weatherData: weatherData,
      currentTime: _currentTime,
      profileCode: profileCode,
      isProfileOverlayVisible: isProfileOverlayVisible,
      profileSlideController: _profileSlideController,
      profileSlideAnimation: _profileSlideAnimation,
      isNightModeActive: isVolumeControlLocked,
      nightModeWarningColor: _nightModeWarningColor,
      showLanguageOverlay: _showLanguageOverlay,
      showProfileOverlay: _showProfileOverlay,
      closeProfileOverlay: _closeProfileOverlay,
      toggleNightMode: toggleNightMode,
      playClickSound: _playClickSound,
      navigateToPage: (int page) {
        pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );
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
    _multiroomSlideController.dispose();

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
    mesaMultiroomTopicController.dispose();
    bridgeMultiroomTopicController.dispose();

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
      final data = await WeatherService.getWeatherData(
          waterTemperature: waterTemperature);
      if (mounted) {
        setState(() {
          weatherData = data;
          isLoadingWeather = false;
        });
        _updateWidgetPanels();
        _updateHeaderElements();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          weatherError = true;
          isLoadingWeather = false;
        });
        _updateWidgetPanels();
        _updateHeaderElements();
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
        _updateWidgetPanels();
        _updateHeaderElements();
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
            cleanWaterLevel = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania poziomu wody czystej: $e');
        }
      });

      _mqttService.subscribeToTopic(greyWaterTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            greyWaterLevel = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania poziomu wody szarej: $e');
        }
      });

      _mqttService.subscribeToTopic(blackWaterTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            blackWaterLevel = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania poziomu fekaliów: $e');
        }
      });

      _mqttService.subscribeToTopic(fuelTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            fuelLevel = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania poziomu paliwa: $e');
        }
      });

      _mqttService.subscribeToTopic(engineRoomTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            engineRoomTemp = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania temperatury silnika: $e');
        }
      });

      _mqttService.subscribeToTopic(chargerTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            chargerTemp = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania temperatury ładowarki: $e');
        }
      });

      _mqttService.subscribeToTopic(leftBatteryTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            leftBatteryTemp = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania temperatury baterii lewej: $e');
        }
      });

      _mqttService.subscribeToTopic(rightBatteryTempTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            rightBatteryTemp = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania temperatury baterii prawej: $e');
        }
      });

      _mqttService.subscribeToTopic(battery12VLevelTopic, (topic, message) {
        try {
          double value;
          if (message.startsWith('[')) {
            // Jeśli wiadomość jest tablicą JSON, weź pierwszą wartość
            final decoded = json.decode(message);
            if (decoded is List && decoded.isNotEmpty) {
              value = double.parse(decoded[0].toString());
            } else {
              throw Exception('Pusta tablica lub nieprawidłowy format');
            }
          } else {
            // Jeśli wiadomość jest pojedynczą wartością
            value = double.parse(message);
          }
          setState(() {
            battery12VLevel = value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania poziomu baterii 12V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery12VVoltageTopic, (topic, message) {
        try {
          double value;
          if (message.startsWith('[')) {
            // Jeśli wiadomość jest tablicą JSON, weź pierwszą wartość
            final decoded = json.decode(message);
            if (decoded is List && decoded.isNotEmpty) {
              value = double.parse(decoded[0].toString());
            } else {
              throw Exception('Pusta tablica lub nieprawidłowy format');
            }
          } else {
            // Jeśli wiadomość jest pojedynczą wartością
            value = double.parse(message);
          }
          setState(() {
            battery12VVoltage = value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania napięcia baterii 12V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery24VLevelTopic, (topic, message) {
        try {
          double value;
          if (message.startsWith('[')) {
            // Jeśli wiadomość jest tablicą JSON, weź pierwszą wartość
            final decoded = json.decode(message);
            if (decoded is List && decoded.isNotEmpty) {
              value = double.parse(decoded[0].toString());
            } else {
              throw Exception('Pusta tablica lub nieprawidłowy format');
            }
          } else {
            // Jeśli wiadomość jest pojedynczą wartością
            value = double.parse(message);
          }
          setState(() {
            battery24VLevel = value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania poziomu baterii 24V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery24VVoltageTopic, (topic, message) {
        try {
          double value;
          if (message.startsWith('[')) {
            // Jeśli wiadomość jest tablicą JSON, weź pierwszą wartość
            final decoded = json.decode(message);
            if (decoded is List && decoded.isNotEmpty) {
              value = double.parse(decoded[0].toString());
            } else {
              throw Exception('Pusta tablica lub nieprawidłowy format');
            }
          } else {
            // Jeśli wiadomość jest pojedynczą wartością
            value = double.parse(message);
          }
          setState(() {
            battery24VVoltage = value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania napięcia baterii 24V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery48VLevelTopic, (topic, message) {
        try {
          double value;
          if (message.startsWith('[')) {
            // Jeśli wiadomość jest tablicą JSON, weź pierwszą wartość
            final decoded = json.decode(message);
            if (decoded is List && decoded.isNotEmpty) {
              value = double.parse(decoded[0].toString());
            } else {
              throw Exception('Pusta tablica lub nieprawidłowy format');
            }
          } else {
            // Jeśli wiadomość jest pojedynczą wartością
            value = double.parse(message);
          }
          setState(() {
            battery48VLevel = value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania poziomu baterii 48V: $e');
        }
      });

      _mqttService.subscribeToTopic(battery48VVoltageTopic, (topic, message) {
        try {
          double value;
          if (message.startsWith('[')) {
            // Jeśli wiadomość jest tablicą JSON, weź pierwszą wartość
            final decoded = json.decode(message);
            if (decoded is List && decoded.isNotEmpty) {
              value = double.parse(decoded[0].toString());
            } else {
              throw Exception('Pusta tablica lub nieprawidłowy format');
            }
          } else {
            // Jeśli wiadomość jest pojedynczą wartością
            value = double.parse(message);
          }
          setState(() {
            battery48VVoltage = value;
          });
          _updateSensorPanels();
        } catch (e) {
          print('Błąd podczas parsowania napięcia baterii 48V: $e');
        }
      });

      _mqttService.subscribeToTopic(waterTemperatureTopic, (topic, message) {
        try {
          final value = double.parse(message);
          setState(() {
            waterTemperature = value.isNaN ? 0.0 : value;
          });
          _updateSensorPanels();
          // Odśwież dane pogodowe z nową temperaturą wody
          _fetchWeatherData();
        } catch (e) {
          print('Błąd podczas parsowania temperatury wody: $e');
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

  void _closeVolumeNotification() {
    _volumeNotificationTimer?.cancel();
    _volumeSlideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          isVolumeNotificationVisible = false;
        });
      }
    });
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
        profileCodeTopicController.text = profileCodeTopic;
        waterTemperatureTopicController.text = waterTemperatureTopic;
        mesaMultiroomTopicController.text = mesaMultiroomTopic;
        bridgeMultiroomTopicController.text = bridgeMultiroomTopic;

        _mqttService.subscribeToTopic(profileCodeTopic, (topic, message) {
          if (mounted) {
            setState(() {
              profileCode = message;
            });
          }
        });
      });
    } else {
      // Pokaż komunikat o nieprawidłowym PINie
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.translate('invalid_pin')),
          duration: const Duration(seconds: 2),
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
        mesaMultiroom: mesaMultiroomTopicController.text,
        bridgeMultiroom: bridgeMultiroomTopicController.text,
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
      waterTemperatureTopic = waterTemperatureTopicController.text;

      // Aktualizacja tematów baterii
      battery12VLevelTopic = battery12VLevelTopicController.text;
      battery12VVoltageTopic = battery12VVoltageTopicController.text;
      battery24VLevelTopic = battery24VLevelTopicController.text;
      battery24VVoltageTopic = battery24VVoltageTopicController.text;
      battery48VLevelTopic = battery48VLevelTopicController.text;
      battery48VVoltageTopic = battery48VVoltageTopicController.text;

      // Aktualizacja tematu kodu profilu
      profileCodeTopic = profileCodeTopicController.text;

      // Aktualizacja tematów multiroom
      mesaMultiroomTopic = mesaMultiroomTopicController.text;
      bridgeMultiroomTopic = bridgeMultiroomTopicController.text;

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

  void _showMultiroomOverlay() {
    setState(() {
      isMultiroomOverlayVisible = true;
    });
    _multiroomSlideController.reset();
    _multiroomSlideController.forward();
  }

  void _closeMultiroomOverlay() {
    _multiroomSlideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          isMultiroomOverlayVisible = false;
        });
      }
    });
  }

  void updateVolume(double newVolume) async {
    if (isVolumeControlLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.translate('volume_locked')),
          duration: const Duration(seconds: 2),
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
          content: Text(
              '${LanguageService.translate('lighting_control_error')}: $e'),
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
            content:
                Text('${LanguageService.translate('color_update_error')}: $e'),
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
            content:
                Text('${LanguageService.translate('color_temp_error')}: $e'),
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
              content:
                  Text('${LanguageService.translate('brightness_error')}: $e'),
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
              content:
                  Text('${LanguageService.translate('brightness_error')}: $e'),
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

  void _showProfileOverlay() {
    setState(() {
      isProfileOverlayVisible = true;
    });
    // Rozpocznij animację pokazywania
    _profileSlideController.forward();

    // Nasłuchuj MQTT aby uzyskać aktualny kod
    _mqttService.subscribeToTopic(profileCodeTopic, (topic, message) {
      if (mounted) {
        setState(() {
          profileCode = message;
        });
      }
    });
  }

  void _closeProfileOverlay() {
    print("DEBUG: _closeProfileOverlay() wywołane");
    // Anuluj subskrypcję MQTT przed zamknięciem overlaya
    _mqttService.unsubscribeFromTopic(profileCodeTopic);

    // Animuj zamknięcie overlaya
    _profileSlideController.reverse().then((_) {
      print("DEBUG: animacja reverse zakończona");
      if (mounted) {
        setState(() {
          print("DEBUG: setState wywołane - ukrywanie overlay");
          isProfileOverlayVisible = false;
        });
      }
    });
  }

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

  // Funkcja aktualizująca czas
  void _updateTime() {
    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _currentTime = formattedTime;
    });
    _updateHeaderElements();
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
                // Elementy nagłówka - używamy zrefaktoryzowanej klasy HeaderElements
                _headerElements.buildCompleteHeader(
                  buttonScale: buttonScale,
                  verticalOffset: verticalOffset,
                  horizontalOffset: horizontalOffset,
                  width: width,
                  height: height,
                  volumeBarX: volumeBarX,
                  volumeBarWidth: volumeBarWidth,
                ),

                // Przycisk ustawień - na dole ekranu
                Positioned(
                  bottom: verticalOffset + height * 0.025,
                  left: horizontalOffset + width * 0.015,
                  child: IconButton(
                    icon: const Icon(FontAwesomeIcons.gear),
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
                      100 * buttonScale +
                      33,
                  child: _sensorPanels.buildBatteryPanel(
                    buttonScale: buttonScale,
                    sideContainerWidth: sideContainerWidth,
                    batteryContainerHeight: batteryContainerHeight,
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
                      100 * buttonScale +
                      33,
                  child: _sensorPanels.buildTanksPanel(
                    buttonScale: buttonScale,
                    sideContainerWidth: sideContainerWidth,
                    tanksContainerHeight: tanksContainerHeight,
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
                      100 * buttonScale +
                      33,
                  child: _sensorPanels.buildTemperaturePanel(
                    buttonScale: buttonScale,
                    sideContainerWidth: sideContainerWidth,
                    tempContainerHeight: tempContainerHeight,
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
                                          return _widgetPanels
                                              .buildMusicWidget();
                                        case 1:
                                          return _widgetPanels
                                              .buildWeatherWidget();
                                        case 2:
                                          return _widgetPanels
                                              .buildWebViewWidget();
                                        default:
                                          return _widgetPanels
                                              .buildMusicWidget();
                                      }
                                    },
                                  ),
                                ),
                              );
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
                  left: 1642 * buttonScale - 55,
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
                          'Ambiente',
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
                                FontAwesomeIcons.sink,
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
                            onLongPress: () {
                              _playClickSound();
                              _showMultiroomOverlay();
                            },
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
                                    onTap: () => updateVolume(
                                      volume - 0.05 < 0.0 ? 0.0 : volume - 0.05,
                                    ),
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
                                    onTap: () => updateVolume(
                                      volume + 0.05 > 1.0 ? 1.0 : volume + 0.05,
                                    ),
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
                            width: volumeBarWidth * 0.015), // Zwiększony odstęp
                        GestureDetector(
                          onTap: toggleNightMode,
                          child: Container(
                            width: volumeBarWidth * 0.2,
                            height:
                                110 * buttonScale, // Dokładnie 90px wysokości
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(0, 255, 255, 255),
                              borderRadius:
                                  BorderRadius.circular(28.39 * buttonScale),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/Leon.png',
                                width: 110 * buttonScale,
                                height: 120 * buttonScale,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Elementy overlay
                if (isMultiroomOverlayVisible) ...[
                  // Backdrop (tło) z animacją dissolve
                  AnimatedBuilder(
                    animation: _multiroomSlideController,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Opacity(
                          opacity: _multiroomSlideAnimation.value *
                              0.3, // 30% opacity backdrop
                          child: GestureDetector(
                            onTap: _closeMultiroomOverlay,
                            child: Container(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Właściwy overlay
                  _buildMultiroomOverlay(
                    volumeBarX: volumeBarX,
                    volumeBarWidth: volumeBarWidth,
                    buttonScale: buttonScale,
                    verticalOffset: verticalOffset,
                  ),
                ],
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
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: _closeSettingsOverlay,
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
                                  LanguageService.translate('multiroom_topics'),
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
                                                mesaMultiroomTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'mesa_multiroom_topic'),
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
                                                bridgeMultiroomTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'bridge_multiroom_topic'),
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
                                          SizedBox(height: height * 0.018),
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
                                          SizedBox(height: height * 0.018),
                                          TextField(
                                            controller:
                                                waterTemperatureTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'water_temp_topic'),
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
                                          SizedBox(height: height * 0.018),
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
                                  ],
                                ),
                                // Sekcja Profile Code Topic
                                const SizedBox(height: 30),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            LanguageService.translate(
                                                'profile_settings'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          TextField(
                                            controller:
                                                profileCodeTopicController,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText:
                                                  LanguageService.translate(
                                                      'profile_code_topic'),
                                              labelStyle: const TextStyle(
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

                if (isVolumeNotificationVisible)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeVolumeNotification,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: AnimatedBuilder(
                          animation: _volumeSlideController,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Transform.translate(
                                offset: Offset(0, _volumeSlideAnimation.value),
                                child: GestureDetector(
                                  onTap: () => null,
                                  child: Container(
                                    width: 631,
                                    height:
                                        450, // Zwiększona wysokość z 357 do 450
                                    decoration: const ShapeDecoration(
                                      color: Color(0xFF262626),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(34),
                                          bottomRight: Radius.circular(34),
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          30), // Dodany padding dla całego kontenera
                                      child: Column(
                                        children: [
                                          // Ikona ostrzeżenia
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 15, bottom: 25),
                                            child: Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    0, 255, 255, 255),
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: const Icon(
                                                Icons.warning_rounded,
                                                size: 100,
                                                color: Color.fromARGB(
                                                    200, 255, 204, 0),
                                              ),
                                            ),
                                          ),
                                          // Tekst ostrzeżenia
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal:
                                                      20), // Zmniejszony padding z 65 do 20
                                              child: Center(
                                                child: Text(
                                                  LanguageService.translate(
                                                      'volume_notification'),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontFamily:
                                                        'SourceSansPro-Regular',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.42,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Przycisk OK
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 20), // Tylko górny padding
                                            child: SizedBox(
                                              width: double
                                                  .infinity, // Pełna szerokość
                                              height:
                                                  60, // Większa wysokość przycisku
                                              child: ElevatedButton(
                                                onPressed:
                                                    _closeVolumeNotification,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                  ),
                                                ),
                                                child: Text(
                                                  LanguageService.translate(
                                                      'ok'),
                                                  style: const TextStyle(
                                                      fontSize:
                                                          20, // Większy tekst
                                                      fontWeight:
                                                          FontWeight.bold),
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
                            );
                          },
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
                        color: Colors.black.withOpacity(0.5),
                        child: AnimatedBuilder(
                          animation: _nightModeSlideController,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Transform.translate(
                                offset:
                                    Offset(0, _nightModeSlideAnimation.value),
                                child: GestureDetector(
                                  onTap: () => null,
                                  child: Container(
                                    width: 631,
                                    height: 600,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF262626),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(34),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Ikona ostrzeżenia
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 40, bottom: 30),
                                          child: Icon(
                                            Icons.warning_rounded,
                                            size: 80,
                                            color: Colors.red,
                                          ),
                                        ),
                                        // Tekst ostrzeżenia
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 40),
                                            child: SingleChildScrollView(
                                              child: Text(
                                                LanguageService.translate(
                                                    'night_mode_warning'),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontFamily: 'Roboto',
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Pytanie czy kontynuować
                                        Text(
                                          LanguageService.translate(
                                              'continue_question'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 20,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Przyciski
                                        Padding(
                                          padding: const EdgeInsets.all(30),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed:
                                                      _closeNightModeConfirmation,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.grey[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize:
                                                        const Size(0, 70),
                                                    elevation: 4,
                                                    shadowColor: Colors.black
                                                        .withOpacity(0.2),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    LanguageService.translate(
                                                        'no'),
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: _disableNightMode,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF4CAF50),
                                                    foregroundColor:
                                                        Colors.white,
                                                    minimumSize:
                                                        const Size(0, 70),
                                                    elevation: 8,
                                                    shadowColor: Colors.black
                                                        .withOpacity(0.3),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    LanguageService.translate(
                                                        'yes'),
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
                // PIN overlay - musi być na końcu Stack aby było na górze wszystkich innych nakładek
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
                                        enteredPin = '';
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.025),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int i = 0; i < 4; i++)
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: i < enteredPin.length
                                            ? Colors.white
                                            : Colors.white30,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
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
                                  } else if (index == 11) {
                                    // Przycisk OK - widoczny tylko gdy wprowadzono 4 cyfry
                                    return enteredPin.length == 4
                                        ? ElevatedButton(
                                            onPressed: _verifyPin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text(
                                              'OK',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink();
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
                // Profile Overlay - musi być na samej górze, tuż po PIN overlay
                if (isProfileOverlayVisible)
                  _headerElements.buildProfileOverlay(width: width),
              ],
            ),
          );
        },
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

  Widget _buildMultiroomOverlay({
    required double volumeBarX,
    required double volumeBarWidth,
    required double buttonScale,
    required double verticalOffset,
  }) {
    final fontSize = buttonScale * 29.0;
    final buttonWidth = 153 * buttonScale;
    final buttonHeight = 147 * buttonScale;

    return Positioned(
      bottom: verticalOffset +
          90 * buttonScale +
          130 * buttonScale +
          20, // 20px nad suwakiem głośności
      left: volumeBarX +
          (volumeBarWidth - 410 * buttonScale) /
              2, // Wyśrodkowanie relative do volumeBar z nowym rozmiarem
      child: AnimatedBuilder(
        animation: _multiroomSlideController,
        builder: (context, child) {
          return Opacity(
            opacity: _multiroomSlideAnimation.value,
            child: Container(
              width: 410 * buttonScale, // Zwiększony rozmiar do 410px (+50px)
              height: 240 * buttonScale, // Zwiększona wysokość do 240px (+50px)
              padding: EdgeInsets.all(15 * buttonScale),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(30, 30, 30, 0.95),
                borderRadius: BorderRadius.circular(28.39 * buttonScale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nagłówek z przyciskiem zamknięcia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize * 0.6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _closeMultiroomOverlay,
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20 * buttonScale,
                        ),
                      ),
                    ],
                  ),
                  // Przyciski multiroom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Przycisk Mesa
                      GestureDetector(
                        onTap: () {
                          _playClickSound();
                          setState(() {
                            isMessActive =
                                !isMessActive; // Toggle zamiast wyłącznego wyboru
                          });
                          // Wyślij komendę MQTT dla Mesa (device ID 7)
                          _mqttService.sendCommand(7, isMessActive ? 1 : 0);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: buttonWidth,
                              height: buttonHeight,
                              decoration: BoxDecoration(
                                color: isMessActive
                                    ? getInterfaceColor(true)
                                    : getInterfaceColor(false),
                                borderRadius:
                                    BorderRadius.circular(28.39 * buttonScale),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dining,
                                    color: isMessActive
                                        ? getInterfaceIconColor(true)
                                        : getInterfaceIconColor(false),
                                    size: 45 * buttonScale,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                height: 6 *
                                    buttonScale), // Odstęp jak w przyciskach oświetlenia
                            Text(
                              'Mesa',
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
                      // Przycisk Mostek
                      GestureDetector(
                        onTap: () {
                          _playClickSound();
                          setState(() {
                            isBridgeActive =
                                !isBridgeActive; // Toggle zamiast wyłącznego wyboru
                          });
                          // Wyślij komendę MQTT dla Mostek (device ID 8)
                          _mqttService.sendCommand(8, isBridgeActive ? 1 : 0);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: buttonWidth,
                              height: buttonHeight,
                              decoration: BoxDecoration(
                                color: isBridgeActive
                                    ? getInterfaceColor(true)
                                    : getInterfaceColor(false),
                                borderRadius:
                                    BorderRadius.circular(28.39 * buttonScale),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_boat,
                                    color: isBridgeActive
                                        ? getInterfaceIconColor(true)
                                        : getInterfaceIconColor(false),
                                    size: 45 * buttonScale,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                                height: 6 *
                                    buttonScale), // Odstęp jak w przyciskach oświetlenia
                            Text(
                              'Mostek',
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
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
