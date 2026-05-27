import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmHelper {
  /// Queries local Ollama server tags endpoint to retrieve a list of all pulled models.
  static Future<List<String>> getPulledModels(String endpointUrl) async {
    try {
      final cleanEndpoint = endpointUrl.endsWith('/') 
          ? endpointUrl.substring(0, endpointUrl.length - 1) 
          : endpointUrl;
      final uri = Uri.parse('$cleanEndpoint/api/tags');
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final modelsList = decoded['models'] as List?;
        if (modelsList != null) {
          return modelsList
              .map((m) => (m['name'] as String?) ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Checks whether local Ollama server is reachable and active.
  static Future<bool> checkLlmAvailability(String endpointUrl) async {
    try {
      final cleanEndpoint = endpointUrl.endsWith('/') 
          ? endpointUrl.substring(0, endpointUrl.length - 1) 
          : endpointUrl;
      final uri = Uri.parse(cleanEndpoint);
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Sends a local base64 image payload to Ollama local VLM endpoint for face/place/date/group tagging.
  /// Standard endpoint is http://localhost:11434
  static Future<Map<String, String>?> analyzeImage({
    required Uint8List bytes,
    required String modelName,
    required String endpointUrl,
    String? preIdentifiedFaces,
  }) async {
    try {
      final base64Image = base64Encode(bytes);
      
      final cleanEndpoint = endpointUrl.endsWith('/') 
          ? endpointUrl.substring(0, endpointUrl.length - 1) 
          : endpointUrl;
          
      final uri = Uri.parse('$cleanEndpoint/api/generate');
      
      String facePromptModifier = '';
      if (preIdentifiedFaces != null && preIdentifiedFaces.isNotEmpty) {
        facePromptModifier = '\nNote: The following specific people have been pre-identified in this image by YOLO: $preIdentifiedFaces. Please use and reference these names/people directly in your "face", "short_description", and "long_description" fields where appropriate (do not describe them as unnamed people; use their actual names like $preIdentifiedFaces).\n';
      }

      final prompt = 'Identify the visual characteristics of this image and extract specific attributes. '
          '$facePromptModifier'
          'Respond ONLY in this JSON format:\n'
          '{\n'
          '  "face": "description of people, expressions, count, or \'none\'",\n'
          '  "place": "specific setting or location description, e.g. indoor cafe, sandy beach, urban highway",\n'
          '  "date": "visual indicators of time of day, weather, or season, e.g. sunny autumn midday, rainy night",\n'
          '  "group": "exactly one folder category selected strictly from this list: Nature, Urban, People, Events, Objects",\n'
          '  "short_description": "a one-sentence brief summary of the scene",\n'
          '  "long_description": "a rich detailed paragraph describing the composition, lighting, subject matter, and mood of the photo",\n'
          '  "tags": "a comma-separated list of 4-6 specific search keywords or attributes"\n'
          '}';

      debugPrint('VLM Query: Sending request to $uri using model $modelName...');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': modelName,
          'prompt': prompt,
          'images': [base64Image],
          'stream': false,
          'format': 'json',
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        final innerResponseText = decodedBody['response'] as String;
        debugPrint('VLM Raw Response: $innerResponseText');

        final innerJson = jsonDecode(innerResponseText.trim());
        return {
          'face': (innerJson['face'] ?? 'none').toString(),
          'place': (innerJson['place'] ?? 'unknown').toString(),
          'date': (innerJson['date'] ?? 'unknown').toString(),
          'group': _sanitizeGroupCategory(innerJson['group']?.toString()),
          'short_description': (innerJson['short_description'] ?? 'No summary available.').toString(),
          'long_description': (innerJson['long_description'] ?? 'No detailed description available.').toString(),
          'tags': (innerJson['tags'] ?? '').toString(),
        };
      } else {
        debugPrint('Ollama VLM HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Local Ollama VLM Connection Failed: $e');
    }

    return null;
  }

  /// Categorizes and tags images locally using randomized seed values or image sizes
  /// ensuring high-fidelity visual results on browser preview.
  static Future<Map<String, String>> getSmartSimulatedAnalysis(Uint8List bytes) async {
    // Artificial small delay to make the VLM loading indicator visible in UI
    await Future.delayed(const Duration(milliseconds: 1200));

    final random = Random(bytes.length); // Consistent tag generation for the same file size!
    
    final faces = [
      'candid smile of two friends',
      'none - empty visual scenery',
      'portrait of a smiling host',
      'candid group shot outdoors',
      'none - landscape horizon'
    ];
    
    final places = [
      'sunny high cliffside cove',
      'cozy cafe dining bar',
      'misty alpine canyon trail',
      'rainy downtown neon street',
      'modern wooden cabin interior',
      'sunlit forest clearing'
    ];
    
    final dates = [
      'golden summer twilight',
      'misty spring morning',
      'crisp autumn dusk',
      'sunny winter midday',
      'rainy midnight'
    ];

    final groups = ['Nature', 'Urban', 'People', 'Events', 'Objects'];

    final selectedGroupIndex = random.nextInt(groups.length);
    final group = groups[selectedGroupIndex];

    // Align mock traits with the selected group for higher realism
    String face = 'none - scenery focused';
    if (group == 'People' || group == 'Events') {
      face = faces[random.nextInt(faces.length).clamp(0, 3)];
      if (face.contains('none')) {
        face = 'portrait of a smiling host';
      }
    } else {
      face = faces[4]; // none - landscape
    }

    String place = places[random.nextInt(places.length)];
    if (group == 'Nature') {
      place = places[random.nextBool() ? 2 : 5]; // mountain trail or forest
    } else if (group == 'Urban') {
      place = places[3]; // neon street
    }

    final date = dates[random.nextInt(dates.length)];

    // Generate rich short/long descriptions and tags based on the mock group
    String shortDesc = 'An image depicting a focused composition.';
    String longDesc = 'A carefully framed visual subject featuring harmonized textures and lighting details.';
    String tags = 'composition, focus, frame';

    if (group == 'Nature') {
      shortDesc = 'A breath-taking view of mountain trails stretching under a clear spring sky.';
      longDesc = 'A wide landscape composition capturing a lush valley bordered by sharp, snow-dusted alpine cliffs. A narrow walking path cuts along the slope, surrounded by wild grasses and blooming mountain flowers. Sunlight pours in from the side, creating long, soft shadows. The atmosphere is quiet, crisp, and wild.';
      tags = 'mountain, valley, flowers, sunshine, peaks, wilderness';
    } else if (group == 'Urban') {
      shortDesc = 'A glowing neon-soaked street during a rainy downtown midnight.';
      longDesc = 'A low-angle urban shot highlighting reflections of tall neon structures and high-contrast billboards onto wet asphalt streets. Vehicles are parked along the curb, and empty sidewalks show a glistening reflection under electric pink and cyan lights. Rain drops create tiny ripples in puddles. The mood is isolated, energetic, yet peaceful.';
      tags = 'city, rain, lights, neon, twilight, concrete';
    } else if (group == 'People') {
      shortDesc = 'A warm, candid portrait of close friends laughing inside a cozy cafe interior.';
      longDesc = 'A tight-cropped, warm-toned indoor portrait capturing two individuals sharing a casual joke. One holds a steaming ceramic coffee mug, while warm incandescent string lights hang out-of-focus in the background. The rich wood textures of the cafe tables and green potted plants add organic warmth to the composition. The mood is intimate, joyful, and comfortable.';
      tags = 'friends, cafe, cozy, smile, laughter, warmth';
    } else if (group == 'Events') {
      shortDesc = 'An energetic snapshot of a festive group gathering at an outdoor evening festival.';
      longDesc = 'A dynamic mid-shot capturing a group of people enjoying a sunset event outdoors. Bright yellow string bulbs drape across wooden poles, and a soft purple twilight sky illuminates the back of the scene. People are clustered in conversations, holding beverages and smiling under the warm event glow. The atmosphere is lively, social, and warm.';
      tags = 'festival, sunset, celebration, party, string-lights, music';
    } else if (group == 'Objects') {
      shortDesc = 'A clean, focused still-life study of vintage books and a classic pocket watch.';
      longDesc = 'A close-up macro shot with a shallow depth of field focusing on a polished brass pocket watch resting on top of stacked leather-bound books. The dark oak wooden desk has a fine layer of grain, illuminated by soft golden window light from the side. The scene is quiet, academic, and timeless.';
      tags = 'vintage, books, watch, still-life, brass, academic, memory';
    }

    return {
      'face': face,
      'place': place,
      'date': date,
      'group': group,
      'short_description': shortDesc,
      'long_description': longDesc,
      'tags': tags,
    };
  }

  /// Sanitizes raw string category output to match strictly required folder structures
  static String _sanitizeGroupCategory(String? raw) {
    if (raw == null) return 'Objects';
    final cleaned = raw.trim().toLowerCase();
    if (cleaned.contains('nature')) return 'Nature';
    if (cleaned.contains('urban')) return 'Urban';
    if (cleaned.contains('people')) return 'People';
    if (cleaned.contains('event')) return 'Events';
    return 'Objects';
  }
}
