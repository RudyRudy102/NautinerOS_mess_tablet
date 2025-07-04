import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'services/language_service.dart';

class SensorPanels {
  // Parametry baterii
  final double battery12VLevel;
  final double battery12VVoltage;
  final double battery24VLevel;
  final double battery24VVoltage;
  final double battery48VLevel;
  final double battery48VVoltage;

  // Parametry zbiorników
  final double cleanWaterLevel;
  final double greyWaterLevel;
  final double blackWaterLevel;
  final double fuelLevel;

  // Parametry temperatur
  final double engineRoomTemp;
  final double chargerTemp;
  final double leftBatteryTemp;
  final double rightBatteryTemp;

  // Funkcja do kolorów interfejsu
  final Color Function(bool) getInterfaceColor;

  const SensorPanels({
    required this.battery12VLevel,
    required this.battery12VVoltage,
    required this.battery24VLevel,
    required this.battery24VVoltage,
    required this.battery48VLevel,
    required this.battery48VVoltage,
    required this.cleanWaterLevel,
    required this.greyWaterLevel,
    required this.blackWaterLevel,
    required this.fuelLevel,
    required this.engineRoomTemp,
    required this.chargerTemp,
    required this.leftBatteryTemp,
    required this.rightBatteryTemp,
    required this.getInterfaceColor,
  });

  // Panel z bateriami
  Widget buildBatteryPanel({
    required double buttonScale,
    required double sideContainerWidth,
    required double batteryContainerHeight,
  }) {
    return Container(
      width: sideContainerWidth,
      height: batteryContainerHeight,
      decoration: ShapeDecoration(
        color: getInterfaceColor(false),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27.88 * buttonScale),
        ),
      ),
      child: Stack(
        children: [
          // Zawartość panelu baterii
          Positioned(
            top: 15 * buttonScale,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                LanguageService.translate('batteries'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28 * buttonScale,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Positioned(
            left: 40 * buttonScale,
            top: 50 * buttonScale,
            child: Container(
              width: sideContainerWidth - 80 * buttonScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildBatteryGauge(
                    title: LanguageService.translate('battery_12v'),
                    level: battery12VLevel,
                    voltage: battery12VVoltage,
                    width: sideContainerWidth - 80 * buttonScale,
                  ),
                  SizedBox(height: 3 * buttonScale),
                  buildBatteryGauge(
                    title: LanguageService.translate('battery_24v'),
                    level: battery24VLevel,
                    voltage: battery24VVoltage,
                    width: sideContainerWidth - 80 * buttonScale,
                  ),
                  SizedBox(height: 3 * buttonScale),
                  buildBatteryGauge(
                    title: LanguageService.translate('battery_48v'),
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
    );
  }

  // Panel ze zbiornikami
  Widget buildTanksPanel({
    required double buttonScale,
    required double sideContainerWidth,
    required double tanksContainerHeight,
  }) {
    return Container(
      width: sideContainerWidth,
      height: tanksContainerHeight,
      decoration: ShapeDecoration(
        color: getInterfaceColor(false),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27.87 * buttonScale),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12 * buttonScale,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                LanguageService.translate('tanks'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25 * buttonScale,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Positioned(
            left: 29 * buttonScale,
            top: 47 * buttonScale,
            child: Container(
              width: 220.14 * buttonScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTankGauge(
                    title: LanguageService.translate('clean_water'),
                    level: cleanWaterLevel,
                    width: 220.22 * buttonScale,
                    gaugeColor: const Color(0xFF64D2FF),
                  ),
                  buildTankGauge(
                    title: LanguageService.translate('grey_water'),
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
            child: Container(
              width: 220.14 * buttonScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTankGauge(
                    title: LanguageService.translate('black_water'),
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
    );
  }

  // Panel z temperaturami
  Widget buildTemperaturePanel({
    required double buttonScale,
    required double sideContainerWidth,
    required double tempContainerHeight,
  }) {
    return Container(
      width: sideContainerWidth,
      height: tempContainerHeight,
      decoration: ShapeDecoration(
        color: getInterfaceColor(false),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27.87 * buttonScale),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12 * buttonScale,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                LanguageService.translate('tech_rooms_temps'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * buttonScale,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Positioned(
            left: 29 * buttonScale,
            top: 47 * buttonScale,
            child: Container(
              width: 220.14 * buttonScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTemperatureGauge(
                    title: LanguageService.translate('engine_room'),
                    temperature: engineRoomTemp,
                    width: 220.22 * buttonScale,
                  ),
                  buildTemperatureGauge(
                    title: LanguageService.translate('charger_room'),
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
            child: Container(
              width: 220.14 * buttonScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTemperatureGauge(
                    title: LanguageService.translate('left_battery'),
                    temperature: leftBatteryTemp,
                    width: 220.22 * buttonScale,
                  ),
                  buildTemperatureGauge(
                    title: LanguageService.translate('right_battery'),
                    temperature: rightBatteryTemp,
                    width: 219.22 * buttonScale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Metoda pomocnicza dla budowania gaugeów zbiorników
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${level.toInt()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
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
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '100',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16.40,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  // Metoda pomocnicza dla budowania gaugeów baterii
  Widget buildBatteryGauge({
    required String title,
    required double level,
    required double voltage,
    required double width,
  }) {
    Color getBatteryColor(double level) {
      if (level >= 40) {
        return const Color(0xFF00FF48); // Zielony od 40%
      } else if (level >= 20) {
        return const Color(0xFFFFA500); // Pomarańczowy między 20-40%
      } else {
        return const Color(0xFFFF0000); // Czerwony od 0-20%
      }
    }

    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.90,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${level.toInt()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25.79,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LanguageService.translate('battery_voltage'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16.41,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${voltage.toStringAsFixed(2)} V',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16.41,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Metoda pomocnicza dla budowania gaugeów temperatury
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
                axisTrackStyle: LinearAxisTrackStyle(
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
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '60°C',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}
