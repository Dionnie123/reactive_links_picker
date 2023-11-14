import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ReorderableList;
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:reactive_links_picker/reactive_links_picker.dart';
import 'package:reactive_links_picker/src/fields_list/field_item.dart';

class FieldsList extends StatefulWidget {
  final Function(int index, CustomLink link) onUpdateAt;
  final Function(List<Map<String, dynamic>> value) onReorder;
  final Function(int index) onRemovedAt;
  const FieldsList({
    super.key,
    required this.onReorder,
    required this.onRemovedAt,
    required this.onUpdateAt,
  });

  @override
  State<FieldsList> createState() => _LinksListState();
}

class _LinksListState extends State<FieldsList> {
  late FormGroup form;
  late FormArray formArray;

  DraggingMode draggingMode = DraggingMode.iOS;
  double itemHeight = kIsWeb ? 144 : 138;

  @override
  Widget build(BuildContext context) {
    form = ReactiveForm.of(context) as FormGroup;
    formArray = form.control('customLinks') as FormArray<Map<String, dynamic>>;
    List<FieldItem> items = [];
    for (var i = 0; i < formArray.controls.length; i++) {
      items.add(FieldItem(
          data: formArray.controls[i].value,
          index: i,
          orderKey: ValueKey(i),
          isFirst: i == 0,
          isLast: i == formArray.controls.length - 1,
          draggingMode: DraggingMode.iOS,
          onRemove: (index) {
            widget.onRemovedAt(index);
          },
          onUpdate: (index, value) {
            widget.onUpdateAt(index, value);
          }));
    }
    return ReactiveFormArray(
        formArray: formArray,
        builder: (context, array, child) {
          return DottedBorder(
              dashPattern: const [9, 3],
              borderPadding: const EdgeInsets.all(8.0),
              strokeCap: StrokeCap.butt,
              radius: const Radius.circular(12.0),
              strokeWidth: 1,
              child: array.controls.isEmpty
                  ? SizedBox(
                      height: itemHeight,
                      child: const Center(
                        child: Text("Tap a field to add in your card."),
                      ),
                    )
                  : SorterList(
                      items: items,
                      onReorder: (value) {
                        widget.onReorder(value);
                      },
                    ));
        });
  }
}

class SorterList extends StatefulWidget {
  final Function(List<Map<String, dynamic>> value) onReorder;
  final List<FieldItem> items;
  const SorterList({super.key, required this.items, required this.onReorder});

  @override
  State<SorterList> createState() => _SorterListState();
}

class _SorterListState extends State<SorterList> {
  @override
  Widget build(BuildContext context) {
    int indexOfKey(Key key) {
      return widget.items.indexWhere((v) => v.orderKey == key);
    }

    bool reorderCallback(Key item, Key newPosition) {
      int draggingIndex = indexOfKey(item);
      int newPositionIndex = indexOfKey(newPosition);
      final draggedItem = widget.items[draggingIndex];
      debugPrint("Reordering $draggingIndex -> $newPositionIndex");
      setState(() {
        widget.items.removeAt(draggingIndex);
        widget.items.insert(newPositionIndex, draggedItem);
      });
      return true;
    }

    void reorderDone(Key item) {
      final draggedItem = widget.items[indexOfKey(item)];
      debugPrint("Reordering finished for ${draggedItem.index}");
      List<Map<String, dynamic>> reorderedItems = [];
      for (var i = 0; i < widget.items.length; i++) {
        reorderedItems.add(widget.items[i].data);
      }
      widget.onReorder(reorderedItems);
    }

    return ReorderableList(
      onReorder: reorderCallback,
      onReorderDone: reorderDone,
      decoratePlaceholder: (widget, decorationOpacity) {
        return DecoratedPlaceholder(
            offset: 0.0,
            widget: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                margin: EdgeInsets.zero,
                elevation: 5,
                child: widget));
      },
      child: CustomScrollView(
        shrinkWrap: true,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Padding(
                      padding: EdgeInsets.only(
                          bottom: index != widget.items.length - 1 ? 8.0 : 0.0),
                      child: widget.items[index]);
                },
                childCount: widget.items.length,
              ),
            ),
          )
        ],
      ),
    );
  }
}
