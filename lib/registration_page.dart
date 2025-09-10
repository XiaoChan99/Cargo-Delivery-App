import 'package:flutter/material.dart';
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
  final _licenseNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _firebaseInitialized = false;
  String? _avatarFileName;
  String? _avatarFileBase64;
  String? _licenseFileName;
  String? _licenseFileBase64;
  double _uploadProgress = 0.0;
  String? _initializationError;
  int _currentStep = 0;
  String? _selectedRole; // No default role - user must choose

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

  Future<void> _pickAndEncodeImage({bool isLicense = false}) async {
    try {
      Uint8List? imageBytes;
      String fileName = isLicense ? 'license.jpg' : 'avatar.jpg';

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
        if (isLicense) {
          _licenseFileName = fileName;
          _licenseFileBase64 = base64Image;
        } else {
          _avatarFileName = fileName;
          _avatarFileBase64 = base64Image;
        }
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${isLicense ? 'License' : 'Avatar'} image ready! (${(imageBytes.length / 1024).toStringAsFixed(0)}KB)')),
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
    
    // Validate role selection
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role (Shipper or Courier)')),
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
      Map<String, dynamic> userData = {
        'firebase_uid': userId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': _selectedRole,
        'avatar': _avatarFileBase64 != null ? 'data:image/jpeg;base64,$_avatarFileBase64' : null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_seen': null,
        'status': 'pending', // pending, approved, rejected
        'is_active': true,
      };
      
      // Add courier-specific fields if role is courier
      if (_selectedRole == 'courier') {
        userData['license_number'] = _licenseNumberController.text.trim();
        userData['license_image'] = _licenseFileBase64 != null ? 'data:image/jpeg;base64,$_licenseFileBase64' : null;
        userData['courier_status'] = 'pending_verification'; // pending_verification, verified, rejected
      }

      // Determine the collection based on role
      String collectionName = _selectedRole == 'courier' ? 'Couriers' : 'Shippers';
      
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(userId)
          .set(userData);

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

  // Role selection widget
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Your Role*",
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
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRole = 'Shipper';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'Shipper' 
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedRole == 'Shipper' 
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: _selectedRole == 'Shipper' 
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Shipper",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRole = 'courier';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'courier' 
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedRole == 'courier' 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        color: _selectedRole == 'courier' 
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Courier",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedRole == null) ...[
          const SizedBox(height: 8),
          const Text(
            'Please select a role',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  // Step 0: Role selection
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text(
                "Create Your Account",
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
                "Role Selection",
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
        
        _buildRoleSelector(),
        const SizedBox(height: 32),
        
        Text(
          _selectedRole == 'Shipper' 
            ? "As a Shipper, you can create and manage delivery requests for your packages."
            : _selectedRole == 'courier'
              ? "As a Courier, you can accept and fulfill delivery requests to earn money."
              : "Please select whether you want to ship packages or deliver them.",
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Step 1: Basic information
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Tell us about yourself",
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
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _phoneController,
          label: "Phone Number",
          hint: "Enter your phone number",
          icon: Icons.phone_outlined,
          iconColor: const Color(0xFF10B981),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _addressController,
          label: "Address",
          hint: "Enter your address",
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFFEF4444),
          keyboardType: TextInputType.streetAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
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
                onPressed: _isUploading ? null : () => _pickAndEncodeImage(isLicense: false),
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
      ],
    );
  }

  // Step 2: Courier-specific information
  Widget _buildStep2() {
    if (_selectedRole != 'courier') {
      return _buildConfirmationStep();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text(
                "Courier Information",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Complete your courier profile",
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
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              Icon(
                Icons.directions_car_outlined,
                size: 20,
                color: Color(0xFF10B981),
              ),
              SizedBox(width: 8),
              Text(
                "Courier Details",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        _buildTextField(
          controller: _licenseNumberController,
          label: "Driver License Number",
          hint: "Enter your license number",
          icon: Icons.card_membership_outlined,
          iconColor: const Color(0xFF10B981),
          validator: (value) {
            if (_selectedRole == 'courier' && (value == null || value.isEmpty)) {
              return 'Please enter your license number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        Text(
          "Driver License Photo",
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
                  hintText: _licenseFileName ?? "Upload driver license photo",
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF10B981),
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
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
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
                color: const Color(0xFF10B981),
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
                onPressed: _isUploading ? null : () => _pickAndEncodeImage(isLicense: true),
              ),
            ),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
        if (_licenseFileName != null) ...[
          const SizedBox(height: 8),
          Text(
            'Uploaded: $_licenseFileName',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          "Note: Your driver license will be verified before you can start accepting deliveries.",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Step 3: Confirmation step
  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Column(
            children: [
              Text(
                "Review Your Information",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Please verify your details before submitting",
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
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: Color(0xFF8B5CF6),
              ),
              SizedBox(width: 8),
              Text(
                "Confirmation",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6),
                ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Role confirmation
        _buildConfirmationItem(
          label: "Role",
          value: _selectedRole == 'Shipper' ? "Shipper" : "Courier",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        
        // Personal info confirmation
        _buildConfirmationItem(
          label: "Name",
          value: "${_firstNameController.text} ${_lastNameController.text}",
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        
        _buildConfirmationItem(
          label: "Email",
          value: _emailController.text,
          icon: Icons.email,
        ),
        const SizedBox(height: 16),
        
        _buildConfirmationItem(
          label: "Phone",
          value: _phoneController.text,
          icon: Icons.phone,
        ),
        const SizedBox(height: 16),
        
        _buildConfirmationItem(
          label: "Address",
          value: _addressController.text,
          icon: Icons.location_on,
        ),
        
        // Courier-specific confirmation
        if (_selectedRole == 'courier') ...[
          const SizedBox(height: 16),
          _buildConfirmationItem(
            label: "License Number",
            value: _licenseNumberController.text,
            icon: Icons.card_membership,
          ),
          const SizedBox(height: 16),
          _buildConfirmationItem(
            label: "License Photo",
            value: _licenseFileName ?? "Not uploaded",
            icon: Icons.photo,
          ),
        ],
        
        // Avatar confirmation
        const SizedBox(height: 16),
        _buildConfirmationItem(
          label: "Profile Avatar",
          value: _avatarFileName ?? "Not uploaded",
          icon: Icons.photo_camera,
        ),
        
        const SizedBox(height: 32),
        const Text(
          "By submitting this form, you agree to our Terms of Service and Privacy Policy.",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConfirmationItem({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF64748B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "Not provided",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
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
          validator: validator,
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
          ),
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
          validator: validator,
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
                isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
          ),
        ),
      ],
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text("Role"),
        content: _buildStep0(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text("Personal"),
        content: _buildStep1(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      if (_selectedRole == 'courier')
        Step(
          title: const Text("License"),
          content: _buildStep2(),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
      Step(
        title: const Text("Confirm"),
        content: _buildConfirmationStep(),
        isActive: _currentStep >= (_selectedRole == 'courier' ? 3 : 2),
        state: _currentStep > (_selectedRole == 'courier' ? 3 : 2) 
            ? StepState.complete 
            : StepState.indexed,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _initializationError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Initialization Error",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initializationError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _checkFirebaseInitialization,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStepIndicator(1, "Role", _currentStep >= 0),
                        Container(
                          height: 2,
                          width: 40,
                          color: _currentStep >= 1 
                              ? const Color(0xFF3B82F6) 
                              : const Color(0xFFE2E8F0),
                        ),
                        _buildStepIndicator(2, "Personal", _currentStep >= 1),
                        if (_selectedRole == 'courier') ...[
                          Container(
                            height: 2,
                            width: 40,
                            color: _currentStep >= 2 
                                ? const Color(0xFF3B82F6) 
                                : const Color(0xFFE2E8F0),
                          ),
                          _buildStepIndicator(3, "License", _currentStep >= 2),
                        ],
                        Container(
                          height: 2,
                          width: 40,
                          color: _currentStep >= (_selectedRole == 'courier' ? 3 : 2)
                              ? const Color(0xFF3B82F6) 
                              : const Color(0xFFE2E8F0),
                        ),
                        _buildStepIndicator(
                          _selectedRole == 'courier' ? 4 : 3, 
                          "Confirm", 
                          _currentStep >= (_selectedRole == 'courier' ? 3 : 2)
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Current step content
                    IndexedStack(
                      index: _currentStep,
                      children: [
                        _buildStep0(),
                        _buildStep1(),
                        if (_selectedRole == 'courier') _buildStep2(),
                        _buildConfirmationStep(),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Back"),
                          )
                        else
                          const SizedBox(width: 100),

                        if (_currentStep < (_selectedRole == 'courier' ? 3 : 2))
                          ElevatedButton(
                            onPressed: () {
                              if (_currentStep == 0 && _selectedRole == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a role')),
                                );
                                return;
                              }
                              
                              if (_currentStep == 1) {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                              }
                              
                              setState(() {
                                _currentStep++;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Next",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: _isLoading ? null : _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Create Account",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}