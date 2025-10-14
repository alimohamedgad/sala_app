import 'package:flutter/material.dart';

import 'in_app_webview_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InAppWebViewScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffbc9d61),
      body: Center(
        child: ClipOval(
          // borderRadius:   BorderRadius.circular(100),
          child: Image.asset(
            'assets/logo_new.png',
            // fit: BoxFit.cover,
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}
