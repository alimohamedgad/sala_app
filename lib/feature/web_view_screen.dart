// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class WebViewScreen extends StatefulWidget {
//   const WebViewScreen({super.key});

//   @override
//   State<WebViewScreen> createState() => _WebViewScreenState();
// }

// class _WebViewScreenState extends State<WebViewScreen> {
//   late final WebViewController _controller;
//   String baseUrl = "https://salaa.net/";
//   bool isLoading = true; // حالة التحميل
//   String? currentUrl; // نحتفظ باللينك الحالي لتجنب إعادة التحميل الوهمي
//   bool hasInternet = true;
//   @override
//   void initState() {
//     super.initState();
//     _checkInternetOnStart();
//     _listenToConnectivity();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0xffbc9d61))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onWebResourceError: (_) {
//             setState(() {
//               hasInternet = false;
//             });
//           },
//           onNavigationRequest: (request) async {
//             // لو اللينك خارجي (مش نفس الموقع الأساسي)
//             final url = request.url;
//             // لو اللينك تابع لموقعك الأساسي → خليه يعدي عادي
//             if (url.contains(baseUrl)) {
//               return NavigationDecision.navigate;
//             }

//             final bool opened = await _tryOpenUrl(url);
//             if (!opened) {
//               _showSnackBar("⚠️ الرابط غير صالح ");
//             }

//             return NavigationDecision.prevent;
//           },
//           // onPageStarted: (url) {
//           //   // لو الصفحة فعلاً اتغيرت
//           //   if (currentUrl != url) {
//           //     setState(() {
//           //       isLoading = true;
//           //     });
//           //   }
//           // },
//           // onPageFinished: (url) {
//           //   setState(() {
//           //     isLoading = false;
//           //     currentUrl = url; // حفظ اللينك الحالي
//           //   });
//           // },
//         ),
//       )
//       ..loadRequest(Uri.parse(baseUrl));
//   }

//   /// دالة تتحقق من صلاحية اللينك

//   Future<bool> _tryOpenUrl(String url) async {
//     try {
//       final uri = Uri.tryParse(url);
//       if (uri == null) return false;

//       final success = await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );
//       return success;
//     } catch (e) {
//       return false;
//     }
//   }

//   void _showSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message, textAlign: TextAlign.center),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: Colors.redAccent,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   Future<void> _checkInternetOnStart() async {
//     final connectivity = await Connectivity().checkConnectivity();
//     setState(() {
//       hasInternet = connectivity != ConnectivityResult.none;
//     });
//     if (hasInternet) {
//       _controller.loadRequest(Uri.parse(baseUrl));
//     }
//   }

//   /// متابعة الاتصال أثناء الاستخدام
//   void _listenToConnectivity() {
//     Connectivity().onConnectivityChanged.listen((result) {
//       final connected = result != ConnectivityResult.none;
//       if (connected && !hasInternet) {
//         // لو رجع النت نحمل الموقع تاني
//         _controller.loadRequest(Uri.parse(baseUrl));
//       }
//       setState(() {
//         hasInternet = connected;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (await _controller.canGoBack()) {
//           await _controller.goBack();
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xffbc9d61),
//         body: hasInternet
//             ? WebViewWidget(controller: _controller)
//             : _noInternetWidget(),
//       ),
//     );
//   }

//   Widget _noInternetWidget() {
//     return Center(
//       child: Image.asset(
//         'assets/no_internet.jpg',
//         fit: BoxFit.fill,
//         height: double.infinity,
//         width: double.infinity, // ضع صورتك هنا
//       ),
//     );
//   }
// }
