import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:media_chronicle/main.dart';
import 'package:media_chronicle/state/app_state.dart';
import 'package:media_chronicle/features/gallery/providers/gallery_provider.dart';
import 'package:media_chronicle/features/stories/providers/stories_provider.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';
import 'package:media_chronicle/features/gallery/providers/yolo_face_provider.dart';
import 'package:media_chronicle/core/utils/postgres_sync_service.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();
  
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => mockImageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([mockImageBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// 1x1 transparent GIF bytes
final List<int> mockImageBytes = [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x21, 0xf9, 0x04, 0x01, 0x00,
  0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
  0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b
];

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('App startup and navigation smoke test', (WidgetTester tester) async {
    // Configure desktop viewport for the test to avoid mobile layout constraints
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    // Build our app under MultiProvider and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => GalleryProvider()),
          ChangeNotifierProvider(create: (_) => YoloFaceProvider()),
          ChangeNotifierProvider(create: (_) => PostgresSyncService()),
          ChangeNotifierProvider(create: (_) => StoriesProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Let the image loader and transition settle
    await tester.pumpAndSettle();

    // Verify that the title dashboard header is present
    expect(find.text('Chronicle Workspace'), findsOneWidget);
    
    // Verify that "Memory Stories" tab exists
    expect(find.text('Memory Stories'), findsOneWidget);
  });
}
