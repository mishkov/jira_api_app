import 'package:flutter/material.dart';
import 'package:jira_api/jira_api.dart';
import 'package:jira_api_app/home_page.dart';
import 'package:jira_api_app/login_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: LoginPage.routeName,
      routes: {
        LoginPage.routeName: (context) => const LoginPage(),
      },
      onGenerateRoute: (settings) {

        if (settings.name == HomePage.routeName) {
          return MaterialPageRoute(
            builder: (context) {
              return HomePage(jiraStats: settings.arguments as JiraStats);
            },
          );
        } else {
          return MaterialPageRoute(
            builder: (context) {
              return const LoginPage();
            },
          );
        }
      },
    );
  }
}
