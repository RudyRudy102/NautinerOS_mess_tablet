import 'package:flutter/material.dart';
import 'models/weather_model.dart';

class HeaderElements {
  // Parametry pogodowe
  final WeatherModel? weatherData;

  // Parametr czasu
  final String currentTime;

  // Parametry profilu
  final String profileCode;
  final bool isProfileOverlayVisible;
  final AnimationController profileSlideController;
  final Animation<double> profileSlideAnimation;

  // Parametry trybu nocnego
  final bool isNightModeActive;
  final Color? nightModeWarningColor;

  // Funkcje callback
  final VoidCallback showLanguageOverlay;
  final VoidCallback showProfileOverlay;
  final VoidCallback closeProfileOverlay;
  final VoidCallback toggleNightMode;
  final VoidCallback playClickSound;
  final Function(int) navigateToPage;

  const HeaderElements({
    required this.weatherData,
    required this.currentTime,
    required this.profileCode,
    required this.isProfileOverlayVisible,
    required this.profileSlideController,
    required this.profileSlideAnimation,
    required this.isNightModeActive,
    required this.nightModeWarningColor,
    required this.showLanguageOverlay,
    required this.showProfileOverlay,
    required this.closeProfileOverlay,
    required this.toggleNightMode,
    required this.playClickSound,
    required this.navigateToPage,
  });

  // Górny pasek z tłem Outline.png
  Widget buildTopBar({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
  }) {
    return Positioned(
      top: verticalOffset,
      left: horizontalOffset,
      child: Container(
        width: 1920 * buttonScale,
        height: 162 * buttonScale,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/Outline.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(),
      ),
    );
  }

  // Przycisk języka
  Widget buildLanguageButton({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
    required double width,
    required double height,
  }) {
    return Positioned(
      top: verticalOffset + height * 0.025,
      left: horizontalOffset + width * 0.015,
      child: GestureDetector(
        onTap: () {
          playClickSound();
          showLanguageOverlay();
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
    );
  }

  // Przycisk profilu
  Widget buildProfileButton({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
    required double width,
    required double height,
  }) {
    return Positioned(
      top: verticalOffset + height * 0.025,
      right: horizontalOffset + width * 0.015,
      child: GestureDetector(
        onTap: () {
          playClickSound();
          showProfileOverlay();
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
    );
  }

  // Overlay profilu
  Widget buildProfileOverlay({
    required double width,
  }) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8), // Półprzezroczyste tło
        child: GestureDetector(
          onTap: closeProfileOverlay, // Zamknij overlay po kliknięciu w tło
          child: AnimatedBuilder(
            animation: profileSlideAnimation,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, profileSlideAnimation.value),
                  child: GestureDetector(
                    onTap: () =>
                        null, // Prevent clicks from passing through to background
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
                      child: Stack(
                        children: [
                          // Przycisk zamknięcia w prawym górnym rogu
                          Positioned(
                            right: 16,
                            top: 16,
                            child: GestureDetector(
                              onTap: closeProfileOverlay,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
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
                            left: 56,
                            right: 56,
                            top: 159,
                            child: Text(
                              profileCode,
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    playClickSound();
                                    closeProfileOverlay();
                                  },
                                  child: Center(
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
    );
  }

  // Ikona pogody
  Widget buildWeatherIcon({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
  }) {
    return Positioned(
      top: verticalOffset + 40 * buttonScale,
      left: horizontalOffset + 520 * buttonScale,
      child: GestureDetector(
        onTap: () {
          playClickSound();
          navigateToPage(1);
        },
        child: Icon(
          weatherData?.getWeatherIcon() ?? Icons.wb_sunny,
          color: weatherData?.getIconColor() ?? Colors.yellow,
          size: 60 * buttonScale,
        ),
      ),
    );
  }

  // Temperatura
  Widget buildTemperatureDisplay({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
  }) {
    return Positioned(
      top: verticalOffset + 40 * buttonScale,
      left: horizontalOffset + 570 * buttonScale,
      child: GestureDetector(
        onTap: () {
          playClickSound();
          navigateToPage(1);
        },
        child: SizedBox(
          width: 130 * buttonScale,
          height: 60 * buttonScale,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: weatherData?.temperature.toStringAsFixed(0) ?? '--',
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
    );
  }

  // Logo
  Widget buildLogo({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
  }) {
    return Positioned(
      top: verticalOffset + 40 * buttonScale,
      left: horizontalOffset + 863 * buttonScale,
      child: Container(
        width: 193.22 * buttonScale,
        height: 83 * buttonScale,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/logo.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // Zegar
  Widget buildClock({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
  }) {
    return Positioned(
      top: verticalOffset + 40 * buttonScale,
      left: horizontalOffset + 1220 * buttonScale,
      child: SizedBox(
        width: 130 * buttonScale,
        height: 60 * buttonScale,
        child: Text(
          currentTime,
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
    );
  }

  // Kompletny górny pasek z wszystkimi elementami
  Widget buildCompleteHeader({
    required double buttonScale,
    required double verticalOffset,
    required double horizontalOffset,
    required double width,
    required double height,
    required double volumeBarX,
    required double volumeBarWidth,
  }) {
    return Stack(
      children: [
        // Górny pasek z tłem
        buildTopBar(
          buttonScale: buttonScale,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
        ),

        // Przycisk języka
        buildLanguageButton(
          buttonScale: buttonScale,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
          width: width,
          height: height,
        ),

        // Przycisk profilu
        buildProfileButton(
          buttonScale: buttonScale,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
          width: width,
          height: height,
        ),

        // Ikona pogody
        buildWeatherIcon(
          buttonScale: buttonScale,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
        ),

        // Temperatura
        buildTemperatureDisplay(
          buttonScale: buttonScale,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
        ),

        // Logo
        buildLogo(
          buttonScale: buttonScale,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
        ),

        // Zegar
        buildClock(
          buttonScale: buttonScale,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
        ),
      ],
    );
  }
}
