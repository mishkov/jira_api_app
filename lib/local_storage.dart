import 'dart:convert';

import 'package:jira_api_app/statuses_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  final _loginKey = 'login';
  final _apiTokenKey = 'apiToken';
  final _accountNameKey = 'accountName';
  final _storyPointsField = 'storyPointsFieldName';
  final _jqlQueryKey = 'jqlQuery';
  final _statusesCategoriesKey = 'statusesCategories';

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> putLogin(String login) async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    await _prefs!.setString(_loginKey, login);
  }

  Future<String?> getLogin() async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    return _prefs!.getString(_loginKey);
  }

  Future<void> putApiToken(String apiToken) async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    await _prefs!.setString(_apiTokenKey, apiToken);
  }

  Future<String?> getApiToken() async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    return _prefs!.getString(_apiTokenKey);
  }

  Future<void> putAccountName(String accountName) async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    await _prefs!.setString(_accountNameKey, accountName);
  }

  Future<String?> getAccountName() async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    return _prefs!.getString(_accountNameKey);
  }

  Future<void> putStoryPointsField(String filedName) async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    await _prefs!.setString(_storyPointsField, filedName);
  }

  Future<String?> getStoryPointsField() async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    return _prefs!.getString(_storyPointsField);
  }

  Future<void> putJqlQuery(String jql) async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    await _prefs!.setString(_jqlQueryKey, jql);
  }

  Future<String?> getJqlQuery() async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    return _prefs!.getString(_jqlQueryKey);
  }

  Future<void> putStatusesCategories(List<StatusesCategory> categories) async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    final convertedCategories = categories.map((e) => e.toMap()).toList();

    await _prefs!.setString(
      _statusesCategoriesKey,
      json.encode(convertedCategories),
    );
  }

  Future<List<StatusesCategory>?> getStatusesCategories() async {
    if (_prefs == null) {
      UninitializedLocalStorageException();
    }

    final rawString = _prefs!.getString(_statusesCategoriesKey);

    if (rawString == null) {
      return null;
    }

    final rawCategories = json.decode(rawString);
    final List<StatusesCategory> categories = [];

    for (final rawCategory in rawCategories) {
      categories.add(StatusesCategory.fromMap(rawCategory));
    }

    return categories;
  }
}

class UninitializedLocalStorageException {}
