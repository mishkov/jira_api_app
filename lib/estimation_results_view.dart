import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jira_api/jira_api.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EstimationResultsView extends StatelessWidget {
  const EstimationResultsView({
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
