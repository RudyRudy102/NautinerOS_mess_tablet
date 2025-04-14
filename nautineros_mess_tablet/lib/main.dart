import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'services/volumio_service.dart';
import 'dart:async';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dodanie trybu debugowania
  if (kDebugMode) {
    debugPrint('Aplikacja uruchomiona w trybie debug');
  }

  // Konfiguracja systemu
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NautinerOS Mess Tablet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const FixedSizeScreen(),
    );
  }
}

class FixedSizeScreen extends StatefulWidget {
  const FixedSizeScreen({super.key});

  @override
  State<FixedSizeScreen> createState() => _FixedSizeScreenState();
}

class _FixedSizeScreenState extends State<FixedSizeScreen> {
  String _timeString = '';
  Timer? _timer;
  bool _isLightOn = true;
  bool _isLightOn1 = true;
  bool _isLightOn2 = true;
  bool _isLightOn3 = true;
  bool _isLightOn4 = true;
  bool _isLightOn5 = true;
  bool _isLightOn6 = true;

  // Media player state
  String currentAlbumArt = '';
  late final PageController _pageController;
  int _currentPage = 0;

  // Add new state variables
  WeatherModel? weatherData;
  bool isLoadingWeather = true;
  bool weatherError = false;
  bool showWindInBft = false;
  final VolumioService _volumioService = VolumioService();
  WebViewController? webViewController;
  bool isWebViewLoading = true;
  bool webViewError = false;
  Timer? _weatherRefreshTimer;
  Timer? _playerUpdateTimer;

  @override
  void initState() {
    super.initState();

    // Dodanie obsługi błędów
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Inicjalizacja pozostałych elementów
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _timeString = _formatDateTime(DateTime.now());
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (Timer timer) => _getTime(),
      );
      _pageController = PageController(initialPage: 0);

      await _initializeWebView();
      await _fetchWeatherData();

