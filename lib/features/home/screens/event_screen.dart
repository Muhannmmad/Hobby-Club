import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  EventScreenState createState() => EventScreenState();
}

class EventScreenState extends State<EventScreen> {
  List<dynamic> events = [];
  bool isLoading = false;
  String selectedCity = "";

  Future<void> fetchEvents(String city) async {
    setState(() {
      isLoading = true;
      events = [];
    });

    const String apiKey =
        'c51638313e87fe63d37dd25ad025c1c9192220bb8422d55cc55df306af042c0a';
    final String query = 'Events in $city';

    try {
      final response = await http.get(
        Uri.parse(
            'https://serpapi.com/search.json?engine=google_events&q=$query&hl=en&gl=us&api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          events = data['events_results'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events Near You')),
      body: selectedCity.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      backgroundColor: const Color.fromARGB(205, 67, 7, 82),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      final city = await _selectCityDialog(context);
                      if (city != null && city.isNotEmpty) {
                        setState(() {
                          selectedCity = city;
                        });
                        fetchEvents(city);
                      }
                    },
                    child: const Text(
                      'Choose City',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      backgroundColor: const Color.fromARGB(255, 28, 155, 101),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateEventScreen()),
                      );
                    },
                    child: const Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : events.isEmpty
                  ? const Center(child: Text('No events found'))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          title: Text(event['title'] ?? 'No Title'),
                          subtitle:
                              Text(event['date']['start_date'] ?? 'No Date'),
                        );
                      },
                    ),
      floatingActionButton: selectedCity.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateEventScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<String?> _selectCityDialog(BuildContext context) async {
    TextEditingController cityController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter City'),
          content: TextField(
            controller: cityController,
            decoration: const InputDecoration(hintText: 'City name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, cityController.text);
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class CreateEventScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Event Title'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Event Date'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Event Description'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final date = dateController.text;
                final description = descriptionController.text;

                Navigator.pop(context);
              },
              child: const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
