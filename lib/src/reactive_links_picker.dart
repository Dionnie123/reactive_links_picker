import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'fields_list/fields_list.dart';
import 'icons_list/icons_list.dart';
import 'link_types.dart';

FormGroup mapToFormGroup(Map<String, dynamic>? data) {
  return FormGroup({
    'id': FormControl<String>(value: "customLink-${UniqueKey()}"),
    'value': FormControl<String>(
      value: data?['value'],
      validators: [const RequiredValidator()],
    ),
    'custom': FormControl<String>(value: data?['custom']),
    'label': FormControl<String>(value: data?['label']),
  });
}

class LinksPicker extends StatefulWidget {
  final List<Map<String, dynamic>?> value;
  final Function(List<Map<String, dynamic>?>?) onValueChanged;

  const LinksPicker(
      {super.key, required this.onValueChanged, this.value = const []});

  @override
  State<LinksPicker> createState() => _LinksPickerState();
}

class _LinksPickerState extends State<LinksPicker> {
  FormGroup form = FormGroup({
    'customLinks': FormArray<Map<String, dynamic>>([]),
  });
  FormArray<Map<String, dynamic>> get customLinks =>
      form.control('customLinks') as FormArray<Map<String, dynamic>>;

  @override
  void initState() {
    for (var i = 0; i < widget.value.length; i++) {
      customLinks.add(mapToFormGroup(widget.value[i]));
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    customLinks.dispose();
    form.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 150),
              child: FieldsList(
                onUpdateAt: (index, link) {
                  customLinks.insert(index, mapToFormGroup(link.toJson()));
                  customLinks.removeAt(index);
                  widget.onValueChanged(customLinks.value);
                },
                onReorder: (value) async {
                  customLinks.clear();
                  for (var i = 0; i < value.length; i++) {
                    customLinks.add(mapToFormGroup(value[i]));
                  }
                  widget.onValueChanged(customLinks.value);
                },
                onRemovedAt: (index) {
                  customLinks.removeAt(index);
                  widget.onValueChanged(customLinks.value);
                },
              ),
            ),
            Container(
              height:
                  ((MediaQuery.of(context).size.height - kToolbarHeight) / 2) +
                      150,
              constraints: const BoxConstraints(minHeight: 150),
              child: IconsList(
                customLinks: linkTypes,
                onLinkCreated: (customLink) {
                  customLinks.add(mapToFormGroup(customLink.toJson()));
                  widget.onValueChanged(customLinks.value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReactiveLinksPicker extends ReactiveFormField<List<Map<String, dynamic>>,
    List<Map<String, dynamic>>> {
  ReactiveLinksPicker({
    Key? key,
    String? formControlName,
    FormControl<List<Map<String, dynamic>>>? formControl,
  }) : super(
          key: key,
          formControlName: formControlName,
          formControl: formControl,
          builder: (field) {
            return LinksPicker(
              value: field.value ?? [],
              onValueChanged: (customLinks) {
                final List<Map<String, dynamic>>? x =
                    customLinks?.cast<Map<String, dynamic>>();
                field.control.value = x ?? [];
                field.didChange;
                field.control.markAsDirty();
                field.control.updateValueAndValidity();
              },
            );
          },
        ) {
    if (this.formControlName == null && this.formControl == null) {
      assert(this.formControlName == null && this.formControl == null,
          'ReactiveLinksPicker requires atleast a formControlName or formControl');
    }
  }

  @override
  ReactiveFormFieldState<List<Map<String, dynamic>>, List<Map<String, dynamic>>>
      createState() => ReactiveFormFieldState<List<Map<String, dynamic>>,
          List<Map<String, dynamic>>>();
}
