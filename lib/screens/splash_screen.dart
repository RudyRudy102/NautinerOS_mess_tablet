import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                Positioned(
                  left: (width - 550) / 2,
                  top: (height - 235) / 2 - 45,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 550,
                    height: 235,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: (height + 235) / 2 + 40,
                  child: Center(
                    child: Text(
                      'Witaj na pokładzie!',
                      style: TextStyle(
                        fontFamily: 'SourceSansPro',
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: Center(
                    child: Text(
                      'Powered by YachtOS 25 Śniardwy',
                      style: TextStyle(
                        fontFamily: 'SourceSansPro',
                        fontSize: 25,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
