import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({super.key});

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  InAppWebViewController? webViewController;
  String baseUrl = "https://harm.chat/";

  // استخدام ValueNotifier بدلاً من المتغيرات العادية
  final ValueNotifier<bool> hasInternetNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _checkInternetOnStart();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    // التخلص من الـ ValueNotifier عند إغلاق الشاشة
    hasInternetNotifier.dispose();
    isLoadingNotifier.dispose();
    super.dispose();
  }

  /// فحص الاتصال أول ما التطبيق يفتح
  Future<void> _checkInternetOnStart() async {
    final connectivity = await Connectivity().checkConnectivity();
    hasInternetNotifier.value = connectivity != ConnectivityResult.none;
  }

  /// متابعة الاتصال أثناء الاستخدام
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final connected = result != ConnectivityResult.none;
      if (connected && !hasInternetNotifier.value) {
        webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(baseUrl)),
        );
      }
      hasInternetNotifier.value = connected;
    });
  }

  /// محاولة فتح الروابط الخارجية
  Future<bool> _tryOpenUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return false;

      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return success;
    } catch (_) {
      return false;
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await webViewController?.canGoBack() ?? false) {
          webViewController?.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        // backgroundColor: const Color(0xffbc9d61),
        body: ValueListenableBuilder<bool>(
          valueListenable: hasInternetNotifier,
          builder: (context, hasInternet, child) {
            return hasInternet
                ? Stack(
                    children: [
                      InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(baseUrl)),
                        initialSettings: InAppWebViewSettings(
                          transparentBackground: true,
                          javaScriptEnabled: true,
                          mediaPlaybackRequiresUserGesture: false,
                          underPageBackgroundColor: const Color(0xffbc9d61),
                          useShouldOverrideUrlLoading: true,
                          clearCache: false,
                          allowFileAccessFromFileURLs: true,
                          allowUniversalAccessFromFileURLs: true,
                        ),
                        onWebViewCreated: (controller) {
                          webViewController = controller;
                        },
                        shouldOverrideUrlLoading:
                            (controller, navigationAction) async {
                          final url = navigationAction.request.url.toString();
                          if (url.contains(baseUrl)) {
                            return NavigationActionPolicy.ALLOW;
                          }

                          final opened = await _tryOpenUrl(url);
                          if (!opened) {
                            _showSnackBar("⚠️ الرابط غير صالح");
                          }
                          return NavigationActionPolicy.CANCEL;
                        },
                        onLoadStart: (controller, url) {
                          isLoadingNotifier.value = true;
                        },
                        onLoadStop: (controller, url) async {
                          isLoadingNotifier.value = false;
                        },
                        onReceivedError: (controller, request, error) {
                          // تحقق من نوع الخطأ - فقط أخطاء الاتصال تؤدي إلى تغيير حالة الإنترنت
                          if (error.type ==
                                  WebResourceErrorType
                                      .NOT_CONNECTED_TO_INTERNET ||
                              error.type == WebResourceErrorType.TIMEOUT ||
                              error.type == WebResourceErrorType.HOST_LOOKUP ||
                              error.type ==
                                  WebResourceErrorType.CONNECTION_ABORTED ||
                              error.type ==
                                  WebResourceErrorType
                                      .NETWORK_CONNECTION_LOST) {
                            hasInternetNotifier.value = false;
                          }
                        },
                        onPermissionRequest: (controller, request) async {
                          return PermissionResponse(
                            resources: request.resources,
                            action: PermissionResponseAction.GRANT,
                          );
                        },
                      ),
                    ],
                  )
                : _noInternetWidget();
          },
        ),
      ),
    );
  }

  Widget _noInternetWidget() {
    return Center(
      child: Image.asset(
        'assets/no_internet.jpg',
        fit: BoxFit.fill,
        height: double.infinity,
        width: double.infinity,
      ),
    );
  }
}
