import 'dart:convert'; // For json.encode
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:provider/provider.dart';
import '../providers/mapping_provider.dart';
// '../utils/js_autofill.dart' is not used as per PDR, JS is loaded from assets.

class WebviewScreen extends StatefulWidget {
  final String url;
  WebviewScreen({Key? key, required this.url}) : super(key: key); // Added Key

  @override
  _WebviewScreenState createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  late final WebViewController _controller; // Made final
  bool _isLoadingPage = true; // To show a loading indicator
  bool _hasError = false; // To show an error message

  @override
  void initState() {
    super.initState();

    // Initialize the WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) // Optional: for transparency
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar or state here if needed
            if (kDebugMode) {
              print('WebView is loading (progress : $progress%)');
            }
          },
          onPageStarted: (String url) {
            if (kDebugMode) {
              print('Page started loading: $url');
            }
            setState(() {
              _isLoadingPage = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            if (kDebugMode) {
              print('Page finished loading: $url');
            }
            setState(() {
              _isLoadingPage = false;
            });
            // It's generally better to call _runAutofill from here
            // ensuring the page is fully loaded.
            _runAutofill();
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            }
            setState(() {
              _isLoadingPage = false;
              _hasError = true; // Show an error message
            });
            // Optionally show a dialog or SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading page: ${error.description}')),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            // You can intercept navigation requests here if needed
            // For example, prevent navigation to certain domains
            if (kDebugMode) {
              print('allowing navigation to ${request.url}');
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // Load initial URL
  }

  Future<void> _runAutofill() async {
    // Access provider without listening if it's just for one-off data
    final prov = Provider.of<MappingProvider>(context, listen: false);
    try {
      final rawJsTemplate = await rootBundle.loadString('assets/autofill.js');
      final mappingJsonString = json.encode(prov.mapping.toJson());

      // Replace placeholder ensuring proper escaping for JS string
      final scriptToRun = rawJsTemplate.replaceFirst(
        "'%MAPPING%'", // If %MAPPING% is a string literal in JS
        mappingJsonString
      ).replaceFirst(
        "%MAPPING%", // If %MAPPING% is a direct substitution
        mappingJsonString
      );

      await _controller.runJavaScript(scriptToRun);
      if (kDebugMode) {
        print('Autofill script injected and executed.');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autofill script executed!')),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error running autofill script: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running autofill script: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Autofill'),
        actions: [
          // Example: Add a refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh Page',
          ),
          // Example: Add a button to re-run autofill manually
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: _runAutofill,
            tooltip: 'Run Autofill Script Again',
          )
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoadingPage)
            Center(child: CircularProgressIndicator()),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load the page.',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoadingPage = true; // Attempt to reload
                      });
                      _controller.loadRequest(Uri.parse(widget.url));
                    },
                    child: Text('Try Again'),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
