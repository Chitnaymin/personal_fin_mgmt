import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_fin_pwa/services/firestore_service.dart';

class ManagePeoplePage extends StatelessWidget {
  const ManagePeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    void showAddPersonDialog() {
      final TextEditingController controller = TextEditingController();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add Person'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Person\'s Name'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    firestoreService.addPerson(controller.text);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage People'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddPersonDialog,
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getBudget(), // Reusing this stream
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Go to Settings to initialize.'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> people = List<String>.from(data['people'] ?? []);

          if (people.isEmpty) return const Center(child: Text('No people added yet.'));

          return ListView.builder(
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              return ListTile(
                title: Text(person),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => firestoreService.deletePerson(person),
                ),
              );
            },
          );
        },
      ),
    );
  }
}