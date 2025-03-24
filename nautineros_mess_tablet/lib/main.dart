import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Ustawienie aplikacji na pełny ekran
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Ustawienie stałej orientacji na poziomą
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

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) => _getTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    // Obliczenia dla odpowiedniego rozmieszczenia prostokątów
    const double rightPanelTop = 886.0;
    const double rightPanelHeight = 130.0;
    const double rightPanelWidth = 577.0; // Szerokość paska po prawej
    const double rightPanelLeft =
        1305.0; // Pozycja lewej krawędzi paska po prawej
    const double rightPanelBottom = rightPanelTop + rightPanelHeight; // 1016

    const double firstBoxTop = 199.0; // Górna krawędź prostokąta "Baterie"
    const double spacing = 15.0; // Odstęp między prostokątami

    // Obliczamy wysokość dwóch pierwszych prostokątów plus odstępy
    const double firstBoxHeight = 310.0;
    const double secondBoxHeight = 215.0;

    // Nowa wysokość trzeciego prostokąta, aby zrównać z dolną krawędzią paska
    final double thirdBoxHeight =
        rightPanelBottom -
        (firstBoxTop + firstBoxHeight + secondBoxHeight + spacing * 2);

    // Wymiary i pozycja siatki przycisków
    const double buttonGridWidth =
        rightPanelWidth; // Taka sama szerokość jak pasek po prawej
    final double buttonGridHeight =
        firstBoxTop; // Wysokość do górnej krawędzi prostokąta "Baterie"
    const double buttonGridLeft =
        rightPanelLeft; // Ta sama pozycja pozioma co pasek po prawej
    const double buttonGridTop = 34.0; // Ta sama wysokość co zegar

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
              // Zegar
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
                        height: 41 / 48, // line-height jako stosunek
                        letterSpacing: -0.4,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Temperatura - symetrycznie względem zegara
              Positioned(
                right: 1220, // Symetrycznie do lewej strony zegara
                top: 34, // Ta sama wysokość co zegar
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
              // Siatka przycisków 2x2
              Positioned(
                left: buttonGridLeft,
                top: buttonGridTop,
                child: SizedBox(
                  width: buttonGridWidth,
                  height: buttonGridHeight - buttonGridTop,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLightButton("Oświetlenie 1"),
                          _buildLightButton("Oświetlenie 2"),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ), // Dodaje odstęp między rzędami
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLightButton("Oświetlenie 3"),
                          _buildLightButton("Oświetlenie 4"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Prostokąt z nagłówkiem "Baterie"
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
                              height: 1.0, // line-height: 100%
                              letterSpacing: 0, // letter-spacing: 0%
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Prostokąt "Zbiorniki"
              Positioned(
                left: 79,
                top:
                    firstBoxTop +
                    firstBoxHeight +
                    spacing, // 199 + 310 + 15 = 524
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
                              fontSize:
                                  22.96, // Używam tego samego rozmiaru jak w "Baterie" dla spójności
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
              // Trzeci prostokąt
              Positioned(
                left: 79,
                top:
                    firstBoxTop +
                    firstBoxHeight +
                    secondBoxHeight +
                    spacing * 2, // 199 + 310 + 215 + 30 = 754
                child: Container(
                  width: 540,
                  height:
                      thirdBoxHeight, // Nowa wysokość, aby zrównać z dolną krawędzią paska
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
                          width:
                              350, // Zwiększona szerokość ze względu na dłuższy tekst
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
              // Dolny kontener po prawej
              Positioned(
                left: 1305,
                top: rightPanelTop,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      width: 577,
                      height: 130,
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
                      child: Row(
                        children: const [
                          // Tutaj można dodać zawartość kontenera
                          // Ustawiam gap: 27px między elementami
                          SizedBox(width: 27), // gap między elementami
                        ],
                      ),
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

  // Funkcja pomocnicza do tworzenia przycisków oświetlenia
  Widget _buildLightButton(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 185.23, // Zaktualizowana szerokość
          height: 177.38, // Zaktualizowana wysokość
          decoration: BoxDecoration(
            color: const Color.fromRGBO(100, 210, 255, 0.2),
            borderRadius: BorderRadius.circular(
              23.55,
            ), // Zaktualizowane zaokrąglenie
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
              borderRadius: BorderRadius.circular(
                23.55,
              ), // Również zaktualizowane tu
              onTap: () {
                // Logika obsługi przycisku
              },
              child: const Center(
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 40, // Zwiększony rozmiar ikony dla lepszych proporcji
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
}
