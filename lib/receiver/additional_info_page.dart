import 'package:flutter/material.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';

class AdditionalInfoPage extends StatefulWidget {
  final ReceiverFormState formState;
  final Function(String) onReasonUpdated;
  final Function(int) onPartySizeUpdated;

  const AdditionalInfoPage({
    super.key,
    required this.formState,
    required this.onReasonUpdated,
    required this.onPartySizeUpdated,
  });

  @override
  _AdditionalInfoPageState createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  String? selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if ([
      'I am elderly',
      'I am a single parent flying with kids',
      'I need company'
    ].contains(widget.formState.reason)) {
      selectedReason = widget.formState.reason;
    } else {
      selectedReason = 'Other';
      _otherReasonController.text = widget.formState.reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Additional Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Reason for assistance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              DropdownButtonFormField<String>(
                dropdownColor: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                value: selectedReason,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: (widget.formState.submitted ||
                              widget.formState.reasonTouched) &&
                          !widget.formState.isReasonValid()
                      ? 'Reason is required'
                      : null,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'I am elderly', child: Text('I am elderly')),
                  DropdownMenuItem(
                      value: 'I am a single parent flying with kids',
                      child: Text('I am a single parent flying with kids')),
                  DropdownMenuItem(
                      value: 'I need company', child: Text('I need company')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                    widget.formState.touchReason();
                    if (value != 'Other') {
                      widget.onReasonUpdated(value ?? '');
                    }
                  });
                },
              ),
              if (selectedReason == 'Other')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _otherReasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Please provide a short description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      widget.formState.touchReason();
                      widget.onReasonUpdated(value);
                    },
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'This description will be shown to potential volunteer contributors.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('Number of people in your party',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              TextFormField(
                initialValue: widget.formState.partySize.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter the number of people',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  widget.formState.touchPartySize();
                  final size = int.tryParse(value);
                  if (size != null) {
                    widget.onPartySizeUpdated(size);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
