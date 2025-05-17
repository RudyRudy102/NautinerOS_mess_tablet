import 'package:flutter/material.dart';

class FallbackWebView extends StatelessWidget {
  final VoidCallback onRetry;

  const FallbackWebView({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.web,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Widok webowy jest niedostępny',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Wystąpił problem z przeglądarką. Możesz spróbować ponownie.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}
