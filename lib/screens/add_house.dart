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

  late TextEditingController _houseNumberController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  String? _selectedHouseType;
  File? _imageFile;
  String? _currentImageUrl;
  bool _isImagePickerAvailable = true;

  @override
  void initState() {
    super.initState();
    _houseNumberController =
        TextEditingController(text: widget.houseData?['houseNumber'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.houseData?['description'] ?? '');
    _priceController =
        TextEditingController(text: widget.houseData?['price'] ?? '');
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
      appBar: AppBar(
        title: Text(widget.houseId == null ? 'Add House' : 'Edit House'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : _currentImageUrl != null
                        ? Image.network(_currentImageUrl!, fit: BoxFit.cover)
                        : Icon(Icons.add_a_photo, size: 50),
              ),
            ),
            if (!_isImagePickerAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Image picker is not available on this device.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 16),
            TextFormField(
              controller: _houseNumberController,
              decoration: InputDecoration(labelText: 'House Number'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a house number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getHouseTypes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                List<DropdownMenuItem<String>> houseTypeItems =
                    snapshot.data!.docs
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
                  decoration: InputDecoration(labelText: 'House Type'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a house type';
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child:
                  Text(widget.houseId == null ? 'Add House' : 'Update House'),
            ),
          ],
        ),
      ),
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
    super.dispose();
  }
}
