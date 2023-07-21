import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jira_api/jira_api.dart';
import 'package:jira_api_app/home_page.dart';
import 'package:jira_api_app/local_storage.dart';
import 'package:jira_api_app/show_message.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _apiTokenController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _isLoading = false;
  final _localStorage = LocalStorage();

  @override
  void initState() {
    super.initState();

    _initLocaleStorage().then((_) {
      _tryLoadCredentials();
    });
  }

  Future<void> _initLocaleStorage() async {
    await _localStorage.load();
  }

  Future<void> _tryLoadCredentials() async {
    _loginController.text = await _localStorage.getLogin() ?? '';
    _apiTokenController.text = await _localStorage.getApiToken() ?? '';
    _accountNameController.text = await _localStorage.getAccountName() ?? '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiTokenController,
                decoration: const InputDecoration(
                  labelText: 'Апи Токен',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Имя Jira аккаунта (<your-account>.atlassian.net)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final response = await http.post(
                            Uri.parse(
                                'http://80.78.245.114:8080/check-credentials'),
                            body: jsonEncode({
                              "user": _loginController.text,
                              "token": _apiTokenController.text,
                              "account": _accountNameController.text,
                            }),
                            headers: {
                              HttpHeaders.contentTypeHeader: 'application/json',
                            },
                          );

                          if (response.statusCode == 401) {
                            throw UnauthorizedException();
                          }

                          if (response.statusCode != 200) {
                            throw Exception();
                          }

                          if (context.mounted) {
                            Navigator.of(context).popAndPushNamed(
                              HomePage.routeName,
                            );
                          }

                          _localStorage.putLogin(_loginController.text);
                          _localStorage.putApiToken(_apiTokenController.text);
                          _localStorage
                              .putAccountName(_accountNameController.text);
                        } on UnauthorizedException catch (_) {
                          showMessage(context,
                              'Войти не удалось! Убедитесь, что логин и апи токен указаны верно');
                        } catch (e) {
                          if (context.mounted) {
                            log(
                              'error: $e. Strack Trace is ${StackTrace.current}',
                            );
                            showMessage(context,
                                'Войти не удалось! Неизвестная ошибка');
                          }
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                child: const Text('Войти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Access-Control-Allow-Origin'] = '*';
    request.headers['Access-Control-Allow-Credentials'] = 'true';
    request.headers['Access-Control-Allow-Headers'] =
        'Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale';
    request.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS';
    request.headers['X-Atlassian-Token'] = 'no-check';

    //X-Atlassian-Token
    return http.Client().send(request);
  }
}
