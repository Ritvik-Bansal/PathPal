import 'package:flutter/material.dart';
import 'package:pathpal/data/airport_database.dart';
import 'package:pathpal/models/airport_model.dart';
import 'package:pathpal/receiver/receiver_form_state.dart';

class AirportSelectionPage extends StatelessWidget {
  final ReceiverFormState formState;
  final Function(Airport) onStartAirportSelected;
  final Function(Airport) onEndAirportSelected;

  const AirportSelectionPage({
    super.key,
    required this.formState,
    required this.onStartAirportSelected,
    required this.onEndAirportSelected,
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
              'Select Your Airports',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Departure Airport',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            _buildAirportSearch(
                hint: 'Select departure airport',
                icon: Icons.flight_takeoff,
                onSelect: onStartAirportSelected,
                selectedAirport: formState.startAirport,
                context: context),
            const SizedBox(height: 24.0),
            const Text(
              'Arrival Airport',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            _buildAirportSearch(
                hint: 'Select arrival airport',
                icon: Icons.flight_land,
                onSelect: onEndAirportSelected,
                selectedAirport: formState.endAirport,
                context: context),
          ],
        ),
      ),
    );
  }

  Widget _buildAirportSearch({
    required String hint,
    required IconData icon,
    required Function(Airport) onSelect,
    required BuildContext context,
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
            if (hint.contains('departure')) {
              formState.touchStartAirport();
            } else {
              formState.touchEndAirport();
            }
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
              },
            ));
      },
    );
  }
}
