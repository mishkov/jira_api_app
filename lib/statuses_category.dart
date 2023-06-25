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
}
