// =============================================
// lib/core/ai/models/ai_models.dart
// =============================================
class DemandPrediction {
  final String productId;
  final double predictedDemand;
  final double confidence;
  final List<String> recommendations;
  final DateTime timestamp;
  
  DemandPrediction({
    required this.productId,
    required this.predictedDemand,
    required this.confidence,
    required this.recommendations,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'predicted_demand': predictedDemand,
    'confidence': confidence,
    'recommendations': recommendations,
    'timestamp': timestamp.toIso8601String(),
  };
}

class PricingSuggestion {
  final String productId;
  final double suggestedPrice;
  final double minPrice;
  final double maxPrice;
  final String reasoning;
  final DateTime timestamp;
  
  PricingSuggestion({
    required this.productId,
    required this.suggestedPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.reasoning,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'suggested_price': suggestedPrice,
    'min_price': minPrice,
    'max_price': maxPrice,
    'reasoning': reasoning,
    'timestamp': timestamp.toIso8601String(),
  };
}

class CropHealthAnalysis {
  final String status;
  final double confidence;
  final List<String> diseases;
  final List<String> suggestions;
  final DateTime timestamp;
  
  CropHealthAnalysis({
    required this.status,
    required this.confidence,
    required this.diseases,
    required this.suggestions,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'status': status,
    'confidence': confidence,
    'diseases': diseases,
    'suggestions': suggestions,
    'timestamp': timestamp.toIso8601String(),
  };
}

class WeatherRecommendation {
  final String location;
  final Map<String, dynamic> weatherData;
  final List<String> recommendations;
  final List<String> warnings;
  final DateTime timestamp;
  
  WeatherRecommendation({
    required this.location,
    required this.weatherData,
    required this.recommendations,
    required this.warnings,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'location': location,
    'weather_data': weatherData,
    'recommendations': recommendations,
    'warnings': warnings,
    'timestamp': timestamp.toIso8601String(),
  };
}

// =============================================
// lib/core/ai/demand_ai_service.dart
// =============================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/http_client.dart';
import '../logging/logger.dart';
import '../constants/app_constants.dart';
import 'models/ai_models.dart';

class DemandAIService {
  final HttpClient _httpClient;
  
  DemandAIService(this._httpClient);
  
  Future<DemandPrediction> predictDemand({
    required String productId,
    required String productName,
    required String category,
    required List<Map<String, dynamic>> historicalData,
  }) async {
    try {
      // Prepare time series data for HuggingFace
      final prompt = _buildDemandPrompt(productName, category, historicalData);
      
      final response = await http.post(
        Uri.parse('${AppConstants.huggingFaceUrl}/models/facebook/bart-large-mnli'),
        headers: {
          'Authorization': 'Bearer ${AppConstants.huggingFaceKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'candidate_labels': ['high_demand', 'medium_demand', 'low_demand'],
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseDemandResponse(productId, data, historicalData);
      } else {
        AppLogger.warning('Demand prediction API failed, using fallback');
        return _fallbackDemandPrediction(productId, historicalData);
      }
    } catch (e, stack) {
      AppLogger.error('Demand prediction failed', error: e, stackTrace: stack);
      return _fallbackDemandPrediction(productId, historicalData);
    }
  }
  
  String _buildDemandPrompt(
    String productName,
    String category,
    List<Map<String, dynamic>> historicalData,
  ) {
    final recentSales = historicalData.take(30).map((d) => d['quantity'] ?? 0).toList();
    final avgSales = recentSales.isEmpty 
        ? 0 
        : recentSales.reduce((a, b) => a + b) / recentSales.length;
    
    return '''
Product: $productName
Category: $category
Average Monthly Sales: ${avgSales.toStringAsFixed(1)} units
Recent Trend: ${_calculateTrend(recentSales)}
Season: ${_getCurrentSeason()}
Market demand for this product is expected to be:
''';
  }
  
  DemandPrediction _parseDemandResponse(
    String productId,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> historicalData,
  ) {
    final scores = data['scores'] as List? ?? [];
    final labels = data['labels'] as List? ?? [];
    
    double predictedDemand = 100.0;
    double confidence = 0.5;
    
    if (scores.isNotEmpty && labels.isNotEmpty) {
      final topLabel = labels[0].toString();
      confidence = scores[0] as double;
      
      if (topLabel.contains('high')) {
        predictedDemand = 150.0;
      } else if (topLabel.contains('medium')) {
        predictedDemand = 100.0;
      } else {
        predictedDemand = 50.0;
      }
    }
    
    // Adjust based on historical data
    if (historicalData.isNotEmpty) {
      final recentAvg = historicalData
          .take(7)
          .map((d) => (d['quantity'] ?? 0).toDouble())
          .reduce((a, b) => a + b) / 7;
      predictedDemand = (predictedDemand + recentAvg) / 2;
    }
    
    final recommendations = _generateRecommendations(predictedDemand, confidence);
    
    return DemandPrediction(
      productId: productId,
      predictedDemand: predictedDemand,
      confidence: confidence,
      recommendations: recommendations,
      timestamp: DateTime.now(),
    );
  }
  
  DemandPrediction _fallbackDemandPrediction(
    String productId,
    List<Map<String, dynamic>> historicalData,
  ) {
    double avgDemand = 100.0;
    
    if (historicalData.isNotEmpty) {
      final quantities = historicalData
          .map((d) => (d['quantity'] ?? 0).toDouble())
          .toList();
      avgDemand = quantities.reduce((a, b) => a + b) / quantities.length;
    }
    
    return DemandPrediction(
      productId: productId,
      predictedDemand: avgDemand * 1.1, // 10% growth assumption
      confidence: 0.6,
      recommendations: [
        'Maintain current stock levels',
        'Monitor market trends closely',
      ],
      timestamp: DateTime.now(),
    );
  }
  
  String _calculateTrend(List<int> sales) {
    if (sales.length < 2) return 'stable';
    final recent = sales.take(7).reduce((a, b) => a + b) / 7;
    final older = sales.skip(7).take(7).reduce((a, b) => a + b) / 7;
    
    if (recent > older * 1.2) return 'increasing';
    if (recent < older * 0.8) return 'decreasing';
    return 'stable';
  }
  
  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'summer';
    if (month >= 6 && month <= 9) return 'monsoon';
    if (month >= 10 && month <= 11) return 'autumn';
    return 'winter';
  }
  
