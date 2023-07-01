import 'dart:convert';

import 'package:jira_api/jira_api.dart';

class StatusesCategory {
  final IssueStatus customIssueStatus;
  final List<String> statusesNames;

  StatusesCategory({
    required this.customIssueStatus,
    required this.statusesNames,
  });

  StatusesCategory clone() {
    return StatusesCategory(
      customIssueStatus: IssueStatus(
        id: customIssueStatus.id,
        name: customIssueStatus.name,
      ),
      statusesNames: List.from(statusesNames),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customIssueStatus': customIssueStatus.toMap(),
      'statusesNames': statusesNames,
    };
  }

  factory StatusesCategory.fromMap(Map<String, dynamic> map) {
    return StatusesCategory(
      customIssueStatus: IssueStatus.fromMap(map['customIssueStatus']),
      statusesNames: List<String>.from(map['statusesNames']),
    );
  }

  String toJson() => json.encode(toMap());

  factory StatusesCategory.fromJson(String source) =>
      StatusesCategory.fromMap(json.decode(source));
}

extension on IssueStatus {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
