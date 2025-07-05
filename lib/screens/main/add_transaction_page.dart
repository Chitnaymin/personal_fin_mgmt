import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

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
  late bool _isEditMode;
  late FinancialTransaction _displayTransaction;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'outcome';
  String? _selectedCategory;
  String? _selectedPerson;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _existingImageBase64;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transaction == null;

    if (widget.transaction != null) {
      _displayTransaction = widget.transaction!;
      _populateControllersFromTransaction(widget.transaction!);
    } else {
      _displayTransaction = FinancialTransaction(
        amount: 0,
        type: 'outcome',
        category: '',
        person: '',
        date: DateTime.now(),
      );
    }
  }

  void _populateControllersFromTransaction(FinancialTransaction t) {
    _amountController.text = t.amount.toStringAsFixed(2);
    _notesController.text = t.notes ?? '';
    _selectedType = t.type;
    _selectedCategory = t.category;
    _selectedPerson = t.person;
    _selectedDate = t.date;
    _existingImageBase64 = t.receiptImageBase64;
    _selectedImageBytes = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode
            ? (widget.transaction == null ? 'Add Transaction' : 'Edit Transaction')
            : 'Transaction Details'),
        actions: [
          if (widget.transaction != null && !_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Transaction',
              onPressed: () => setState(() => _isEditMode = true),
            ),
          if (widget.transaction != null && _isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Transaction',
              onPressed: deleteTransaction,
            ),
        ],
      ),
      body: _isEditMode ? _buildEditView() : _buildReadOnlyView(),
    );
  }

  // --- R E A D - O N L Y   V I E W ---
  Widget _buildReadOnlyView() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final currency = settings.selectedCurrency;
    final isIncome = _displayTransaction.type == 'income';
    final amountColor = isIncome ? Colors.green : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  _displayTransaction.category,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.currency(locale: currency.locale, symbol: currency.symbol).format(_displayTransaction.amount),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: amountColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              _buildDetailTile(Icons.person_outline, "Person", _displayTransaction.person),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildDetailTile(Icons.calendar_today_outlined, "Date", DateFormat.yMMMMd().format(_displayTransaction.date)),
              if (_displayTransaction.notes != null && _displayTransaction.notes!.isNotEmpty)
                const Divider(height: 1, indent: 16, endIndent: 16),
              if (_displayTransaction.notes != null && _displayTransaction.notes!.isNotEmpty)
                _buildDetailTile(Icons.notes_outlined, "Notes", _displayTransaction.notes!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_displayTransaction.receiptImageBase64 != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildReceiptSection(),
          ),
      ],
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  // --- E D I T   V I E W ---
  Widget _buildEditView() {
    final selectedCurrency = Provider.of<SettingsProvider>(context).selectedCurrency;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getBudget(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List<String> incomeCategories = List<String>.from(data['incomeCategories'] ?? ['Salary']);
        final List<String> outcomeCategories = List<String>.from(data['outcomeCategories'] ?? ['Food']);
        final List<String> people = List<String>.from(data['people'] ?? ['Me']);
        final categories = _selectedType == 'income' ? incomeCategories : outcomeCategories;

        if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
          _selectedCategory = categories.isNotEmpty ? categories.first : null;
        }
        if (_selectedPerson == null || !people.contains(_selectedPerson)) {
          _selectedPerson = people.isNotEmpty ? people.first : null;
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ToggleButtons(
                isSelected: [_selectedType == 'outcome', _selectedType == 'income'],
                onPressed: (index) => setState(() {
                  _selectedType = index == 0 ? 'outcome' : 'income';
                  _selectedCategory = null;
                }),
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Outcome')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Income'))
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount', prefixText: '${selectedCurrency.symbol} ', border: const OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Please enter an amount' : null,
              ),
              const SizedBox(height: 20),
              if (_selectedCategory != null)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Please select a category' : null,
                ),
              const SizedBox(height: 20),
              if (_selectedPerson != null)
                DropdownButtonFormField<String>(
                  value: _selectedPerson,
                  decoration: const InputDecoration(labelText: 'Person', border: OutlineInputBorder()),
                  items: people.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _selectedPerson = v),
                  validator: (v) => v == null ? 'Please select a person' : null,
                ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildReceiptSection(),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size.fromHeight(50)),
                onPressed: _isLoading ? null : saveTransaction,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.transaction == null ? 'Save Transaction' : 'Update Transaction'),
              )
            ],
          ),
        );
      },
    );
  }

  // --- H E L P E R S   &   L O G I C ---

  Widget _buildReceiptSection() {
    Uint8List? imageBytes;
    if (_selectedImageBytes != null) {
      imageBytes = _selectedImageBytes;
    } else if (_existingImageBase64 != null) {
      imageBytes = base64Decode(_existingImageBase64!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
          child: Text('Receipt', style: Theme.of(context).textTheme.titleMedium),
        ),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade400)
          ),
          child: GestureDetector(
            onTap: (imageBytes == null || _isEditMode) ? null : () => _showFullScreenImage(imageBytes!),
            child: imageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    // --- The loadingBuilder has been removed ---
                  ),
                )
              : const Center(child: Text('No receipt uploaded')),
          ),
        ),
        const SizedBox(height: 10),
        if (_isEditMode)
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload New Receipt'),
              onPressed: _pickImage,
            ),
          ),
      ],
    );
  }

  void _showFullScreenImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(imageBytes),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _existingImageBase64 = null;
      });
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

  void saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null || _selectedPerson == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category and person.')));
        return;
      }
      setState(() => _isLoading = true);
      
      final amount = double.tryParse(_amountController.text);
      if (amount == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userId = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      final transactionId = widget.transaction?.id ?? _firestoreService.getNewTransactionId();
      String? receiptBase64;

      if (_selectedImageBytes != null) {
        receiptBase64 = base64Encode(_selectedImageBytes!);
      } else {
        receiptBase64 = _existingImageBase64;
      }
      
      final newTransactionData = FinancialTransaction(
        id: transactionId,
        userId: userId,
        amount: amount,
        type: _selectedType,
        category: _selectedCategory!,
        person: _selectedPerson!,
        notes: _notesController.text,
        date: _selectedDate,
        receiptImageBase64: receiptBase64,
      );

      try {
        await _firestoreService.saveTransaction(newTransactionData);
        if (mounted) {
          if (widget.transaction != null) {
            setState(() {
              _displayTransaction = newTransactionData;
              _isEditMode = false;
            });
          } else {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save transaction: ${e.toString()}')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void deleteTransaction() async {
    if (widget.transaction?.id != null) {
      final bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          );
        },
      );
      if (confirmDelete == true) {
        try {
          await _firestoreService.deleteTransaction(widget.transaction!.id!);
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete transaction: ${e.toString()}')));
          }
        }
      }
    }
  }
}