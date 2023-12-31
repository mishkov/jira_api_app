import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jira_api_app/statuses_category.dart';

class StatusesCategoriesView extends StatefulWidget {
  const StatusesCategoriesView({
    super.key,
    required this.statusesCategoris,
    this.onCategoriesUpdated,
  });

  final List<StatusesCategory> statusesCategoris;
  final void Function(List<StatusesCategory> categoris)? onCategoriesUpdated;

  @override
  State<StatusesCategoriesView> createState() => _StatusesCategoriesViewState();
}

class _StatusesCategoriesViewState extends State<StatusesCategoriesView> {
  List<StatusesCategory>? _updatedCategoris;

  @override
  Widget build(BuildContext context) {
    final categories = _updatedCategoris ?? widget.statusesCategoris;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 3.0);
          },
          itemBuilder: (context, index) {
            return DragTarget(
              onAccept: (data) {
                if (data is! String) {
                  return;
                }

                setState(() {
                  _updatedCategoris![index].statusesNames.add(data);
                });
              },
              builder: (context, candidateItems, rejectedItems) => ColoredBox(
                color: index.isEven ? Colors.grey.shade300 : Colors.transparent,
                child: Row(
                  children: [
                    Row(
                      children: [
                        Text(
                          categories[index].customIssueStatus.name,
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
                        children: categories[index].statusesNames.map(
                          (e) {
                            return Draggable(
                              data: e,
                              onDragStarted: () {
                                setState(() {
                                  _updatedCategoris ??=
                                      widget.statusesCategoris.map((e) {
                                    return e.clone();
                                  }).toList();
                                });
                              },
                              onDragEnd: (details) {
                                if (details.wasAccepted) {
                                  setState(() {
                                    categories[index].statusesNames.remove(e);
                                  });
                                }
                              },
                              feedback: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                                padding: const EdgeInsets.all(3.0),
                                child: Text(
                                  e,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                                padding: const EdgeInsets.all(3.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 14,
                                      onPressed: () {
                                        setState(() {
                                          _updatedCategoris ??=
                                              widget.statusesCategoris.map((e) {
                                            return e.clone();
                                          }).toList();
                                        });

                                        _updatedCategoris![index]
                                            .statusesNames
                                            .remove(e);
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                    Text(
                                      e,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 16,
                      onPressed: () async {
                        final newStatus = await showCupertinoDialog<String>(
                          context: context,
                          builder: (context) {
                            return const AddStatusDialog();
                          },
                          barrierDismissible: true,
                        );

                        if (newStatus == null) {
                          return;
                        }
                        if (newStatus.isEmpty) {
                          return;
                        }

                        setState(() {
                          _updatedCategoris ??=
                              widget.statusesCategoris.map((e) {
                            return e.clone();
                          }).toList();
                        });

                        _updatedCategoris![index].statusesNames.add(newStatus);
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Visibility(
          visible: _updatedCategoris != null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.red),
                ),
                onPressed: () {
                  setState(() {
                    _updatedCategoris = null;
                  });
                },
                child: const Text('Отмена'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (widget.onCategoriesUpdated != null) {
                    widget.onCategoriesUpdated!(_updatedCategoris!);
                  }
                  setState(() {
                    _updatedCategoris = null;
                  });
                },
                child: const Text('Применить'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddStatusDialog extends StatefulWidget {
  const AddStatusDialog({
    super.key,
  });

  @override
  State<AddStatusDialog> createState() => _AddStatusDialogState();
}

class _AddStatusDialogState extends State<AddStatusDialog> {
  final _statusNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('New Status'),
      content: Material(
        color: Colors.transparent,
        child: TextField(
          controller: _statusNameController,
          decoration: const InputDecoration(
            labelText: 'Status name',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop(_statusNameController.text);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
