import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({super.key});

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  InAppWebViewController? webViewController;
  String baseUrl = "https://noor-digital.com";

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
        body: SafeArea(
          child: ValueListenableBuilder<bool>(
            valueListenable: hasInternetNotifier,
            builder: (context, hasInternet, child) {
              return hasInternet
                  ? Stack(
                      children: [
                        InAppWebView(
                          initialUrlRequest: URLRequest(url: WebUri(baseUrl)),
                          initialSettings: InAppWebViewSettings(
                            allowsInlineMediaPlayback: true,
                            transparentBackground: true,
                            javaScriptEnabled: true,
                            mediaPlaybackRequiresUserGesture: false,
                            underPageBackgroundColor: const Color(0xff34b4a6),
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
                            final scheme = navigationAction.request.url?.scheme
                                    ?.toLowerCase() ??
                                '';

                            // 1. السماح للروابط الأساسية والداخلية (بوابات الدفع، ديالوج، سكريبتات) بالفتح داخل التطبيق
                            if ([
                              'http',
                              'https',
                              'about',
                              'data',
                              'javascript',
                              'blob',
                              ''
                            ].contains(scheme)) {
                              return NavigationActionPolicy.ALLOW;
                            }

                            // 2. إذا كان رابط لتطبيق آخر (واتساب، اتصال، إيميل)، افتحه في الهاتف الخارجي
                            final opened = await _tryOpenUrl(url);

                            // 3. إظهار رسالة الخطأ فقط إذا كان المستخدم هو من ضغط على الرابط (ليس رابطاً مخفياً في الخلفية)
                            if (!opened && navigationAction.isForMainFrame) {
                              _showSnackBar(
                                  "⚠️ التطبيق المطلوب غير مثبت أو الرابط غير صالح");
                            }

                            return NavigationActionPolicy.CANCEL;
                          },
                          onLoadStart: (controller, url) {
                            // تم إيقافها حتى لا تظهر شاشة التحميل مع كل تنقل داخل الموقع
                            // isLoadingNotifier.value = true;
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
                                error.type ==
                                    WebResourceErrorType.HOST_LOOKUP ||
                                error.type ==
                                    WebResourceErrorType.CONNECTION_ABORTED ||
                                error.type ==
                                    WebResourceErrorType
                                        .NETWORK_CONNECTION_LOST) {
                              hasInternetNotifier.value = false;
                            }
                          },
                          onPermissionRequest: (controller, request) async {
                            final grantedResources = <PermissionResourceType>[];

                            for (final resource in request.resources) {
                              if (resource == PermissionResourceType.CAMERA) {
                                final status =
                                    await Permission.camera.request();
                                if (status.isGranted) {
                                  grantedResources.add(resource);
                                }
                              } else if (resource ==
                                  PermissionResourceType.MICROPHONE) {
                                final status =
                                    await Permission.microphone.request();
                                if (status.isGranted) {
                                  grantedResources.add(resource);
                                }
                              } else {
                                grantedResources.add(resource);
                              }
                            }

                            return PermissionResponse(
                              resources: grantedResources,
                              action: grantedResources.isNotEmpty
                                  ? PermissionResponseAction.GRANT
                                  : PermissionResponseAction.DENY,
                            );
                          },
                        ),
                        loadingWidget(),
                      ],
                    )
                  : _noInternetWidget();
            },
          ),
        ),
      ),
    );
  }

  ValueListenableBuilder<bool> loadingWidget() {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xfff0faf9), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff34b4a6).withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xff34b4a6).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xff34b4a6),
                      strokeWidth: 3.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "مرحباً بكم في منصة نور الرقمية",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff34b4a6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "جاري التحميل...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2d2d2d),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "يرجى الانتظار بضع ثوانٍ...",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _noInternetWidget() {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff1e1b18),
              Color(0xff0f0e0d),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xffbc9d61).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffbc9d61).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffbc9d61).withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 80,
                      color: Color(0xffbc9d61),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "لا يوجد اتصال بالإنترنت",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "يرجى التحقق من اتصال شبكة Wi-Fi أو بيانات الهاتف ومحاولة إعادة الاتصال.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xffd4b26f),
                          Color(0xffbc9d61),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffbc9d61).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await _checkInternetOnStart();
                          if (!mounted) return;
                          if (hasInternetNotifier.value) {
                            webViewController?.loadUrl(
                              urlRequest: URLRequest(url: WebUri(baseUrl)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      "عذراً، ما زال لا يوجد اتصال بالإنترنت",
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xffbc9d61),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                color: Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "إعادة المحاولة",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
