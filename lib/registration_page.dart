import 'package:flutter/material.dart';
import 'package:cargo/header_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _firebaseInitialized = false;
  String? _avatarFileName;
  String? _avatarFileBase64;
  double _uploadProgress = 0.0;
  String? _initializationError;
  // Removed role selection since we only have 'shipper'

  @override
  void initState() {
    super.initState();
    _checkFirebaseInitialization();
  }

  Future<void> _checkFirebaseInitialization() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        setState(() {
          _firebaseInitialized = true;
        });
        print("Firebase is already initialized");
      } else {
        setState(() {
          _initializationError = "Firebase not initialized. Please restart the app.";
        });
      }
    } catch (e) {
      setState(() {
        _initializationError = e.toString();
      });
    }
  }

  Future<void> _pickAndEncodeImage() async {
    try {
      Uint8List? imageBytes;
      String fileName = 'avatar.jpg';

      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result == null || result.files.isEmpty) return;
        imageBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      } else {
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 70,
        );
        if (pickedFile == null) return;
        imageBytes = await pickedFile.readAsBytes();
        fileName = pickedFile.name;
      }

      if (imageBytes == null) {
        throw Exception('Failed to process image');
      }

      if (imageBytes.length > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Image too large. Please select a smaller image.')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final String base64Image = base64Encode(imageBytes);
      
      setState(() {
        _avatarFileName = fileName;
        _avatarFileBase64 = base64Image;
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Avatar image ready! (${(imageBytes.length / 1024).toStringAsFixed(0)}KB)')),
      );

    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Image selection failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_firebaseInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase not initialized. Please check your configuration.')),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });

      print("Attempting to create user with email: ${_emailController.text.trim()}");

      // 1. Create user with Firebase Auth
      final userCredential = 
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String userId = userCredential.user!.uid;
      print("User created successfully with UID: $userId");

      // Add a small delay to ensure user is properly created
      await Future.delayed(const Duration(milliseconds: 300));

      print("Attempting to save user data to Firestore");
      
      // 2. Store user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'firebase_uid': userId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'shipper', // Fixed to 'shipper' only
        'avatar': _avatarFileBase64 != null ? 'data:image/jpeg;base64,$_avatarFileBase64' : null,
        'created_at': DateTime.now().toIso8601String(),
        'last_seen': null,
        'created_by': null, // Set to null as this is a registration
      });

      print("User data saved to Firestore successfully");

      // 3. Send email verification
      await userCredential.user!.sendEmailVerification();
      print("Verification email sent");

      // 4. Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful!'),
            content: const Text('Your account has been created. Please check your email for verification.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 8 characters.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e, stackTrace) {
      print("Unexpected error: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Firebase Configuration Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _initializationError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please check your Firebase configuration and try again.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (!_firebaseInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Checking Firebase initialization...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AppHeader(),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFAFBFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "Create Shipper Account",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Be Part of the Future of Delivery",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.person_outline,
                            size: 20,
                            color: Color(0xFF3B82F6),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Personal Details",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _firstNameController,
                      label: "First Name",
                      hint: "Enter your first name",
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _lastNameController,
                      label: "Last Name",
                      hint: "Enter your last name",
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      hint: "Enter your email",
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    _buildPasswordField(
                      controller: _passwordController,
                      label: "Password",
                      hint: "Create a password (min 8 chars)",
                      isVisible: _isPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      hint: "Confirm your password",
                      isVisible: _isConfirmPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      "Profile Avatar (Optional)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: _avatarFileName ?? "Upload profile picture (optional)",
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.photo_camera,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                  ),
                            onPressed: _isUploading ? null : _pickAndEncodeImage,
                          ),
                        ),
                      ],
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                    if (_avatarFileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded: $_avatarFileName',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Back",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isLoading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                await _registerUser();
                              }
                            },
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Confirm",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorMaxLines: 2,
          ),
          validator: validator ?? (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your ${label.toLowerCase()}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF64748B),
              ),
              onPressed: onVisibilityToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorMaxLines: 2,
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}