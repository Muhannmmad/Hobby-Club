import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hoppy_club/features/home/screens/home_screen.dart';
import 'package:hoppy_club/features/profiles/screens/settings.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId; // Pass the userId for profile editing

  const EditProfileScreen({super.key, required this.userId});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController townController = TextEditingController();
  final TextEditingController hobbiesController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  File? _profileImage;
  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
          nameController.text = data['name'] ?? '';
          ageController.text = data['age'] ?? '';
          genderController.text = data['gender'] ?? '';
          townController.text = data['town'] ?? '';
          hobbiesController.text = data['hobbies'] ?? '';
          aboutController.text = data['about'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      } else {
        debugPrint('No image selected.');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<String?> uploadImage(File image) async {
    try {
      final ref = _storage.ref().child(
          'profile_pictures/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final UploadTask uploadTask = ref.putFile(image);

      final TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Image upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> saveProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await uploadImage(_profileImage!);
      }

      await _firestore.collection('users').doc(widget.userId).set({
        'name': nameController.text,
        'age': ageController.text,
        'gender': genderController.text,
        'town': townController.text,
        'hobbies': hobbiesController.text,
        'about': aboutController.text,
        'profileImage': imageUrl,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingScreen(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.menu,
              color: Colors.black,
            ),
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 100),
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[700],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap to upload Profile Pic',
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              buildTextField(controller: nameController, label: 'Name'),
              buildTextField(controller: ageController, label: 'Age'),
              buildTextField(controller: genderController, label: 'Gender'),
              buildTextField(controller: townController, label: 'Town'),
              buildTextField(controller: hobbiesController, label: 'Hobbies'),
              const SizedBox(height: 10),
              buildTextField(
                  controller: aboutController,
                  label: 'About me',
                  isMultiLine: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        maxLines: isMultiLine ? 5 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}
