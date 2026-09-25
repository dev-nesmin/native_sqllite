import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';

part 'custom_converter.table.dart';

/// Custom type converter for Color
class ColorConverter extends TypeConverter<Color, int> {
  const ColorConverter();

  @override
  int toSql(Color value) => value.toARGB32();

  @override
  Color fromSql(int sqlValue) => Color(sqlValue);
}

/// Table demonstrating custom type converters
@DbTable(name: 'styled_items')
class StyledItem {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn()
  final String name;

  // Custom converter for Color type
  @UseConverter(ColorConverter())
  final Color backgroundColor;

  // Custom converter for nullable Color
  @UseConverter(ColorConverter())
  final Color? textColor;

  // JSON preserves values that contain commas, separators, or whitespace.
  @JsonField()
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
