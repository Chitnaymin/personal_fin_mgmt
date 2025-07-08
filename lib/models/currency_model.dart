import 'package:flutter/material.dart';

@immutable
class Currency {
  final String name;
  final String code;
  final String symbol;
  final String locale;

  const Currency({
    required this.name,
    required this.code,
    required this.symbol,
    required this.locale,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

const List<Currency> supportedCurrencies = [
  Currency(name: 'Thai Baht', code: 'THB', symbol: '฿', locale: 'th_TH'),
  Currency(name: 'US Dollar', code: 'USD', symbol: '\$', locale: 'en_US'),
  Currency(name: 'Euro', code: 'EUR', symbol: '€', locale: 'de_DE'),
  Currency(name: 'Japanese Yen', code: 'JPY', symbol: '¥', locale: 'ja_JP'),
  Currency(name: 'British Pound', code: 'GBP', symbol: '£', locale: 'en_GB'),
];

final Currency defaultCurrency = supportedCurrencies[0];