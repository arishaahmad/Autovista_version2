import 'package:flutter/material.dart';
import 'package:autovista/services/supabase_service.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  final _licenseStartDateController = TextEditingController();
  final _licenseValidityMonthsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final SupabaseService _supabaseService = SupabaseService();

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _licenseStartDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    } else if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: "Location"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your location";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licenseStartDateController,
                  decoration: InputDecoration(
                    labelText: "License Start Date (Optional)",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                if (_licenseStartDateController.text.isNotEmpty)
                  TextFormField(
                    controller: _licenseValidityMonthsController,
                    decoration: const InputDecoration(
                      labelText: "License Validity (Months)",
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_licenseStartDateController.text.isNotEmpty) {
                        if (value == null || value.isEmpty) {
                          return "License validity is required when start date is provided";
                        }
                        if (int.tryParse(value) == null) {
                          return "Please enter a valid number of months";
                        }
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        String userId = await _supabaseService.registerUser(
                          _nameController.text,
                          _emailController.text,
                          _passwordController.text,
                          _locationController.text,
                          licenseStartDate:
                              _licenseStartDateController.text.isNotEmpty
                                  ? _licenseStartDateController.text
                                  : null,
                          licenseValidityMonths: _licenseStartDateController
                                  .text.isNotEmpty
                              ? int.parse(_licenseValidityMonthsController.text)
                              : null,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Registration successful!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pushReplacementNamed(
                          context,
                          '/home',
                          arguments: userId,
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                e.toString().replaceAll("Exception: ", "")),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _licenseStartDateController.dispose();
    _licenseValidityMonthsController.dispose();
    super.dispose();
  }
}
