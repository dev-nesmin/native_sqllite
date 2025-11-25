import 'dart:convert';

import 'package:native_sqlite/native_sqlite.dart';

part 'profile.table.dart';

/// Address model - stored as JSON in profile
class Address {
  final String street;
  final String city;
  final String zipCode;
  final String? country;

  const Address({
    required this.street,
    required this.city,
    required this.zipCode,
    this.country,
  });

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'zipCode': zipCode,
    if (country != null) 'country': country,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    street: json['street'] as String,
    city: json['city'] as String,
    zipCode: json['zipCode'] as String,
    country: json['country'] as String?,
  );
}

/// User profile with JSON fields
@DbTable(name: 'profiles')
class Profile {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(name: 'name')
  final String name;

  @DbColumn(name: 'email')
  final String email;

  /// New field for testing migration
  @DbColumn(name: 'phone_number')
  final String? phoneNumber;

  /// Store settings as a Map<String, dynamic>
  @JsonField()
  @DbColumn(name: 'settings')
  final Map<String, dynamic>? settings;

  /// Store tags as a List
  @JsonField()
  @DbColumn(name: 'tags')
  final List<String>? tags;

  /// Store address as a custom class with toJson/fromJson
  @JsonField()
  @DbColumn(name: 'address')
  final Address? address;

  /// Store multiple addresses as a list of custom objects
  @JsonField()
  @DbColumn(name: 'addresses')
  final List<Address>? addresses;

  /// Store dynamic data
  @JsonField()
  @DbColumn(name: 'metadata')
  final dynamic metadata;

  const Profile({
    this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.settings,
    this.tags,
    this.address,
    this.addresses,
    this.metadata,
  });
}

// Force rebuild 2
