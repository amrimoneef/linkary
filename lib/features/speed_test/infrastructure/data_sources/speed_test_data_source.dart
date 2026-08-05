import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;

class SpeedTestDataSource {
  final http.Client client;

  SpeedTestDataSource({required this.client});

  Future<int> measurePing() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Try Cloudflare first
      final response = await client.get(
        Uri.parse('https://1.1.1.1/cdn-cgi/trace'),
      ).timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds;
      }
    } catch (e) {
      // Fallback to Google if Cloudflare fails
      try {
        stopwatch.reset();
        stopwatch.start();
        final response = await client.get(
          Uri.parse('https://www.google.com/generate_204'),
        ).timeout(const Duration(seconds: 5));
        
        stopwatch.stop();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return stopwatch.elapsedMilliseconds;
        }
      } catch (e2) {
        // Both failed
      }
    }
    return -1; // -1 indicates failure
  }

  /// يرجع بث (Stream) من السرعة الحالية (Mbps) والنسبة المئوية للاكتمال
  Stream<Map<String, dynamic>> testDownloadSpeed() async* {
    // 25 MB file for testing
    final url = Uri.parse('https://speed.cloudflare.com/__down?bytes=25000000');
    final request = http.Request('GET', url);
    
    http.StreamedResponse? response;
    try {
      response = await client.send(request).timeout(const Duration(seconds: 10));
    } catch (e) {
      yield {'speed': 0.0, 'progress': 1.0, 'error': true};
      return;
    }

    if (response.statusCode != 200) {
      yield {'speed': 0.0, 'progress': 1.0, 'error': true};
      return;
    }

    final totalBytes = response.contentLength ?? 25000000;
    int downloadedBytes = 0;
    
    final stopwatch = Stopwatch()..start();
    DateTime lastEmit = DateTime.now();
    int lastEmitBytes = 0;

    await for (final chunk in response.stream) {
      downloadedBytes += chunk.length;
      
      final now = DateTime.now();
      if (now.difference(lastEmit).inMilliseconds > 200 || downloadedBytes == totalBytes) {
        final elapsedSeconds = max(0.001, stopwatch.elapsedMilliseconds / 1000.0);
        
        // Speed in Mbps (Megabits per second)
        // (Bytes * 8) / 1,000,000 = Megabits
        final double currentSpeedMbps = (downloadedBytes * 8) / 1000000.0 / elapsedSeconds;
        
        // Progress 0.0 to 1.0
        final progress = min(1.0, downloadedBytes / totalBytes);
        
        yield {
          'speed': currentSpeedMbps,
          'progress': progress,
          'error': false,
        };
        
        lastEmit = now;
        lastEmitBytes = downloadedBytes;
      }
      
      // Safety timeout after 15 seconds max test time
      if (stopwatch.elapsedMilliseconds > 15000) {
        break;
      }
    }
    
    stopwatch.stop();
    // Final emission ensures progress reaches 1.0 if stopped by timeout
    yield {'speed': (downloadedBytes * 8) / 1000000.0 / (stopwatch.elapsedMilliseconds / 1000.0), 'progress': 1.0, 'error': false};
  }

  Stream<Map<String, dynamic>> testUploadSpeed() async* {
    final url = Uri.parse('https://speed.cloudflare.com/__up');
    final client = http.Client();
    
    // 1MB payload per chunk to allow frequent updates
    const chunkSize = 1000000; 
    final randomData = List<int>.generate(chunkSize, (i) => Random().nextInt(256));

    final stopwatch = Stopwatch()..start();
    int totalUploadedBytes = 0;
    
    // Run for a maximum of 10 seconds
    while (stopwatch.elapsedMilliseconds < 10000) {
      final chunkStopwatch = Stopwatch()..start();
      
      try {
        final request = http.Request('POST', url)
          ..headers['Content-Type'] = 'application/octet-stream'
          ..bodyBytes = randomData;
          
        final response = await client.send(request).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          totalUploadedBytes += chunkSize;
        }
      } catch (e) {
        // Ignore timeouts or errors and continue calculating
      }
      chunkStopwatch.stop();
      
      final elapsedSeconds = max(0.001, stopwatch.elapsedMilliseconds / 1000.0);
      final double currentSpeedMbps = (totalUploadedBytes * 8) / 1000000.0 / elapsedSeconds;
      final progress = min(1.0, stopwatch.elapsedMilliseconds / 10000.0);
      
      yield {
        'speed': currentSpeedMbps,
        'progress': progress,
        'error': false,
      };
    }
    
    stopwatch.stop();
    client.close();
    
    final finalSpeed = (totalUploadedBytes * 8) / 1000000.0 / (stopwatch.elapsedMilliseconds / 1000.0);
    yield {'speed': finalSpeed, 'progress': 1.0, 'error': false};
  }
}
