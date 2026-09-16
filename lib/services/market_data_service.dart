import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MarketDataException implements Exception {
  final String message;

  const MarketDataException(this.message);

  @override
  String toString() => message;
}

class MarketPrice {
  final String commodity;
  final double modalPrice;
  final String market;
  final String state;
  final DateTime priceDate;
  final String source;

  const MarketPrice({
    required this.commodity,
    required this.modalPrice,
    required this.market,
    required this.state,
    required this.priceDate,
    required this.source,
  });
}

class MarketDataService {
  static const _resourceId = '9ef84268-d588-465a-a308-a864a43d0070';
  static const _baseUrl = 'https://api.data.gov.in/resource/$_resourceId';
  static const _source = 'Government of India Data.gov.in / AGMARKNET';
  static const _timeout = Duration(seconds: 15);
  static const _defaultState = 'Maharashtra';
  static const _defaultCommodities = [
    'Wheat',
    'Rice',
    'Mustard',
    'Cotton',
    'Gram',
  ];
  static const _maxReturnedRecords = 10;
  static const _recordsPerCommodity = 2;

  Future<List<MarketPrice>> fetchDailyPrices({
    String? state,
    List<String>? commodities,
    int limit = _maxReturnedRecords,
  }) async {
    if (limit < 1 || limit > _maxReturnedRecords) {
      throw const MarketDataException('Market data limit must be 1-10.');
    }

    final apiKey = _getApiKey();
    final selectedState = state?.trim().isNotEmpty == true
        ? state!.trim()
        : _defaultState;
    final selectedCommodities = commodities == null
        ? _defaultCommodities
        : commodities
              .map((commodity) => commodity.trim())
              .where((commodity) => commodity.isNotEmpty)
              .toSet()
              .toList(growable: false);
    final requestedCommodities = selectedCommodities.isEmpty
        ? _defaultCommodities
        : selectedCommodities;
    final perRequestLimit = selectedCommodities.length == 1
        ? limit
        : _recordsPerCommodity;

    final results = await Future.wait(
      requestedCommodities
          .take(_maxReturnedRecords ~/ _recordsPerCommodity)
          .map(
            (selectedCommodity) => _fetchCommodityPrices(
              apiKey: apiKey,
              state: selectedState,
              commodity: selectedCommodity,
              limit: perRequestLimit,
            ),
          ),
    );
    final prices = results.expand((items) => items).toList()
      ..sort((a, b) => b.priceDate.compareTo(a.priceDate));
    if (prices.isEmpty) {
      throw const MarketDataException(
        'Market data response contained no records.',
      );
    }
    return prices.take(limit).toList(growable: false);
  }

  Future<List<MarketPrice>> _fetchCommodityPrices({
    required String apiKey,
    required String state,
    required String commodity,
    required int limit,
  }) async {
    final queryParameters = <String, String>{
      'api-key': apiKey,
      'format': 'json',
      'limit': '$limit',
      'filters[state]': state,
      'filters[commodity]': commodity,
    };
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw MarketDataException(
        'Market data request failed with HTTP ${response.statusCode}.',
      );
    }
    return parseResponse(response.body, allowEmpty: true);
  }

  static List<MarketPrice> parseResponse(
    String responseBody, {
    bool allowEmpty = false,
  }) {
    final decoded = _decodeResponse(responseBody);
    final records = decoded['records'];
    if (records is! List) {
      throw const MarketDataException(
        'Market data response did not contain records.',
      );
    }
    if (records.isEmpty && !allowEmpty) {
      throw const MarketDataException(
        'Market data response contained no records.',
      );
    }

    final prices = <MarketPrice>[];
    for (final record in records) {
      if (record is! Map) {
        throw const MarketDataException(
          'Market data contained an invalid record.',
        );
      }
      prices.add(_parseRecord(Map<String, dynamic>.from(record)));
    }
    return prices;
  }

  static String _getApiKey() {
    try {
      final apiKey = dotenv.env['DATA_GOV_IN_API_KEY']?.trim();
      if (apiKey == null || apiKey.isEmpty) {
        throw const MarketDataException(
          'Data.gov.in API key is not configured.',
        );
      }
      return apiKey;
    } on MarketDataException {
      rethrow;
    } catch (_) {
      throw const MarketDataException('Data.gov.in API key is not configured.');
    }
  }

  static Future<http.Response> _get(Uri uri) async {
    try {
      return await http.get(uri).timeout(_timeout);
    } on MarketDataException {
      rethrow;
    } catch (_) {
      throw const MarketDataException(
        'Market data request could not be completed.',
      );
    }
  }

  static Map<String, dynamic> _decodeResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map) {
        throw const MarketDataException(
          'Market data response was not an object.',
        );
      }
      return Map<String, dynamic>.from(decoded);
    } on MarketDataException {
      rethrow;
    } on FormatException {
      throw const MarketDataException(
        'Market data response was not valid JSON.',
      );
    } on TypeError {
      throw const MarketDataException(
        'Market data response had an invalid shape.',
      );
    }
  }

  static MarketPrice _parseRecord(Map<String, dynamic> record) {
    final commodity = _requiredText(record, 'commodity');
    final market = _requiredText(record, 'market');
    final state = _requiredText(record, 'state');
    final priceDate = _parseDate(_requiredText(record, 'arrival_date'));
    final modalPrice = _parsePrice(record['modal_price']);

    return MarketPrice(
      commodity: commodity,
      modalPrice: modalPrice,
      market: market,
      state: state,
      priceDate: priceDate,
      source: _source,
    );
  }

  static String _requiredText(Map<String, dynamic> record, String field) {
    final value = record[field];
    if (value is! String || value.trim().isEmpty) {
      throw MarketDataException('Market data record is missing $field.');
    }
    return value.trim();
  }

  static double _parsePrice(dynamic value) {
    final price = value is num ? value.toDouble() : double.tryParse('$value');
    if (price == null || !price.isFinite || price < 0) {
      throw const MarketDataException(
        'Market data record has an invalid modal price.',
      );
    }
    return price;
  }

  static DateTime _parseDate(String value) {
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return isoDate;

    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        final date = DateTime(year, month, day);
        if (date.year == year && date.month == month && date.day == day) {
          return date;
        }
      }
    }
    throw const MarketDataException(
      'Market data record has an invalid price date.',
    );
  }
}
