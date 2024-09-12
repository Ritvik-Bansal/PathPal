import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';

class DateSelectionPage extends StatelessWidget {
  final ReceiverFormState formState;
  final Function(String) onDateRangeSelected;

  const DateSelectionPage({
    super.key,
    required this.formState,
    required this.onDateRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dates of Travel',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller:
                  TextEditingController(text: formState.selectedDateRange),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Please select your preferred dates of travel',
                errorText:
                    (formState.submitted || formState.dateRangeTouched) &&
                            !formState.isDateRangeValid()
                        ? 'Date range is required'
                        : null,
              ),
              onTap: () {
                formState.touchDateRange();
                _pickDateRange(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Theme.of(context).colorScheme.primaryContainer,
            colorScheme: Theme.of(context).colorScheme,
            scaffoldBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String formattedStartDate = formatter.format(picked.start);
      final String formattedEndDate = formatter.format(picked.end);
      final dateRange = '$formattedStartDate - $formattedEndDate';
      onDateRangeSelected(dateRange);
    }
  }
}