  List<String> _generateRecommendations(double demand, double confidence) {
    final recommendations = <String>[];
    
    if (demand > 120) {
      recommendations.add('High demand expected - increase stock by 30%');
      recommendations.add('Consider premium pricing during peak demand');
    } else if (demand < 80) {
      recommendations.add('Low demand expected - reduce stock to avoid waste');
      recommendations.add('Consider promotional pricing to boost sales');
    } else {
      recommendations.add('Stable demand - maintain current inventory levels');
    }
    
    if (confidence < 0.7) {
      recommendations.add('Prediction confidence is moderate - monitor closely');
    }
    
    return recommendations;
  }
}

// =============================================
// lib/core/ai/pricing_ai_service.dart
// =============================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logging/logger.dart';
import '../constants/app_constants.dart';
import 'models/ai_models.dart';

class PricingAIService {
  Future<PricingSuggestion> suggestPrice({
    required String productId,
    required String productName,
    required double currentPrice,
    required double demandScore,
    required Map<String, dynamic> marketData,
  }) async {
    try {
      final prompt = _buildPricingPrompt(
        productName,
        currentPrice,
        demandScore,
        marketData,
      );
      
      final response = await http.post(
        Uri.parse('${AppConstants.huggingFaceUrl}/models/gpt2'),
        headers: {
          'Authorization': 'Bearer ${AppConstants.huggingFaceKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_length': 100,
            'temperature': 0.7,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        return _parsePricingResponse(productId, currentPrice, demandScore);
      } else {
        return _calculateFallbackPrice(productId, currentPrice, demandScore, marketData);
      }
    } catch (e, stack) {
      AppLogger.error('Price suggestion failed', error: e, stackTrace: stack);
      return _calculateFallbackPrice(productId, currentPrice, demandScore, marketData);
    }
  }
  
  String _buildPricingPrompt(
    String productName,
    double currentPrice,
    double demandScore,
    Map<String, dynamic> marketData,
  ) {
    final competitorAvg = marketData['competitor_avg_price'] ?? currentPrice;
    final seasonalFactor = marketData['seasonal_factor'] ?? 1.0;
    
    return '''
Product: $productName
Current Price: ₹$currentPrice
Market Average: ₹$competitorAvg
Demand Score: ${demandScore.toStringAsFixed(1)}
Seasonal Factor: $seasonalFactor
Optimal pricing recommendation:
''';
  }
  
  PricingSuggestion _parsePricingResponse(
    String productId,
    double currentPrice,
    double demandScore,
  ) {
    // Calculate intelligent price based on demand
    double multiplier = 1.0;
    
    if (demandScore > 120) {
      multiplier = 1.15; // 15% increase for high demand
    } else if (demandScore > 100) {
      multiplier = 1.05; // 5% increase for above average
    } else if (demandScore < 80) {
      multiplier = 0.90; // 10% decrease for low demand
    } else if (demandScore < 100) {
      multiplier = 0.95; // 5% decrease for below average
    }
    
    final suggestedPrice = (currentPrice * multiplier).roundToDouble();
    final minPrice = (currentPrice * 0.85).roundToDouble();
    final maxPrice = (currentPrice * 1.25).roundToDouble();
    
    final reasoning = _generatePricingReasoning(currentPrice, suggestedPrice, demandScore);
    
    return PricingSuggestion(
      productId: productId,
      suggestedPrice: suggestedPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      reasoning: reasoning,
      timestamp: DateTime.now(),
    );
  }
  
  PricingSuggestion _calculateFallbackPrice(
    String productId,
    double currentPrice,
    double demandScore,
    Map<String, dynamic> marketData,
  ) {
    final competitorPrice = marketData['competitor_avg_price'] ?? currentPrice;
    final suggestedPrice = ((currentPrice + competitorPrice) / 2).roundToDouble();
    
    return PricingSuggestion(
      productId: productId,
      suggestedPrice: suggestedPrice,
      minPrice: (suggestedPrice * 0.9).roundToDouble(),
      maxPrice: (suggestedPrice * 1.2).roundToDouble(),
      reasoning: 'Based on market average and current demand trends',
      timestamp: DateTime.now(),
    );
  }
  
  String _generatePricingReasoning(
    double currentPrice,
    double suggestedPrice,
    double demandScore,
  ) {
    final difference = suggestedPrice - currentPrice;
    final percentage = (difference / currentPrice * 100).abs().toStringAsFixed(1);
    
    if (suggestedPrice > currentPrice) {
      return 'Increase price by $percentage% due to high demand (score: ${demandScore.toStringAsFixed(1)}). Market conditions favor premium pricing.';
    } else if (suggestedPrice < currentPrice) {
      return 'Reduce price by $percentage% due to lower demand (score: ${demandScore.toStringAsFixed(1)}). Competitive pricing will help boost sales.';
    } else {
      return 'Maintain current price. Demand is stable and market conditions are balanced.';
    }
  }
}

// =============================================
// lib/core/ai/crop_ai_service.dart
// =============================================
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../logging/logger.dart';
import '../constants/app_constants.dart';
import 'models/ai_models.dart';

class CropAIService {
  Future<CropHealthAnalysis> analyzeCropHealth(Uint8List imageBytes) async {
    try {
      // Use HuggingFace image classification model
      final response = await http.post(
        Uri.parse('${AppConstants.huggingFaceUrl}/models/google/vit-base-patch16-224'),
        headers: {
          'Authorization': 'Bearer ${AppConstants.huggingFaceKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': base64Encode(imageBytes),
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return _parseCropHealthResponse(data);
      } else {
        AppLogger.warning('Crop health analysis failed, using fallback');
        return _fallbackCropHealth();
      }
    } catch (e, stack) {
      AppLogger.error('Crop health analysis failed', error: e, stackTrace: stack);
      return _fallbackCropHealth();
    }
  }
  
  CropHealthAnalysis _parseCropHealthResponse(List data) {
    if (data.isEmpty) return _fallbackCropHealth();
    
    final topPrediction = data[0] as Map<String, dynamic>;
    final label = topPrediction['label'].toString().toLowerCase();
    final score = topPrediction['score'] as double;
    
    String status;
    List<String> diseases = [];
    List<String> suggestions = [];
    
    if (label.contains('healthy') || label.contains('normal')) {
      status = 'Healthy';
      suggestions = [
        'Crop appears healthy',
        'Continue current care routine',
        'Monitor regularly for any changes',
      ];
    } else if (label.contains('disease') || label.contains('infected')) {
      status = 'Diseased';
      diseases = [label];
      suggestions = [
        'Immediate attention required',
        'Consult agricultural expert',
        'Consider organic pesticides',
        'Isolate affected plants',
      ];
    } else if (label.contains('stress') || label.contains('deficiency')) {
      status = 'Stressed';
      suggestions = [
        'Check soil nutrients',
        'Adjust watering schedule',
        'Monitor weather conditions',
      ];
    } else {
      status = 'Needs Attention';
      suggestions = [
        'Further inspection recommended',
        'Monitor plant closely',
      ];
    }
    
    return CropHealthAnalysis(
      status: status,
      confidence: score,
      diseases: diseases,
      suggestions: suggestions,
      timestamp: DateTime.now(),
    );
  }
  
  CropHealthAnalysis _fallbackCropHealth() {
    return CropHealthAnalysis(
      status: 'Analysis Unavailable',
      confidence: 0.0,
      diseases: [],
      suggestions: [
        'Unable to analyze image at this time',
        'Please try again later',
        'Consult local agricultural expert if issues persist',
      ],
      timestamp: DateTime.now(),
    );
  }
}

// =============================================
// lib/core/ai/weather_service.dart
// =============================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logging/logger.dart';
import '../constants/app_constants.dart';
import 'models/ai_models.dart';

class WeatherService {
  Future<WeatherRecommendation> getWeatherRecommendations({
    required double lat,
    required double lng,
    required String location,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.openWeatherUrl}/forecast?lat=$lat&lon=$lng&appid=${AppConstants.openWeatherKey}&units=metric',
        ),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseWeatherData(location, data);
      } else {
        return _fallbackWeatherRecommendation(location);
      }
    } catch (e, stack) {
      AppLogger.error('Weather fetch failed', error: e, stackTrace: stack);
      return _fallbackWeatherRecommendation(location);
    }
  }
  
