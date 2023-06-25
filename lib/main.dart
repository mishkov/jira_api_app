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

  final _jqlController = TextEditingController(
      text: 'project = "AS" AND labels = "MB" ORDER BY created DESC');
  bool _isJqlValid = true;
  String? _jqlError;

  var _samplingFrequency = SamplingFrequency.eachWeek;

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
    _jiraStats = JiraStats(
      user: dotenv.env['USER_NAME']!,
      apiToken: dotenv.env['API_TOKEN']!,
    );

    await _jiraStats!.initialize();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _jqlError = null;
    });
    final errors = await _jiraStats!.validateJql(_jqlController.text);

    setState(() {
      _isJqlValid = errors.isEmpty;
      if (!_isJqlValid) {
        _jqlError = errors.join('. ');
      }
    });

    if (!_isJqlValid) {
      _showMessage('Ошибка! запрос невалиден!');
      return;
    }

    setState(() {
      _resultFuture = _jiraStats!.getTotalEstimationByJql(
        _jqlController.text,
        weeksAgoCount: 40,
        frequency: _samplingFrequency,
      );
    });

    final results = await _resultFuture!;

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

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final samplingFrequency = Row(
      children: [
        Row(
          children: [
            Radio<SamplingFrequency>(
              value: SamplingFrequency.eachDay,
              groupValue: _samplingFrequency,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _samplingFrequency = value;
                  });
                }
              },
            ),
            const Text('Каждый день'),
          ],
        ),
        Row(children: [
          Radio<SamplingFrequency>(
            value: SamplingFrequency.eachWeek,
            groupValue: _samplingFrequency,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _samplingFrequency = value;
                });
              }
            },
          ),
          const Text('Каждую неделю')
        ]),
      ],
    );

    final stats = FutureBuilder<EstimationResults>(
      future: _resultFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return EstimatinoResultsView(results: snapshot.data!);
        } else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        } else if (snapshot.connectionState == ConnectionState.none) {
          return const Center(
            child: Text(
              'Нажмите "Посчитать" для сбора статистики',
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else {
          return const Text('Что-то пошло не так');
        }
      },
    );

    final statusesCategories = Padding(
      padding: const EdgeInsets.all(8.0),
      child: StatusesCategoiesView(
        statusesCategoris: _statusesCategoris,
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final isVertical = (constraints.maxWidth / constraints.maxHeight) < 2;
      Widget content;
      if (isVertical) {
        content = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 50,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: JqlField(
                            jqlController: _jqlController,
                            onSubmitted: () {
                              _fetchStats();
                            },
                            error: _jqlError,
                          ),
                        ),
                        const SizedBox(width: 16),
                        CalculateButton(onPressed: _fetchStats),
                      ],
                    ),
                  ),
                  samplingFrequency,
                ],
              ),
            ),
            Expanded(
              child: stats,
            ),
            statusesCategories,
          ],
        );
      } else {
        content = Row(
          children: [
            Expanded(child: stats),
            SizedBox(
              width: 400,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: JqlField(
                      jqlController: _jqlController,
                      onSubmitted: () {
                        _fetchStats();
                      },
                      error: _jqlError,
                      isMultiLine: true,
                    ),
                  ),
                  samplingFrequency,
                  CalculateButton(
                    onPressed: _fetchStats,
                    inVerticalOrientation: true,
                  ),
                  const Spacer(),
                  statusesCategories,
                ],
              ),
            ),
          ],
        );
      }

      return Scaffold(
        body: SafeArea(
          child: Center(child: content),
        ),
      );
    });
  }
}

class JqlField extends StatelessWidget {
  const JqlField({
    super.key,
    required this.jqlController,
    required this.onSubmitted,
    required this.error,
    this.isMultiLine = false,
  });

  final TextEditingController jqlController;
  final void Function() onSubmitted;
  final String? error;
  final bool isMultiLine;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: jqlController,
      onSubmitted: (_) {
        onSubmitted;
      },
      maxLines: isMultiLine ? null : 1,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        errorText: error,
      ),
    );
  }
}

class CalculateButton extends StatelessWidget {
  const CalculateButton({
    super.key,
    required this.onPressed,
    this.inVerticalOrientation = false,
  });

  final void Function()? onPressed;
  final bool inVerticalOrientation;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (inVerticalOrientation) {
      text = 'Посчитать Статистику';
    } else {
      text = 'Посчитать\nСтатистику';
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class StatusesCategoiesView extends StatelessWidget {
  const StatusesCategoiesView({
    super.key,
    required List<StatusesCategory> statusesCategoris,
  }) : _statusesCategoris = statusesCategoris;

  final List<StatusesCategory> _statusesCategoris;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _statusesCategoris.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 3.0);
      },
      itemBuilder: (context, index) {
        return ColoredBox(
          color: index.isEven ? Colors.grey.shade300 : Colors.transparent,
          child: Row(
            children: [
              Row(
                children: [
                  Text(
                    _statusesCategoris[index].customIssueStatus.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Включает:'),
                ],
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 3.0,
                  runSpacing: 3.0,
                  children: _statusesCategoris[index].statusesNames.map(
                    (e) {
                      return Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(3.0)),
                        padding: const EdgeInsets.all(3.0),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          ),
        );
      },
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

    List<LineSeries<GroupedIssuesRecord, String>> series = [];

    for (final status in allStatus) {
      series.add(
        LineSeries(
          dataSource: results.datedGroups.reversed.toList(),
          dataLabelMapper: (datum, index) {
            const dateFormat = 'yyyy-MM-dd';

            final formatter = DateFormat(dateFormat);
            return formatter.format(datum.date);
          },
          name: status.name,
          xAxisName: 'Дата',
          isVisible: true,
          yAxisName: 'Story Points',
          isVisibleInLegend: true,
          xValueMapper: (record, value) {
            const dateFormat = 'yyyy-MM-dd';

            final formatter = DateFormat(dateFormat);
            return formatter.format(record.date);
          },
          yValueMapper: (record, value) {
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
      primaryXAxis: CategoryAxis(
        title: AxisTitle(
          text: 'Дата',
        ),
        labelRotation: 45,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Story Points'),
      ),
      zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          enableMouseWheelZooming: true,
          zoomMode: ZoomMode.x),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: series,
    );
  }
}
