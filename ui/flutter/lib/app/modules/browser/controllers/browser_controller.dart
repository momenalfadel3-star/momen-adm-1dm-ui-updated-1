import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/model/create_task.dart';
import '../../../../api/model/options.dart';
import '../../../../api/model/request.dart';
import '../../../routes/app_pages.dart';
import 'package:dio/dio.dart' as dio;
import 'package:webview_flutter_android/webview_flutter_android.dart';

class BrowserController extends GetxController {
  final _dio = dio.Dio(dio.BaseOptions(
    followRedirects: true,
    maxRedirects: 5,
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final Set<String> _allowNextNav = {};
  final urlText = TextEditingController();
  final progress = 0.0.obs;
  final canBack = false.obs;
  final canForward = false.obs;
  final pageTitle = ''.obs;

  // Tabs (ADM-like)
  final tabsCount = 0.obs;
  final activeTabIndex = 0.obs;

  // UI state (ADM-like options)
  final desktopMode = false.obs;
  final blockImages = false.obs;
  final enableJs = true.obs;
  // Allow opening plain HTTP links (insecure). Does NOT bypass invalid HTTPS certificates.
  final allowHttp = true.obs;
  final allowMixedContent = true.obs;
  final thirdPartyCookies = true.obs;
  final smartDownloadDetect = true.obs;

  final List<_BrowserTab> _tabs = <_BrowserTab>[];

  // Expose tabs and current WebView controller for the view layer
  List<_BrowserTab> get tabs => _tabs;
  _BrowserTab get currentTab => _tabs[activeTabIndex.value];
  WebViewController get web => currentTab.web;


  final _cookies = WebViewCookieManager();

  static const String homeUrl = 'https://www.google.com/';

  static const Set<String> _downloadExts = {
    'zip',
    'apk',
    'pdf',
    'mp4',
    'mkv',
    'mp3',
    'm4a',
    'wav',
    'flac',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    '7z',
    'rar',
    'tar',
    'gz',
    'tgz',
    'iso',
    'exe',
    'msi',
    'dmg',
    'm3u8',
    'torrent',
  };

  @override
  void onInit() {
    super.onInit();

    final initial = (Get.arguments is String && (Get.arguments as String).isNotEmpty)
        ? (Get.arguments as String)
        : homeUrl;

    urlText.text = initial;
    _openNewTab(initialUrl: initial, switchToNew: true);
  }

  @override
  void onClose() {
    urlText.dispose();
    super.onClose();
  }

  Future<void> _updateNavState() async {
    try {
      final c = currentWeb;
      canBack.value = await c.canGoBack();
      canForward.value = await c.canGoForward();
    } catch (_) {
      // ignore
    }
  }

  WebViewController get currentWeb => _tabs[activeTabIndex.value].web;

  int get currentTabId => _tabs[activeTabIndex.value].id;

  void goToInput() {
    final input = urlText.text.trim();
    if (input.isEmpty) return;
    final url = _normalizeUrl(input);
    currentWeb.loadRequest(Uri.parse(url));
  }

  void goHome() {
    urlText.text = homeUrl;
    currentWeb.loadRequest(Uri.parse(homeUrl));
  }

  Future<void> toggleDesktopMode() async {
    desktopMode.toggle();
    for (final t in _tabs) {
      await t.web.setUserAgent(_userAgent());
    }
    await reload();
  }

  Future<void> toggleJavaScript() async {
    enableJs.toggle();
    for (final t in _tabs) {
      await t.web.setJavaScriptMode(enableJs.value ? JavaScriptMode.unrestricted : JavaScriptMode.disabled);
    }
    await reload();
  }

  Future<void> toggleImages() async {
    blockImages.toggle();
    // Inject CSS to hide images (best-effort, like lightweight adblock)
    await _applyContentRules();
    await reload();
  }

  void toggleAllowHttp() {
    allowHttp.toggle();
  }

  void toggleSmartDownload() {
    smartDownloadDetect.toggle();
  }

  void toggleMixedContent() {
    allowMixedContent.toggle();
    // Note: WebView settings for mixed content are usually set during initialization on Android.
    // Changing this might require re-creating the WebView or using platform-specific calls.
    reload();
  }

  void toggleThirdPartyCookies() {
    thirdPartyCookies.toggle();
    // Note: Cookie manager settings are global.
    reload();
  }

  /// Open current address as HTTP (insecure). Useful for sites that don't support TLS.
  void openAsHttp() {
    final u = urlText.text.trim();
    if (u.isEmpty) return;
    try {
      final uri = Uri.parse(u);
      if (uri.hasScheme && uri.scheme == 'http') return;
      final host = uri.host.isNotEmpty ? uri.host : uri.path;
      if (host.isEmpty) return;
      final httpUrl = 'http://$host${uri.hasAuthority ? uri.path : ''}${uri.hasQuery ? '?${uri.query}' : ''}';
      urlText.text = httpUrl;
      currentWeb.loadRequest(Uri.parse(httpUrl));
    } catch (_) {
      // If parse fails, best-effort prefix.
      final httpUrl = u.startsWith('http') ? u : 'http://$u';
      urlText.text = httpUrl;
      currentWeb.loadRequest(Uri.parse(httpUrl));
    }
  }

  Future<void> clearBrowserData() async {
    try {
      for (final t in _tabs) {
        await t.web.clearCache();
      }
      await _cookies.clearCookies();
    } catch (_) {
      // ignore
    }
  }

  Future<void> copyCurrentUrl() async {
    final u = urlText.text.trim();
    if (u.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: u));
    Get.snackbar('Copied', 'Link copied to clipboard');
  }

  String _userAgent() {
    // A03s = Android Chrome UA. Desktop mode swaps to desktop UA.
    if (desktopMode.value) {
      return 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
    }
    return 'Mozilla/5.0 (Linux; Android 13; SM-A037F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
  }

  Future<void> _applyContentRules([WebViewController? controller]) async {
    if (!blockImages.value) return;
    final c = controller ?? currentWeb;
    // Hide images via CSS injection
    const js = """
      (function(){
        try {
          var style = document.getElementById('__gopeed_img_block');
          if(!style){
            style = document.createElement('style');
            style.id='__gopeed_img_block';
            style.innerHTML='img,video,source,picture{display:none !important;}';
            document.head.appendChild(style);
          }
        } catch(e) {}
      })();
    """;
    try {
      await c.runJavaScript(js);
    } catch (_) {
      // ignore
    }
  }

  Future<void> back() async {
    final c = currentWeb;
    if (await c.canGoBack()) {
      await c.goBack();
      await _updateNavState();
    }
  }

  Future<void> forward() async {
    final c = currentWeb;
    if (await c.canGoForward()) {
      await c.goForward();
      await _updateNavState();
    }
  }

  Future<void> reload() async {
    await currentWeb.reload();
  }

  String _normalizeUrl(String input) {
    final s = input.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    // If user typed a domain or words, search via Google.
    if (s.contains(' ') || !s.contains('.')) {
      final q = Uri.encodeComponent(s);
      return 'https://www.google.com/search?q=$q';
    }
    // Default to HTTPS for safety. If user needs HTTP they can use the menu "Open as HTTP".
    return 'https://$s';
  }

  bool _looksLikeDownload(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      final last = path.split('/').last;
      final dot = last.lastIndexOf('.');
      if (dot > 0 && dot < last.length - 1) {
        final ext = last.substring(dot + 1);
        if (_downloadExts.contains(ext)) return true;
      }

      // Common download hints
      final u = url.toLowerCase();
      if (u.contains('download=1') || u.contains('attachment') || u.contains('dl=1')) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  void _openCreate(String url, {String? fileName}) {
    final task = CreateTask(
      req: Request(url: url),
      opt: fileName == null ? null : Options(name: fileName),
    );
    Get.rootDelegate.toNamed(Routes.CREATE, arguments: task);
  }

  String? _filenameFromContentDisposition(String? cd) {
  if (cd == null) return null;
  // attachment; filename="file.zip"
  // attachment; filename*=UTF-8''file%20name.mp4
  final mStar = RegExp(r"filename\*=(?:UTF-8''|utf-8''|)([^;]+)").firstMatch(cd);
  if (mStar != null) {
    var v = mStar.group(1)!.trim();
    v = v.replaceAll(RegExp(r'(^"|"$)'), '');
    try {
      return Uri.decodeFull(v);
    } catch (_) {
      return v;
    }
  }
  final m = RegExp(r'filename=([^;]+)').firstMatch(cd);
  if (m != null) {
    var v = m.group(1)!.trim();
    v = v.replaceAll(RegExp(r'(^"|"$)'), '');
    return v;
  }
  return null;
}

Future<void> _smartCheckAndMaybeDownload(String url) async {
  // Do a light HEAD request to detect "attachment" / filename like ADM.
  try {
    final resp = await _dio.head(
      url,
      options: dio.Options(
        headers: {
          'User-Agent': _userAgent(),
          'Accept': '*/*',
        },
        followRedirects: true,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

    final headers = resp.headers.map;
    final cd = (headers['content-disposition']?.isNotEmpty ?? false) ? headers['content-disposition']!.first : null;
    final ct = (headers['content-type']?.isNotEmpty ?? false) ? headers['content-type']!.first : null;

    final fileName = _filenameFromContentDisposition(cd);
    final looksAttachment = (cd ?? '').toLowerCase().contains('attachment');
    final looksBinary = ct != null &&
        !ct.toLowerCase().contains('text/html') &&
        !ct.toLowerCase().contains('application/xhtml') &&
        !ct.toLowerCase().contains('text/plain');

    if (looksAttachment || fileName != null || looksBinary) {
      _openCreate(url, fileName: fileName);
    } else {
      _allowNextNav.add(url);
      await currentWeb.loadRequest(Uri.parse(url));
    }
  } catch (_) {
    _allowNextNav.add(url);
    await currentWeb.loadRequest(Uri.parse(url));
  }
}

Future<void> _openExternal(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    // ignore
  }
}

// ---------------- Tabs ----------------
  void openTabSwitcher() {
    // UI handled in view. This is a helper for consistency.
  }

  void newTab() => _openNewTab(initialUrl: homeUrl, switchToNew: true);

  void switchToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    activeTabIndex.value = index;
    final tab = _tabs[index];
    urlText.text = tab.url;
    pageTitle.value = tab.title;
    progress.value = tab.progress;
    _updateNavState();
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) return; // keep at least one
    if (index < 0 || index >= _tabs.length) return;
    _tabs.removeAt(index);
    tabsCount.value = _tabs.length;
    if (activeTabIndex.value >= _tabs.length) {
      activeTabIndex.value = _tabs.length - 1;
    }
    switchToTab(activeTabIndex.value);
  }

  void _openNewTab({required String initialUrl, required bool switchToNew}) {
    final id = DateTime.now().microsecondsSinceEpoch;
    final tab = _BrowserTab(id: id, url: initialUrl, title: '');
    tab.web = _buildWebControllerForTab(tab);
    _tabs.add(tab);
    tabsCount.value = _tabs.length;
    if (switchToNew) {
      activeTabIndex.value = _tabs.length - 1;
    }
  }

  WebViewController _buildWebControllerForTab(_BrowserTab tab) {
    final c = WebViewController();

    c.setJavaScriptMode(JavaScriptMode.unrestricted);
    c.setBackgroundColor(Colors.transparent);

    c.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          tab.url = url;
          _updateNavState();
        },
        onProgress: (p) {
          tab.progress = p / 100.0;
          update(['browser_progress']);
        },
        onPageFinished: (url) async {
          tab.url = url;
          try {
            final t = await c.getTitle();
            if (t != null && t.isNotEmpty) tab.title = t;
          } catch (_) {}
          _updateNavState();
          update(['browser_toolbar', 'browser_tabs']);
        },
        onNavigationRequest: (req) async {
          final url = req.url;

          if (_allowNextNav.contains(url)) {
            _allowNextNav.remove(url);
            return NavigationDecision.navigate;
          }

          // External schemes
          if (url.startsWith('intent:') ||
              url.startsWith('market:') ||
              url.startsWith('mailto:') ||
              url.startsWith('tel:') ||
              url.startsWith('tg:') ||
              url.startsWith('whatsapp:') ||
              url.startsWith('fb:') ||
              url.startsWith('youtube:')) {
            _openExternal(url);
            return NavigationDecision.prevent;
          }

          if (smartDownloadDetect.value && _looksLikeDownload(url)) {
            await _smartCheckAndMaybeDownload(url);
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        },
      ),
    );

    _applyContentRules(c);

    // Android best-effort tweaks
    try {
      final android = c.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
    } catch (_) {}

    c.loadRequest(Uri.parse(_normalizeUrl(tab.url)));
    return c;
  }

}

class _BrowserTab {
  _BrowserTab({required this.id, required this.url, required this.title});
  final int id;
  String url;
  String title;
  double progress = 0;
  late WebViewController web;
}