  WeatherRecommendation _parseWeatherData(
    String location,
    Map<String, dynamic> data,
  ) {
    final list = data['list'] as List? ?? [];
    if (list.isEmpty) return _fallbackWeatherRecommendation(location);
    
    final current = list[0] as Map<String, dynamic>;
    final main = current['main'] as Map<String, dynamic>;
    final weather = (current['weather'] as List)[0] as Map<String, dynamic>;
    
    final temp = main['temp'] as double;
    final humidity = main['humidity'] as int;
    final weatherMain = weather['main'].toString();
    
    final weatherData = {
      'temperature': temp,
      'humidity': humidity,
      'condition': weatherMain,
      'description': weather['description'],
    };
    
    final recommendations = _generateWeatherRecommendations(
      temp,
      humidity,
      weatherMain,
    );
    
    final warnings = _generateWeatherWarnings(temp, humidity, weatherMain);
    
    return WeatherRecommendation(
      location: location,
      weatherData: weatherData,
      recommendations: recommendations,
      warnings: warnings,
      timestamp: DateTime.now(),
    );
  }
  
  List<String> _generateWeatherRecommendations(
    double temp,
    int humidity,
    String condition,
  ) {
    final recommendations = <String>[];
    
    if (condition.toLowerCase().contains('rain')) {
      recommendations.addAll([
        'Postpone irrigation activities',
        'Ensure proper drainage in fields',
        'Cover sensitive crops if possible',
      ]);
    }
    
    if (temp > 35) {
      recommendations.addAll([
        'Increase irrigation frequency',
        'Provide shade for sensitive crops',
        'Harvest early morning or evening',
      ]);
    } else if (temp < 10) {
      recommendations.addAll([
        'Protect crops from frost',
        'Use mulching to retain soil warmth',
        'Delay planting if possible',
      ]);
    }
    
    if (humidity > 80) {
      recommendations.add('Monitor for fungal diseases');
      recommendations.add('Ensure good air circulation');
    } else if (humidity < 40) {
      recommendations.add('Increase irrigation');
      recommendations.add('Use mulch to retain moisture');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Weather conditions are favorable');
      recommendations.add('Continue normal farming activities');
    }
    
    return recommendations;
  }
  
