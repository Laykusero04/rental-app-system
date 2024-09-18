import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';

class AddHouse extends StatefulWidget {
  final String? houseId;
  final Map<String, dynamic>? houseData;

  const AddHouse({Key? key, this.houseId, this.houseData}) : super(key: key);

  @override
  _AddHouseState createState() => _AddHouseState();
}

class _AddHouseState extends State<AddHouse> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  TextEditingController _houseNumberController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _contactNumberController = TextEditingController();
  String? _selectedHouseType;
  File? _imageFile;
  String? _currentImageUrl;
  bool _isImagePickerAvailable = true;

  @override
  void initState() {
    super.initState();
    _houseNumberController.text = widget.houseData?['houseNumber'] ?? '';
    _descriptionController.text = widget.houseData?['description'] ?? '';
    _priceController.text = widget.houseData?['price']?.toString() ?? '';
    _contactNumberController.text = widget.houseData?['contactNumber'] ?? '';
    _selectedHouseType = widget.houseData?['houseType'];
    _currentImageUrl = widget.houseData?['imageUrl'];
    _checkImagePickerAvailability();
  }

  Future<void> _checkImagePickerAvailability() async {
    try {
      await _imagePicker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      setState(() {
        _isImagePickerAvailable = false;
      });
      print('Image picker is not available: $e');
    }
  }

  Future<void> _pickImage() async {
    if (!_isImagePickerAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Image picker is not available on this device.')),
      );
      return;
    }

    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.houseId == null ? 'Add House' : 'Edit House'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImagePicker(),
                SizedBox(height: 24),
                _buildTextFormField(
                  controller: _houseNumberController,
                  label: 'House Number',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a house number' : null,
                ),
                SizedBox(height: 16),
                _buildHouseTypeDropdown(),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: _descriptionController,
                  label: 'Description',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: _priceController,
                  label: 'Price',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter a price';
                    if (double.tryParse(value) == null)
                      return 'Please enter a valid number';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTextFormField(
                  controller: _contactNumberController,
                  label: 'Contact Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a contact number' : null,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(
                    widget.houseId == null ? 'Add House' : 'Update House',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : _currentImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_currentImageUrl!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Add House Image',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildHouseTypeDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getHouseTypes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        List<DropdownMenuItem<String>> houseTypeItems = snapshot.data!.docs
            .map((doc) => DropdownMenuItem<String>(
                  value: doc['type'],
                  child: Text(doc['type']),
                ))
            .toList();

        return DropdownButtonFormField<String>(
          value: _selectedHouseType,
          items: houseTypeItems,
          onChanged: (value) {
            setState(() {
              _selectedHouseType = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'House Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) =>
              value == null ? 'Please select a house type' : null,
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        Map<String, dynamic> houseData = {
          'houseNumber': _houseNumberController.text,
          'houseType': _selectedHouseType,
          'description': _descriptionController.text,
          'price': _priceController.text,
          'contactNumber': _contactNumberController.text,
        };

        if (widget.houseId == null) {
          await _firebaseService.addHouse(houseData, _imageFile);
        } else {
          await _firebaseService.updateHouse(
              widget.houseId!, houseData, _imageFile);
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }
}
