import 'package:flutter/material.dart';
import '../services/modbus_service.dart';

class VolumioTrackDisplay extends StatelessWidget {
  final String? trackTitle;
  final ModbusService modbusService;

  const VolumioTrackDisplay({
    Key? key,
    required this.modbusService,
    this.trackTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: modbusService.stateStream,
      initialData: {
        'volumioConnected': modbusService.isVolumioConnected,
      },
      builder: (context, snapshot) {
        final volumioConnected = snapshot.data?['volumioConnected'] ?? false;

        if (!volumioConnected) {
          // Gdy brak połączenia z Volumio, wyświetl komunikat
          return const Text(
            'Multimedia wyłączone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        // Gdy jest połączenie, wyświetl tytuł utworu lub placeholder
        return Text(
          trackTitle ?? 'Brak odtwarzania',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
