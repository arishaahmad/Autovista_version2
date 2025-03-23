import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/car_model.dart';
import 'package:intl/intl.dart';

class ViewVehicleScreen extends StatefulWidget {
  final String userId;

  const ViewVehicleScreen({super.key, required this.userId});

  @override
  State<ViewVehicleScreen> createState() => _ViewVehicleScreenState();
}

class _ViewVehicleScreenState extends State<ViewVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _engineTypeController = TextEditingController();
  final _mileageController = TextEditingController();
  final _regionController = TextEditingController();
  final _makeYearController = TextEditingController();
  final _engineCapacityController = TextEditingController();
  final _licenseStartDateController = TextEditingController();
  final _licenseValidityMonthsController = TextEditingController();
  final _insuranceStartDateController = TextEditingController();
  final _insuranceValidityMonthsController = TextEditingController();
  final _lastOilChangeDateController = TextEditingController();

  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _registerVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final car = Car(
        brand: _brandController.text,
        model: _modelController.text,
        engineType: _engineTypeController.text,
        mileage: double.parse(_mileageController.text),
        region: _regionController.text,
        makeYear: int.parse(_makeYearController.text),
        engineCapacity: double.parse(_engineCapacityController.text),
        licenseStartDate: _licenseStartDateController.text.isNotEmpty
            ? _licenseStartDateController.text
            : null,
        licenseValidityMonths: _licenseValidityMonthsController.text.isNotEmpty
            ? int.parse(_licenseValidityMonthsController.text)
            : null,
        insuranceStartDate: _insuranceStartDateController.text.isNotEmpty
            ? _insuranceStartDateController.text
            : null,
        insuranceValidityMonths:
            _insuranceValidityMonthsController.text.isNotEmpty
                ? int.parse(_insuranceValidityMonthsController.text)
                : null,
        lastOilChangeDate: _lastOilChangeDateController.text.isNotEmpty
            ? _lastOilChangeDateController.text
            : null,
      );

      await _supabaseService.registerCar(widget.userId, car);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle registered successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/added_vehicle_screen',
        arguments: car.toJson(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error registering vehicle: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/ocr_screen');
                if (result is Map<String, dynamic>) {
                  setState(() {
                    _brandController.text = result['brand'] ?? '';
                    _modelController.text = result['model'] ?? '';
                    _engineTypeController.text = result['engine_type'] ?? '';
                    _mileageController.text = result['mileage'] ?? '';
                    _regionController.text = result['region'] ?? '';
                    _makeYearController.text = result['make_year'] ?? '';
                  });
                }
              },
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Document to Auto-fill'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),

              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _engineTypeController,
                decoration: const InputDecoration(
                  labelText: 'Engine Type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the engine type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(
                  labelText: 'Mileage',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the mileage';
                  }
                  final number = double.tryParse(value.replaceAll(',', ''));
                  if (number == null || number.isNaN || number.isInfinite) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final number = double.tryParse(value.replaceAll(',', ''));
                    if (number == null || number.isNaN || number.isInfinite) {
                      _mileageController.text =
                          value.substring(0, value.length - 1);
                      _mileageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _mileageController.text.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the region';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeYearController,
                decoration: const InputDecoration(
                  labelText: 'Make Year',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the make year';
                  }
                  final year = int.tryParse(value);
                  if (year == null) {
                    return 'Please enter a valid year';
                  }
                  if (year < 1900 || year > DateTime.now().year + 1) {
                    return 'Please enter a valid year between 1900 and ${DateTime.now().year + 1}';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final year = int.tryParse(value);
                    if (year == null) {
                      _makeYearController.text =
                          value.substring(0, value.length - 1);
                      _makeYearController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _makeYearController.text.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _engineCapacityController,
                decoration: const InputDecoration(
                  labelText: 'Engine Capacity (L)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the engine capacity';
                  }
                  final number = double.tryParse(value.replaceAll(',', ''));
                  if (number == null || number.isNaN || number.isInfinite) {
                    return 'Please enter a valid number';
                  }
                  if (number <= 0 || number > 20) {
                    return 'Please enter a valid engine capacity between 0 and 20L';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final number = double.tryParse(value.replaceAll(',', ''));
                    if (number == null || number.isNaN || number.isInfinite) {
                      _engineCapacityController.text =
                          value.substring(0, value.length - 1);
                      _engineCapacityController.selection =
                          TextSelection.fromPosition(
                        TextPosition(
                            offset: _engineCapacityController.text.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseStartDateController,
                decoration: InputDecoration(
                  labelText: 'License Start Date (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(_licenseStartDateController),
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              if (_licenseStartDateController.text.isNotEmpty)
                TextFormField(
                  controller: _licenseValidityMonthsController,
                  decoration: const InputDecoration(
                    labelText: 'License Validity (Months)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_licenseStartDateController.text.isNotEmpty) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the validity period';
                      }
                      final months = int.tryParse(value);
                      if (months == null) {
                        return 'Please enter a valid number';
                      }
                      if (months <= 0 || months > 120) {
                        return 'Please enter a valid period between 1 and 120 months';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final months = int.tryParse(value);
                      if (months == null) {
                        _licenseValidityMonthsController.text =
                            value.substring(0, value.length - 1);
                        _licenseValidityMonthsController.selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset:
                                  _licenseValidityMonthsController.text.length),
                        );
                      }
                    }
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _insuranceStartDateController,
                decoration: InputDecoration(
                  labelText: 'Insurance Start Date (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(_insuranceStartDateController),
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              if (_insuranceStartDateController.text.isNotEmpty)
                TextFormField(
                  controller: _insuranceValidityMonthsController,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Validity (Months)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_insuranceStartDateController.text.isNotEmpty) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the validity period';
                      }
                      final months = int.tryParse(value);
                      if (months == null) {
                        return 'Please enter a valid number';
                      }
                      if (months <= 0 || months > 120) {
                        return 'Please enter a valid period between 1 and 120 months';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final months = int.tryParse(value);
                      if (months == null) {
                        _insuranceValidityMonthsController.text =
                            value.substring(0, value.length - 1);
                        _insuranceValidityMonthsController.selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset: _insuranceValidityMonthsController
                                  .text.length),
                        );
                      }
                    }
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastOilChangeDateController,
                decoration: InputDecoration(
                  labelText: 'Last Oil Change Date (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(_lastOilChangeDateController),
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _registerVehicle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Register Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _engineTypeController.dispose();
    _mileageController.dispose();
    _regionController.dispose();
    _makeYearController.dispose();
    _engineCapacityController.dispose();
    _licenseStartDateController.dispose();
    _licenseValidityMonthsController.dispose();
    _insuranceStartDateController.dispose();
    _insuranceValidityMonthsController.dispose();
    _lastOilChangeDateController.dispose();
    super.dispose();
  }
}
