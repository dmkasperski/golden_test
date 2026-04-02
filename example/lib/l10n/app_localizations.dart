import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  static final _translations = {
    'en': {
      'goodMorning': 'Good morning',
      'totalBalance': 'Total balance',
      'thisMonth': '+12.4% this month',
      'income': 'Income',
      'spending': 'Spending',
      'send': 'Send',
      'request': 'Request',
      'topUp': 'Top up',
      'more': 'More',
      'weeklySpending': 'Weekly spending',
      'recentTransactions': 'Recent transactions',
      'entertainment': 'Entertainment',
      'technology': 'Technology',
      'transferReceived': 'Transfer received',
      'foodAndDrink': 'Food & Drink',
    },
    'es': {
      'goodMorning': 'Buenos dias',
      'totalBalance': 'Saldo total',
      'thisMonth': '+12.4% este mes',
      'income': 'Ingresos',
      'spending': 'Gastos',
      'send': 'Enviar',
      'request': 'Solicitar',
      'topUp': 'Recargar',
      'more': 'Mas',
      'weeklySpending': 'Gastos semanales',
      'recentTransactions': 'Transacciones recientes',
      'entertainment': 'Entretenimiento',
      'technology': 'Tecnologia',
      'transferReceived': 'Transferencia recibida',
      'foodAndDrink': 'Comida y bebida',
    },
  };

  String _t(String key) =>
      _translations[locale.languageCode]?[key] ?? _translations['en']![key]!;

  String get goodMorning => _t('goodMorning');
  String get totalBalance => _t('totalBalance');
  String get thisMonth => _t('thisMonth');
  String get income => _t('income');
  String get spending => _t('spending');
  String get send => _t('send');
  String get request => _t('request');
  String get topUp => _t('topUp');
  String get more => _t('more');
  String get weeklySpending => _t('weeklySpending');
  String get recentTransactions => _t('recentTransactions');
  String get entertainment => _t('entertainment');
  String get technology => _t('technology');
  String get transferReceived => _t('transferReceived');
  String get foodAndDrink => _t('foodAndDrink');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
