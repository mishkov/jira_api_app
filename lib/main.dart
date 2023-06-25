import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:jira_api/jira_api.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class StatusesCategory {
  final IssueStatus customIssueStatus;
  final List<String> statusesNames;

  StatusesCategory({
    required this.customIssueStatus,
    required this.statusesNames,
  });
}

class _HomePageState extends State<HomePage> {
  JiraStats? _jiraStats;
  Future<EstimationResults>? _resultFuture;
  final List<StatusesCategory> _statusesCategoris = [
    StatusesCategory(
      customIssueStatus:
          IssueStatus(id: const Uuid().v1(), name: 'К Выполнению'),
      statusesNames: ['REOPENED', 'К выполнению', 'To Do'],
    ),
    StatusesCategory(
      customIssueStatus: IssueStatus(id: const Uuid().v1(), name: 'В Работе'),
      statusesNames: ['In Progress', 'CODE REVIEW', 'TEST', 'В работе'],
    ),
    StatusesCategory(
      customIssueStatus: IssueStatus(id: const Uuid().v1(), name: 'Сделано'),
      statusesNames: ['TESTED', 'Done', 'Готово'],
    ),
    StatusesCategory(
      customIssueStatus: IssueStatus(id: const Uuid().v1(), name: 'Отменено'),
      statusesNames: ['FAIL', 'rejected'],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _initJiraStats();
  }

  @override
  void dispose() {
    super.dispose();

    _jiraStats?.dispose();
  }

  Future<void> _initJiraStats() async {
    await dotenv.load(fileName: 'assets/.env');
    final jiraStats = JiraStats(
      user: dotenv.env['USER_NAME']!,
      apiToken: dotenv.env['API_TOKEN']!,
    );

    await jiraStats.initialize();

    final results = await jiraStats.getTotalEstimationFor(
      label: 'MB',
      weeksAgoCount: 40,
    );

    for (final record in results.datedGroups) {
      final categorisedEstimation = <EstimatedGroup>[];
      for (final estimationGroup in record.groupedEstimations) {
        final possibleCategories = _statusesCategoris.where((category) {
          return category.statusesNames
              .contains(estimationGroup.groupStatus.name);
        });

        if (possibleCategories.isEmpty) {
          log('${estimationGroup.groupStatus.name} is not found in available categories');
          continue;
        }

        if (possibleCategories.length > 1) {
          log('found more than one ${estimationGroup.groupStatus.name}');
          continue;
        }

        if (categorisedEstimation.any((element) {
          return element.groupStatus ==
              possibleCategories.single.customIssueStatus;
        })) {
          final category = categorisedEstimation.singleWhere((element) {
            return element.groupStatus ==
                possibleCategories.single.customIssueStatus;
          });

          category.estimation += estimationGroup.estimation;
        } else {
          categorisedEstimation.add(EstimatedGroup(
            groupStatus: possibleCategories.single.customIssueStatus,
            estimation: estimationGroup.estimation,
          ));
        }
      }

      record.groupedEstimations
        ..clear()
        ..addAll(categorisedEstimation);
    }

    setState(() {
      _resultFuture = Future.value(results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<EstimationResults>(
          future: _resultFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: [
                  Expanded(
                    child: EstimatinoResultsView(results: snapshot.data!),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _statusesCategoris.length,
                      itemBuilder: (context, index) {
                        return ColoredBox(
                          color: index.isEven
                              ? Colors.grey.shade300
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _statusesCategoris[index]
                                        .customIssueStatus
                                        .name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Включает'),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                _statusesCategoris[index]
                                    .statusesNames
                                    .join(', '),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              );
            } else if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            } else {
              return const CircularProgressIndicator.adaptive();
            }
          },
        ),
      ),
    );
  }
}

class EstimatinoResultsView extends StatelessWidget {
  const EstimatinoResultsView({
    super.key,
    required this.results,
  });

  final EstimationResults results;

  @override
  Widget build(BuildContext context) {
    final allStatus =
        results.datedGroups.fold<Set<IssueStatus>>({}, (allStatuses, record) {
      return allStatuses
        ..addAll(record.groupedEstimations.fold<Set<IssueStatus>>({},
            (innerStatuses, group) {
          return innerStatuses..add(group.groupStatus);
        }));
    });

    List<LineSeries<GroupedIssuesRecord, int>> series = [];

    for (final status in allStatus) {
      series.add(
        LineSeries(
          dataSource: results.datedGroups,
          dataLabelMapper: (datum, index) {
            const dateFormat = 'yyyy-MM-dd';

            final formatter = DateFormat(dateFormat);
            return formatter.format(datum.date);
          },
          name: status.name,
          xAxisName: 'Дата',
          yAxisName: 'Story Points',
          isVisibleInLegend: true,
          xValueMapper: (GroupedIssuesRecord record, _) {
            return record.date.millisecondsSinceEpoch;
          },
          yValueMapper: (GroupedIssuesRecord record, _) {
            final estimatedGroup = record.groupedEstimations
                .where((element) => element.groupStatus == status);

            return estimatedGroup.singleOrNull?.estimation;
          },
        ),
      );
    }

    return SfCartesianChart(
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: series,
    );
  }
}
