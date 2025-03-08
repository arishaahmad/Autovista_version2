class Car {
  final String? id;
  final String brand;
  final String model;
  final String engineType;
  final double mileage;
  final String region;
  final int makeYear;
  final double engineCapacity;
  final String? licenseStartDate;
  final int? licenseValidityMonths;
  final String? insuranceStartDate;
  final int? insuranceValidityMonths;
  final String? lastOilChangeDate;
  final String? createdAt;
  final String? updatedAt;

  Car({
    this.id,
    required this.brand,
    required this.model,
    required this.engineType,
    required this.mileage,
    required this.region,
    required this.makeYear,
    required this.engineCapacity,
    this.licenseStartDate,
    this.licenseValidityMonths,
    this.insuranceStartDate,
    this.insuranceValidityMonths,
    this.lastOilChangeDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id']?.toString(),
      brand: json['brand'] as String,
      model: json['model'] as String,
      engineType: json['engine_type'] as String,
      mileage: (json['mileage'] as num).toDouble(),
      region: json['region'] as String,
      makeYear: json['make_year'] as int,
      engineCapacity: (json['engine_capacity'] as num).toDouble(),
      licenseStartDate: json['license_start_date']?.toString(),
      licenseValidityMonths: json['license_validity_months'] as int?,
      insuranceStartDate: json['insurance_start_date']?.toString(),
      insuranceValidityMonths: json['insurance_validity_months'] as int?,
      lastOilChangeDate: json['last_oil_change_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'brand': brand,
      'model': model,
      'engine_type': engineType,
      'mileage': mileage,
      'region': region,
      'make_year': makeYear,
      'engine_capacity': engineCapacity,
      if (licenseStartDate != null) 'license_start_date': licenseStartDate,
      if (licenseValidityMonths != null)
        'license_validity_months': licenseValidityMonths,
      if (insuranceStartDate != null)
        'insurance_start_date': insuranceStartDate,
      if (insuranceValidityMonths != null)
        'insurance_validity_months': insuranceValidityMonths,
      if (lastOilChangeDate != null) 'last_oil_change_date': lastOilChangeDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  Car copyWith({
    String? id,
    String? brand,
    String? model,
    String? engineType,
    double? mileage,
    String? region,
    int? makeYear,
    double? engineCapacity,
    String? licenseStartDate,
    int? licenseValidityMonths,
    String? insuranceStartDate,
    int? insuranceValidityMonths,
    String? lastOilChangeDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return Car(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      engineType: engineType ?? this.engineType,
      mileage: mileage ?? this.mileage,
      region: region ?? this.region,
      makeYear: makeYear ?? this.makeYear,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      licenseStartDate: licenseStartDate ?? this.licenseStartDate,
      licenseValidityMonths:
          licenseValidityMonths ?? this.licenseValidityMonths,
      insuranceStartDate: insuranceStartDate ?? this.insuranceStartDate,
      insuranceValidityMonths:
          insuranceValidityMonths ?? this.insuranceValidityMonths,
      lastOilChangeDate: lastOilChangeDate ?? this.lastOilChangeDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