      _weatherRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        _fetchWeatherData();
      });

      await _updateVolumiPlayerState();
      _playerUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _updateVolumiPlayerState();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Błąd inicjalizacji aplikacji: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _weatherRefreshTimer?.cancel();
    _playerUpdateTimer?.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _getFullAlbumArtUrl(String art) {
    return art; // Implement your album art URL logic here
  }

  Future<void> _initializeWebView() async {
    try {
      final controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.transparent)
            ..enableZoom(true)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (String url) {
                  setState(() {
                    isWebViewLoading = true;
                    webViewError = false;
                  });
                },
                onPageFinished: (String url) {
                  setState(() {
                    isWebViewLoading = false;
                  });
                },
                onWebResourceError: (WebResourceError error) {
                  setState(() {
                    webViewError = true;
                    isWebViewLoading = false;
                  });
                },
              ),
            )
            ..loadRequest(Uri.parse('https://www.windy.com/?52.248,21.003,5'));

      setState(() {
        webViewController = controller;
      });
    } catch (e) {
      print('Error initializing WebView: $e');
      setState(() {
        webViewError = true;
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      isLoadingWeather = true;
      weatherError = false;
    });

    try {
      final data = await WeatherService.getMockWeatherData();
      setState(() {
        weatherData = data;
        isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        weatherError = true;
        isLoadingWeather = false;
      });
    }
  }

  Future<void> _updateVolumiPlayerState() async {
    try {
      final trackInfo = await _volumioService.getCurrentTrack();
      setState(() {
        currentAlbumArt = trackInfo['albumart'] ?? '';
      });
    } catch (e) {
      print('Error updating player state: $e');
    }
  }

  Widget buildMusicWidget() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text(
            'Odtwarzacz muzyki',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (currentAlbumArt.isNotEmpty)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _getFullAlbumArtUrl(currentAlbumArt),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.music_note,
                      size: 100,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
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
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : weatherError
                    ? // Widok błędu
                    : // Widok pogody
          ),
        ),
      ],
    ),
  );
  }

  Widget buildWebViewWidget() {
    if (isWebViewLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (webViewError) {
      return const Center(
        child: Text(
          'Błąd ładowania mapy',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.39),
      child:
          webViewController != null
              ? WebViewWidget(controller: webViewController!)
              : const Center(
                child: Text(
                  'Ładowanie...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double rightPanelTop = 867.0;
    const double rightPanelHeight = 130.0;
    const double rightPanelWidth = 460.0;
    const double rightPanelLeft = 1422.0;
    const double rightPanelBottom = rightPanelTop + rightPanelHeight;

    const double firstBoxTop = 199.0;
    const double spacing = 15.0;

    const double firstBoxHeight = 310.0;
    const double secondBoxHeight = 215.0;

    final double thirdBoxHeight =
        rightPanelBottom -
        (firstBoxTop + firstBoxHeight + secondBoxHeight + spacing * 2);

    const double buttonWidth = 153.50;
    const double buttonHeight = 147.0;
    const double buttonSpacing = 79.0; // Zmieniony odstęp
    const double rightColumnLeft =
        rightPanelLeft + rightPanelWidth - buttonWidth;

    return Scaffold(
      body: Center(
        child: Container(
          width: 1920,
          height: 1080,
          color: Colors.black,
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'NautinerOS Mess Tablet',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              Positioned(
                left: 690,
                top: 199,
                child: Container(
                  width: 540,
                  height: 798,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(84, 84, 84, 1),
                    borderRadius: BorderRadius.circular(27.88),
                  ),
                  child: PageView(
                    controller: _pageController,
                    children: [
                      buildMusicWidget(),
                      buildWeatherWidget(),
                      buildWebViewWidget(),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 1220,
                top: 34,
                child: Container(
                  width: 130,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _timeString,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 48,
                        height: 41 / 48,
                        letterSpacing: -0.4,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 1220,
                top: 34,
                child: Container(
                  width: 130,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      "20°C",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 48,
                        height: 41 / 48,
                        letterSpacing: -0.4,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                top: firstBoxTop,
                child: Container(
                  width: 540,
                  height: firstBoxHeight,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(84, 84, 84, 1),
                    borderRadius: BorderRadius.circular(27.88),
                  ),
                  child: Stack(
                    children: const [
                      Positioned(
                        left: 41.52,
                        top: 20.99,
                        child: SizedBox(
                          width: 96.94,
                          height: 27.12,
                          child: Text(
                            'Baterie',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 22.96,
                              height: 1.0,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 79,
                top: firstBoxTop + firstBoxHeight + spacing,
                child: Container(
                  width: 540,
                  height: secondBoxHeight,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(84, 84, 84, 1),
                    borderRadius: BorderRadius.circular(27.88),
                  ),
                  child: Stack(
                    children: const [
                      Positioned(
                        left: 29,
                        top: 17,
                        child: SizedBox(
                          width: 175.10,
                          height: 25.01,
                          child: Text(
                            'Zbiorniki',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 22.96,
                              height: 1.0,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 79,
                top:
                    firstBoxTop +
                    firstBoxHeight +
                    secondBoxHeight +
                    spacing * 2,
                child: Container(
                  width: 540,
                  height: thirdBoxHeight,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(84, 84, 84, 1),
                    borderRadius: BorderRadius.circular(27.88),
                  ),
                  child: Stack(
                    children: const [
                      Positioned(
                        left: 29,
                        top: 17,
                        child: SizedBox(
                          width: 350,
                          height: 25.01,
                          child: Text(
                            'Temperatury pom. technicznych',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 22.96,
                              height: 1.0,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: rightPanelLeft,
                top: 199,
                child: _buildLightButton2Content(
                  _isLightOn1,
                  () => setState(() => _isLightOn1 = !_isLightOn1),
                  'Oświetlenie 1',
                ),
              ),
              Positioned(
                left: rightPanelLeft,
                top: 199 + buttonHeight + buttonSpacing,
                child: _buildLightButton2Content(
                  _isLightOn2,
                  () => setState(() => _isLightOn2 = !_isLightOn2),
                  'Oświetlenie 2',
                ),
              ),
              Positioned(
                left: rightPanelLeft,
                top: 199 + (buttonHeight + buttonSpacing) * 2,
                child: _buildLightButton2Content(
                  _isLightOn3,
                  () => setState(() => _isLightOn3 = !_isLightOn3),
                  'Oświetlenie 3',
                ),
              ),
              // Separator między kolumnami przycisków
              Positioned(
                left: 1650,
                top: 228,
                child: Container(width: 1, height: 580, color: Colors.white),
              ),
              Positioned(
                left: rightColumnLeft,
                top: 199,
                child: _buildLightButton2Content(
                  _isLightOn4,
                  () => setState(() => _isLightOn4 = !_isLightOn4),
                  'Oświetlenie 4',
                ),
              ),
              Positioned(
                left: rightColumnLeft,
                top: 199 + buttonHeight + buttonSpacing,
                child: _buildLightButton2Content(
                  _isLightOn5,
                  () => setState(() => _isLightOn5 = !_isLightOn5),
                  'Oświetlenie 5',
                ),
              ),
              Positioned(
                left: rightColumnLeft,
                top: 199 + (buttonHeight + buttonSpacing) * 2,
                child: _buildLightButton2Content(
                  _isLightOn6,
                  () => setState(() => _isLightOn6 = !_isLightOn6),
                  'Oświetlenie 6',
                ),
              ),
              Positioned(
                left: rightPanelLeft,
                top: rightPanelTop,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      width: rightPanelWidth,
                      height: rightPanelHeight,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(100, 210, 255, 0.3),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.25),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(children: const [SizedBox(width: 27)]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightButton(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 185.23,
          height: 177.38,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(100, 210, 255, 0.2),
            borderRadius: BorderRadius.circular(23.55),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(23.55),
              onTap: () {
                // Logika obsługi przycisku
              },
              child: const Center(
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLightButton2Content(
    bool isOn,
    VoidCallback onTap,
    String label,
  ) {
    return Column(
      children: [
        Container(
          width: 153.50,
          height: 147,
          decoration: BoxDecoration(
            color:
                isOn
                    ? const Color.fromRGBO(100, 210, 255, 0.3)
                    : const Color.fromRGBO(161, 161, 161, 0.3),
            borderRadius: BorderRadius.circular(27.88),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(27.88),
              onTap: onTap,
              child: const Center(
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
