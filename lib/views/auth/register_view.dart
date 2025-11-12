

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/auth_controller.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Find AuthController (should be registered in main.dart)
  final AuthController _authController = Get.find<AuthController>();

  bool _obsecurePassword = true;
  bool _obsecureConfirmPassword = true;
  String _selectedGender = '';
  String _selectedAvatarCode = '';

  // Avatar options
  final List<String> maleAvatars = ['male_1', 'male_2', 'male_3'];
  final List<String> femaleAvatars = ['female_1', 'female_2', 'female_3'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Submission Logic ---
  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _authController.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
        _selectedGender, // Pass selected gender
        avatarCode: _selectedAvatarCode.isNotEmpty ? _selectedAvatarCode : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // --- Header/Title ---
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8), // Adjusted width for better spacing
                    Text(
                      "Creating Account",
                      style: Theme.of(context).textTheme.headlineMedium, // Use headlineMedium for better scaling
                    ),
                  ],
                ),
                Text(
                  "Fill in your details to get started",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecoundaryColor,
                      ),
                ),
                const SizedBox(height: 40),

                // --- Form Fields ---

                // Display Name
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person_2_outlined),
                    hintText: 'Enter your Name',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your Name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'Enter your email',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obsecurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    hintText: 'Enter your Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obsecurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () {
                        setState(() {
                          _obsecurePassword = !_obsecurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obsecureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    hintText: 'Confirm your Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obsecureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () {
                        setState(() {
                          _obsecureConfirmPassword =
                              !_obsecureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- Gender Selection ---
                Text(
                  'Gender (Optional)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/male_1.png',
                              width: 28,
                              height: 28,
                              
                              
                            ),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                'Male',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        value: 'male',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value ?? '';
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/female_1.png',
                            
                              width: 28,
                              height: 28,
                             
                            ),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                'Female',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        value: 'female',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value ?? '';
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),

                // Avatar Selection
                if (_selectedGender.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Choose Avatar',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        final avatars = _selectedGender == 'male' 
                            ? maleAvatars 
                            : femaleAvatars;
                        final avatarCode = avatars[index];
                        final isSelected = _selectedAvatarCode == avatarCode;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarCode = avatarCode;
                            });
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : Colors.grey.shade300,
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/$avatarCode.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // --- Create Account Button ---
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authController.isLoading ? null : _submit, // Use _submit method
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _authController.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Create Account"),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- OR Divider ---
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppTheme.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(
                        child: Divider(color: AppTheme.borderColor)),
                  ],
                ),
                const SizedBox(height: 32),

                // --- Already have account ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.login),
                      child: Text(
                        'Sign In',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}