import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:jira_api/jira_api.dart';
import 'package:jira_api_app/calculate_button.dart';
import 'package:jira_api_app/estimation_results_view.dart';
import 'package:jira_api_app/jql_field.dart';
import 'package:jira_api_app/show_message.dart';
import 'package:jira_api_app/statuses_categories_view.dart';
import 'package:jira_api_app/statuses_category.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';

  const HomePage({
    super.key,
    required this.jiraStats,
  });

  final JiraStats jiraStats;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  Future<EstimationResults>? _rawResultsFuture;
  Future<EstimationResults>? _results;
  List<StatusesCategory> _statusesCategoris = [
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
  void dispose() {
    super.dispose();

    widget.jiraStats.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _jqlError = null;
    });
    final errors = await widget.jiraStats.validateJql(_jqlController.text);

    setState(() {
      _isJqlValid = errors.isEmpty;
      if (!_isJqlValid) {
        _jqlError = errors.join('. ');
      }
    });

    if (!_isJqlValid) {
      if (context.mounted) {
        showMessage(context, 'Ошибка! запрос невалиден!');
      }
      return;
    }

    setState(() {
      _rawResultsFuture = widget.jiraStats.getTotalEstimationByJql(
        _jqlController.text,
        weeksAgoCount: 40,
        frequency: _samplingFrequency,
      );
    });

    await _groupEstimationByCategories();
  }

  Future<void> _groupEstimationByCategories() async {
    setState(() {
      _results = _rawResultsFuture!;
    });

    final copy = (await _results!).clone();

    for (final record in copy.datedGroups) {
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
      _results = Future.value(copy);
    });
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
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return EstimationResultsView(results: snapshot.data!);
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
      child: StatusesCategoriesView(
        statusesCategoris: _statusesCategoris,
        onCategoriesUpdated: (categoris) {
          setState(() {
            _statusesCategoris = categoris;
            if (_rawResultsFuture != null) {
              _groupEstimationByCategories();
            }
          });
        },
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
