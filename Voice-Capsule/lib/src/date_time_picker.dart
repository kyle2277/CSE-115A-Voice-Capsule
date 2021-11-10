import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

class BasicDateField extends StatelessWidget {
  final format = DateFormat("yyyy-MM-dd");
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Text('Basic date field (${format.pattern})'),
      DateTimeField(
        format: format,
        onShowPicker: (context, currentValue) {
          return showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              initialDate: currentValue ?? DateTime.now(),
              lastDate: DateTime(2100));
        },
      ),
    ]);
  }
}

class BasicDateTimeField extends StatefulWidget {
  BasicDateTimeField({
   required this.currentSelection,
  });
  DateTime? currentSelection;
  @override
  _BasicDateTimeFieldState createState() => _BasicDateTimeFieldState();
}

class _BasicDateTimeFieldState extends State<BasicDateTimeField> {

  final format = DateFormat("MM-dd-yyyy, hh:mm a");
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Text(
        'Choose date to open:',
        textScaleFactor: 1.25,
      ),
      DateTimeField(
        format: format,
        onShowPicker: (context, currentValue) async {
          final date = await showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              initialDate: currentValue ?? DateTime.now(),
              lastDate: DateTime(2100));
          if (date != null) {
            final time = await showTimePicker(
              context: context,
              initialTime:
              TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
            );
            DateTime fieldValue = DateTimeField.combine(date, time);
            setState(() {
              widget.currentSelection = fieldValue;
            });
            return fieldValue;
          } else {
            setState(() {
              widget.currentSelection = currentValue;
            });
            return currentValue;
          }
        },
      ),
    ]);
  }
}