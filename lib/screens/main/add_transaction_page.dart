import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_fin_pwa/models/transaction_model.dart';
import 'package:flutter_fin_pwa/services/auth_service.dart';
import 'package:flutter_fin_pwa/services/firestore_service.dart';
import 'package:flutter_fin_pwa/services/settings_provider.dart';

class AddTransactionPage extends StatefulWidget {
  final FinancialTransaction? transaction;
  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'outcome';
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _incomeCategories = ['Salary', 'Gifts', 'Investment'];
  final List<String> _outcomeCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toString();
      _notesController.text = t.notes ?? '';
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedDate = t.date;
    } else {
      _selectedCategory = _outcomeCategories.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final amount = double.tryParse(_amountController.text);
      if (amount == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final firestoreService = FirestoreService();

      final transaction = FinancialTransaction(
        id: widget.transaction?.id,
        userId: userId,
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        notes: _notesController.text,
        date: _selectedDate,
      );

      try {
        await firestoreService.saveTransaction(transaction);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save transaction: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _deleteTransaction() async {
    if (widget.transaction?.id != null) {
      // Show confirmation dialog before deleting
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Transaction?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        await FirestoreService().deleteTransaction(widget.transaction!.id!);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        _selectedType == 'income' ? _incomeCategories : _outcomeCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    final selectedCurrency =
        Provider.of<SettingsProvider>(context).selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteTransaction,
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ToggleButtons(
              isSelected: [_selectedType == 'outcome', _selectedType == 'income'],
              onPressed: (index) {
                setState(() {
                  _selectedType = index == 0 ? 'outcome' : 'income';
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Outcome')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Income'))
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${selectedCurrency.symbol} ',
                  border: const OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an amount' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                    value: category, child: Text(category));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                  labelText: 'Notes (Optional)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            // --- MODIFIED BUTTON ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _isLoading ? null : _saveTransaction,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Transaction'),
            )
          ],
        ),
      ),
    );
  }
}