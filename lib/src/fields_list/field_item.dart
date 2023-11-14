import 'package:flutter/material.dart' hide ReorderableList;
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_links_picker/src/fields_list/dialog.dart';
import 'package:reactive_links_picker/src/models/custom_link.dart';

enum DraggingMode {
  iOS,
  android,
}

class FieldItem extends StatelessWidget {
  const FieldItem({
    Key? key,
    required this.isFirst,
    required this.isLast,
    required this.draggingMode,
    required this.index,
    required this.orderKey,
    required this.onRemove,
    required this.onUpdate,
    required this.data,
  }) : super(key: key);

  final int index;
  final Key orderKey;
  final Map<String, dynamic> data;
  final bool isFirst;
  final bool isLast;
  final DraggingMode draggingMode;

  final Function(int) onRemove;
  final Function(int, CustomLink) onUpdate;

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    final formGroup =
        ReactiveForm.of(context, listen: true)?.parent as FormGroup;

    BoxDecoration decoration;

    if (state == ReorderableItemState.dragProxy ||
        state == ReorderableItemState.dragProxyFinished) {
      // slightly transparent background white dragging (just like on iOS)
      decoration = const BoxDecoration(color: Color(0xD0FFFFFF));
    } else {
      bool placeholder = state == ReorderableItemState.placeholder;
      decoration = BoxDecoration(
          border: Border(
              top: isFirst && !placeholder
                  ? Divider.createBorderSide(context) //
                  : BorderSide.none,
              bottom: isLast && placeholder
                  ? BorderSide.none //
                  : Divider.createBorderSide(context)),
          color: placeholder ? null : Colors.white);
    }

    // For iOS dragging mode, there will be drag handle on the right that triggers
    // reordering; For android mode it will be just an empty container
    Widget dragHandle = draggingMode == DraggingMode.iOS
        ? ReorderableListener(
            child: const Center(
              child: Icon(Icons.reorder, color: Color(0xFF888888)),
            ),
          )
        : Container();

    Widget content = SafeArea(
        top: false,
        bottom: false,
        child: Opacity(
          // hide content for placeholder
          opacity: state == ReorderableItemState.placeholder ? 0.0 : 1.0,
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: formGroup.control("customLinks.$index").valid
                        ? Colors.transparent
                        : Colors.red,
                    width: 2.0),
                borderRadius: BorderRadius.circular(8.0)),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 16,
                          children: [
                            dragHandle,
                            Text(
                              "${formGroup.control('customLinks.$index.label').value}",
                            )
                          ],
                        ),
                        GestureDetector(
                            onTap: () async {
                              await showDeleteDialog(context).then((value) {
                                if (value == true) {
                                  onRemove(index);
                                }
                              });
                            },
                            child: const Icon(Icons.clear_rounded))
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    ReactiveTextField(
                      onChanged: (control) {
                        onUpdate(
                            index,
                            CustomLink.fromJson(
                                control.parent?.value as Map<String, dynamic>));
                      },

                      showErrors: (control) {
                        return false;
                      },
                      formControl: formGroup.control('customLinks.$index.value')
                          as FormControl,
                      //  formControlName: '$i.value',
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReactiveTextField(
                      onChanged: (control) {
                        onUpdate(
                            index,
                            CustomLink.fromJson(
                                control.parent?.value as Map<String, dynamic>));
                      },
                      showErrors: (control) {
                        return false;
                      },
                      formControl: formGroup
                          .control('customLinks.$index.custom') as FormControl,
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));

    // For android dragging mode, wrap the entire content in DelayedReorderableListener
    if (draggingMode == DraggingMode.android) {
      content = DelayedReorderableListener(
        child: content,
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
        key: orderKey, //
        childBuilder: _buildChild);
  }
}
