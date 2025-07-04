import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_fin_pwa/services/firestore_service.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  // Function to show the "Add Category" dialog
  void _showAddCategoryDialog(BuildContext context, String type) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${type == 'income' ? 'Income' : 'Outcome'} Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _firestoreService.addCategory(controller.text, type);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getBudget(), // We reuse getBudget as it streams the whole user doc
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No categories found. Go to Settings to initialize.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> incomeCategories = List<String>.from(data['incomeCategories'] ?? []);
          final List<String> outcomeCategories = List<String>.from(data['outcomeCategories'] ?? []);

          return ListView(
            children: [
              _buildCategoryList(
                context,
                'Income Categories',
                incomeCategories,
                'income',
              ),
              const Divider(),
              _buildCategoryList(
                context,
                'Outcome Categories',
                outcomeCategories,
                'outcome',
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper widget to build a list of categories
  Widget _buildCategoryList(BuildContext context, String title, List<String> categories, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showAddCategoryDialog(context, type),
                ),
              ],
            ),
          ),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No custom categories yet. Add one!'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _firestoreService.deleteCategory(category, type),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}