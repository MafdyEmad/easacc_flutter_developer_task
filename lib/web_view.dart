import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Webview extends StatefulWidget {
  final String link;
  const Webview({super.key, required this.link});

  @override
  State<Webview> createState() => _WebviewState();
}

class _WebviewState extends State<Webview> {
  late final WebViewController controller;
  bool hasError = false;
  @override
  void initState() {
    try {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..loadRequest(Uri.parse(widget.link));
    } catch (e) {
      hasError = true;
      setState(() {});
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: !hasError
          ? WebViewWidget(controller: controller)
          : const Center(
              child: Text(
                "An error occurred",
                style: TextStyle(fontSize: 20),
              ),
            ),
    );
  }
}
