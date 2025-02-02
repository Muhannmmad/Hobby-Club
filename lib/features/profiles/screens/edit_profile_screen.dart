import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_state_city_pro/country_state_city_pro.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/profiles/screens/my_profile_screen.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController hobbiesController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _profileImage;
  String? _profileImageUrl;
  bool isLoading = false;

  String? selectedGender;
  String? selectedAge;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<String> ageOptions =
      List.generate(91, (index) => (index + 10).toString());
  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          hobbiesController.text = data['hobbies'] ?? '';
          aboutController.text = data['about'] ?? '';

          selectedAge = ageOptions.contains(data['age']) ? data['age'] : null;
          selectedGender =
              genderOptions.contains(data['gender']) ? data['gender'] : null;

          countryController.text = data['country'] ?? '';
          stateController.text = data['state'] ?? '';
          cityController.text = data['city'] ?? '';

          _profileImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _profileImageUrl =
              null; // Clear the existing URL when a new image is picked
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> removeImage() async {
    setState(() {
      _profileImage = null;
      _profileImageUrl = null;
    });
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String? imageUrl = _profileImageUrl;
      if (_profileImage != null) {
        final ref = _storage.ref().child(
            'profile_pictures/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = ref.putFile(_profileImage!);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(widget.userId).set({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'age': selectedAge,
        'gender': selectedGender,
        'country': countryController.text,
        'state': stateController.text,
        'city': cityController.text,
        'hobbies': hobbiesController.text,
        'about': aboutController.text,
        'profileImage': imageUrl,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyProfileScreen()),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),
              GestureDetector(
                onTap: pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null),
                      child: _profileImage == null && _profileImageUrl == null
                          ? Icon(Icons.person,
                              size: 50, color: Colors.grey[700])
                          : null,
                    ),
                    if (_profileImage != null || _profileImageUrl != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: removeImage,
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to upload Profile Pic',
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: firstNameController,
                            label: 'First Name',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: buildTextField(
                            controller: lastNameController,
                            label: 'Last Name',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    buildDropdown(
                      label: 'Age',
                      value: selectedAge,
                      items: ageOptions,
                      onChanged: (val) => setState(() => selectedAge = val),
                    ),
                    const SizedBox(height: 12),
                    buildDropdown(
                      label: 'Gender',
                      value: selectedGender,
                      items: genderOptions,
                      onChanged: (val) => setState(() => selectedGender = val),
                    ),
                    const SizedBox(height: 12),
                    CountryStateCityPicker(
                      country: countryController,
                      state: stateController,
                      city: cityController,
                    ),
                    const SizedBox(height: 12),
                    buildTextField(
                        controller: hobbiesController, label: 'Hobbies'),
                    const SizedBox(height: 12),
                    buildTextField(
                        controller: aboutController,
                        label: 'About me',
                        isMultiLine: true),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save changes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // **Added buildTextField**
  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: isMultiLine ? 5 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  // **Added buildDropdown**
  Widget buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
