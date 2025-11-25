import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';

part 'custom_converter.table.dart';

/// Custom type converter for Color
class ColorConverter extends TypeConverter<Color, int> {
  const ColorConverter();

  @override
  int toSql(Color value) => value.value;

  @override
  Color fromSql(int sqlValue) => Color(sqlValue);
}

/// Custom type converter for List<String> (storing as comma-separated TEXT)
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  String toSql(List<String> value) => value.join(',');

  @override
  List<String> fromSql(String sqlValue) =>
      sqlValue.isEmpty ? [] : sqlValue.split(',');
}

/// Table demonstrating custom type converters
@DbTable(name: 'styled_items')
class StyledItem {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String name;

  // Custom converter for Color type
  @DbColumn(type: 'INTEGER')
  @UseConverter(ColorConverter())
  final Color backgroundColor;

  // Custom converter for nullable Color
  @DbColumn(type: 'INTEGER')
  @UseConverter(ColorConverter())
  final Color? textColor;

  // Custom converter for List<String>
  @DbColumn(type: 'TEXT')
  @UseConverter(StringListConverter())
  final List<String> tags;

  @DbColumn()
  final DateTime createdAt;

  const StyledItem({
    this.id,
    required this.name,
    required this.backgroundColor,
    this.textColor,
    required this.tags,
    required this.createdAt,
  });

  StyledItem copyWith({
    int? id,
    String? name,
    Color? backgroundColor,
    Color? textColor,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return StyledItem(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Force rebuild 2
