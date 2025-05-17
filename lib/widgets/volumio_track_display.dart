import 'package:flutter/material.dart';

class VolumioTrackDisplay extends StatelessWidget {
  final String? trackTitle;

  const VolumioTrackDisplay({
    Key? key,
    this.trackTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      trackTitle ?? 'Brak odtwarzania',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
