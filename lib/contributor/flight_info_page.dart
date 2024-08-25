import 'package:flutter/material.dart';
import 'package:pathpal/data/airport_database.dart';
import 'package:pathpal/models/airport_model.dart';
import 'package:pathpal/contributor/contributor_form_state.dart';

class FlightInfoPage extends StatefulWidget {
  final ContributorFormState formState;
  final Function(String) onFlightNumberUpdated;
  final Function(String) onFlightNumberFirstLegUpdated;
  final Function(String) onFlightNumberSecondLegUpdated;
  final Function(int) onPartySizeUpdated;
  final Function(Airport) onDepartureAirportSelected;
  final Function(Airport) onArrivalAirportSelected;
  final Function(Airport) onLayoverAirportSelected;
  final Function(bool) onLayoverToggled;
  final Function(DateTime) onFlightDateTimeUpdated;

  const FlightInfoPage({
    super.key,
    required this.formState,
    required this.onFlightNumberUpdated,
    required this.onFlightNumberFirstLegUpdated,
    required this.onFlightNumberSecondLegUpdated,
    required this.onPartySizeUpdated,
    required this.onDepartureAirportSelected,
    required this.onArrivalAirportSelected,
    required this.onLayoverAirportSelected,
    required this.onLayoverToggled,
    required this.onFlightDateTimeUpdated,
  });

  @override
  _FlightInfoPageState createState() => _FlightInfoPageState();
}

class _FlightInfoPageState extends State<FlightInfoPage> {
  late TextEditingController _flightNumberController;
  late TextEditingController _flightNumberFirstLegController;
  late TextEditingController _flightNumberSecondLegController;

  @override
  void initState() {
    super.initState();
    _flightNumberController =
        TextEditingController(text: widget.formState.flightNumber);
    _flightNumberFirstLegController =
        TextEditingController(text: widget.formState.flightNumberFirstLeg);
    _flightNumberSecondLegController =
        TextEditingController(text: widget.formState.flightNumberSecondLeg);
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    _flightNumberFirstLegController.dispose();
    _flightNumberSecondLegController.dispose();
    super.dispose();
  }

  Widget _buildAirportSearch({
    required String hint,
    required IconData icon,
    required Function(Airport) onSelect,
    Airport? selectedAirport,
  }) {
    return SearchAnchor(
      viewBackgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context, SearchController controller) {
        if (selectedAirport != null && controller.text.isEmpty) {
          controller.text = selectedAirport.toString();
        }
        return SearchBar(
          controller: controller,
          padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0)),
          onTap: () {
            controller.openView();
          },
          onChanged: (_) {
            controller.openView();
          },
          leading: Icon(icon),
          hintText: hint,
          backgroundColor:
              WidgetStatePropertyAll(Theme.of(context).colorScheme.surface),
          elevation: const WidgetStatePropertyAll(0.0),
        );
      },
      suggestionsBuilder:
          (BuildContext context, SearchController controller) async {
        final airports =
            await AirportDatabase.instance.searchAirports(controller.text);
        return airports.map((airport) => ListTile(
              leading: const Icon(Icons.flight),
              title: Text(airport.name),
              subtitle:
                  Text('${airport.iata} - ${airport.city}, ${airport.country}'),
              onTap: () {
                onSelect(airport);
                controller.closeView(airport.toString());
                setState(() {});
              },
            ));
      },
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.formState.flightDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialEntryMode: TimePickerEntryMode.input,
        initialTime:
            TimeOfDay.fromDateTime(widget.formState.flightDateTime ?? now),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: const TimePickerThemeData(
                dayPeriodColor: Color.fromARGB(255, 180, 221, 255),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        widget.onFlightDateTimeUpdated(pickedDateTime);
      }
    }
  }

  void _handleFlightNumberChange(String value,
      {bool isFirstLeg = false, bool isSecondLeg = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (widget.formState.isValidFlightNumber(value)) {
      if (isFirstLeg) {
        widget.onFlightNumberFirstLegUpdated(value);
      } else if (isSecondLeg) {
        widget.onFlightNumberSecondLegUpdated(value);
      } else {
        widget.onFlightNumberUpdated(value);
      }
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Flight number must contain at least two letters.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _flightNumberController.text = widget.formState.flightNumber;
    _flightNumberFirstLegController.text =
        widget.formState.flightNumberFirstLeg;
    _flightNumberSecondLegController.text =
        widget.formState.flightNumberSecondLeg;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('My trip has a layover'),
              value: widget.formState.hasLayover,
              onChanged: (value) {
                if (value != null) {
                  widget.onLayoverToggled(value);
                }
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Departure Airport',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            _buildAirportSearch(
              hint: 'Select departure airport',
              icon: Icons.flight_takeoff,
              onSelect: (airport) {
                widget.onDepartureAirportSelected(airport);
                setState(() {});
              },
              selectedAirport: widget.formState.departureAirport,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Arrival Airport',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            _buildAirportSearch(
              hint: 'Select arrival airport',
              icon: Icons.flight_land,
              onSelect: (airport) {
                widget.onArrivalAirportSelected(airport);
                setState(() {});
              },
              selectedAirport: widget.formState.arrivalAirport,
            ),
            if (widget.formState.hasLayover)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),
                  const Text(
                    'Layover Airport',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8.0),
                  _buildAirportSearch(
                    hint: 'Select layover airport',
                    icon: Icons.flight,
                    onSelect: (airport) {
                      widget.onLayoverAirportSelected(airport);
                      setState(() {});
                    },
                    selectedAirport: widget.formState.layoverAirport,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            if (!widget.formState.hasLayover)
              TextFormField(
                controller: _flightNumberController,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Flight Number with airline code',
                  hintText: 'Enter your flight number with airline code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _handleFlightNumberChange(value),
              ),
            if (widget.formState.hasLayover) ...[
              TextFormField(
                controller: _flightNumberFirstLegController,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Flight Number (First Leg) with airline code',
                  hintText:
                      'Enter your first leg flight number with airline code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    _handleFlightNumberChange(value, isFirstLeg: true),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _flightNumberSecondLegController,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Flight Number (Second Leg) with airline code',
                  hintText:
                      'Enter your second leg flight number with airline code',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    _handleFlightNumberChange(value, isSecondLeg: true),
              ),
            ],
            const SizedBox(height: 16.0),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: widget.formState.flightDateTime != null
                    ? "${widget.formState.flightDateTime!.toLocal().toString().split(' ')[0]} ${TimeOfDay.fromDateTime(widget.formState.flightDateTime!).format(context)}"
                    : '',
              ),
              decoration: const InputDecoration(
                labelText: 'Flight Date and Time',
                hintText: 'Select your flight date and time',
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDateTime(context),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              initialValue: widget.formState.partySize.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of People',
                hintText: 'Enter the number of people traveling with you',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final size = int.tryParse(value);
                if (size != null) {
                  widget.onPartySizeUpdated(size);
                }
              },
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Note: Your flight information will be shared with receivers to help them decide who to travel with.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