  List<String> _generateWeatherWarnings(
    double temp,
    int humidity,
    String condition,
  ) {
    final warnings = <String>[];
    
    if (condition.toLowerCase().contains('storm') || 
        condition.toLowerCase().contains('thunder')) {
      warnings.add('⚠️ Severe weather alert - secure loose items');
    }
    
    if (temp > 40) {
      warnings.add('🌡️ Extreme heat warning - protect livestock and crops');
    }
    
    if (temp < 5) {
      warnings.add('❄️ Frost warning - cover sensitive plants');
    }
    
    return warnings;
  }
  
  WeatherRecommendation _fallbackWeatherRecommendation(String location) {
    return WeatherRecommendation(
      location: location,
      weatherData: {
        'temperature': 25.0,
        'humidity': 60,
        'condition': 'Unknown',
      },
      recommendations: [
        'Weather data unavailable',
        'Follow standard farming practices',
      ],
      warnings: [],
      timestamp: DateTime.now(),
    );
  }
}

// =============================================
// lib/core/ai/translation_service.dart
// =============================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logging/logger.dart';

class TranslationService {
  final Map<String, String> _cache = {};
  
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    final cacheKey = '$text-$sourceLanguage-$targetLanguage';
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    try {
      final response = await http.post(
        Uri.parse('https://libretranslate.com/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': sourceLanguage,
          'target': targetLanguage,
          'format': 'text',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['translatedText'] as String;
        _cache[cacheKey] = translated;
        return translated;
      } else {
        return text;
      }
    } catch (e, stack) {
      AppLogger.error('Translation failed', error: e, stackTrace: stack);
      return text;
    }
  }
  
  Future<Map<String, String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'en',
  }) async {
    final results = <String, String>{};
    
    for (final text in texts) {
      results[text] = await translate(
        text: text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
    }
    
    return results;
  }
  
  void clearCache() {
    _cache.clear();
  }
}