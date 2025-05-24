import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/weather_model.dart';
import 'services/language_service.dart';
import 'services/volumio_service.dart';

class WidgetPanels {
  // Parametry potrzebne do działania widgetów
  final String currentAlbumArt;
  final String currentSongTitle;
  final String currentSongArtist;
  final bool isPlaying;
  final VolumioService volumioService;
  final Function getFullAlbumArtUrl;
  final Widget Function() buildDefaultAlbumArt;
  final VoidCallback togglePlayPause;
  final VoidCallback previousTrack;
  final VoidCallback nextTrack;

  // Parametry pogodowe
  final WeatherModel? weatherData;
  final bool isLoadingWeather;
  final bool weatherError;
  final bool showWindInBft;
  final VoidCallback fetchWeatherData;
  final Function(bool) setShowWindInBft;

  // Parametry WebView
  final WebViewController? webViewController;
  final bool webViewError;
  final bool isWebViewLoading;
  final VoidCallback initializeWebView;

  // Parametry interfejsu
  final bool syncInterfaceColor;
  final Color Function(bool) getInterfaceIconColor;

  const WidgetPanels({
    required this.currentAlbumArt,
    required this.currentSongTitle,
    required this.currentSongArtist,
    required this.isPlaying,
    required this.volumioService,
    required this.getFullAlbumArtUrl,
    required this.buildDefaultAlbumArt,
    required this.togglePlayPause,
    required this.previousTrack,
    required this.nextTrack,
    required this.weatherData,
    required this.isLoadingWeather,
    required this.weatherError,
    required this.showWindInBft,
    required this.fetchWeatherData,
    required this.setShowWindInBft,
    required this.webViewController,
    required this.webViewError,
    required this.isWebViewLoading,
    required this.initializeWebView,
    required this.syncInterfaceColor,
    required this.getInterfaceIconColor,
  });

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
                      getFullAlbumArtUrl(currentAlbumArt),
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
                            getFullAlbumArtUrl(currentAlbumArt),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading album art: $error');
                              return buildDefaultAlbumArt();
                            },
                          )
                        : buildDefaultAlbumArt(),
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
                                onPressed: fetchWeatherData,
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
            setShowWindInBft(!showWindInBft);
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
            setShowWindInBft(!showWindInBft);
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
                                onPressed: initializeWebView,
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
}
