import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jira_api/jira_api.dart';
import 'package:jira_api_app/home_page.dart';
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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tryLoadCredentials();
  }

  Future<void> _tryLoadCredentials() async {
    await dotenv.load(fileName: 'assets/.env');

    setState(() {
      _loginController.text = dotenv.env['USER_NAME'] ?? '';
      _apiTokenController.text = dotenv.env['API_TOKEN'] ?? '';
    });
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        final jiraStats = JiraStats(
                          user: _loginController.text,
                          apiToken: _apiTokenController.text,
                        );
                        try {
                          await jiraStats.initialize();

                          if (context.mounted) {
                            Navigator.of(context).popAndPushNamed(
                                HomePage.routeName,
                                arguments: jiraStats);
                          }
                        } on UnauthorizedException catch (_) {
                          showMessage(context,
                              'Войти не удалось! Убедитесь, что логин и апи токен указаны верно');
                        } catch (e) {
                          if (context.mounted) {}
                          showMessage(
                              context, 'Войти не удалось! Неизвестная ошибка');
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
