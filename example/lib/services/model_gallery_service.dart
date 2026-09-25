import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:native_sqlite/native_sqlite.dart';

import '../models/advanced.dart';
import '../models/attachment.dart';
import '../models/category.dart';
import '../models/comment.dart';
import '../models/custom_converter.dart';
import '../models/demo_enums.dart';
import '../models/freezed_advanced.dart';
import '../models/note.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/profile.dart';
import '../models/sync_event.dart';
import '../models/tag.dart';
import '../models/user.dart';

class ModelGalleryResult {
  const ModelGalleryResult({
    required this.model,
    required this.features,
    required this.passed,
    required this.detail,
  });

  final String model;
  final String features;
  final bool passed;
  final String detail;
}

/// Creates and reads one row for every model in the generated main database.
class ModelGalleryService {
  const ModelGalleryService(this.database);

  final NativeSqliteDatabase database;

  Future<List<ModelGalleryResult>> runAll() async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final instant = DateTime.utc(2025, 2, 3, 4, 5, 6, 789);
    int? userId;
    int? categoryId;
    int? productId;

    return [
      await _check(
        'User',
        'defaults, nullable columns, bool, DateTime, ignored field',
        () async {
          final repository = UserRepository(database);
          userId = await repository.insert(
            User(
              name: 'Gallery User',
              email: 'gallery-$suffix@example.com',
              phoneNumber: '555-$suffix',
              age: 29,
              isActive: true,
              createdAt: instant,
              tempPassword: 'ignored',
            ),
          );
          final saved = await repository.findById(userId);
          return saved?.name == 'Gallery User' &&
              saved?.phoneNumber == '555-$suffix' &&
              saved?.age == 29 &&
              saved?.isActive == true &&
              saved?.createdAt.millisecondsSinceEpoch ==
                  instant.millisecondsSinceEpoch &&
              saved?.tempPassword == null;
        },
      ),
      await _check('Category', 'UNIQUE text and generated DateTime', () async {
        final repository = CategoryRepository(database);
        categoryId = await repository.insert(
          Category(
            name: 'Gallery Category $suffix',
            description: 'Round-trip sample',
            createdAt: instant,
          ),
        );
        final saved = await repository.findById(categoryId);
        return saved?.name == 'Gallery Category $suffix' &&
            saved?.description == 'Round-trip sample' &&
            saved?.createdAt.millisecondsSinceEpoch ==
                instant.millisecondsSinceEpoch;
      }),
      await _check('Product', 'foreign key, REAL, defaults, indexes', () async {
        final parentId = categoryId;
        if (parentId == null) return false;
        final repository = ProductRepository(database);
        productId = await repository.insert(
          Product(
            name: 'Gallery Product $suffix',
            description: 'Indexed product',
            price: 19.95,
            stock: 7,
            categoryId: parentId,
            createdAt: instant,
          ),
        );
        final saved = await repository.findById(productId);
        return saved?.name == 'Gallery Product $suffix' &&
            saved?.price == 19.95 &&
            saved?.stock == 7 &&
            saved?.categoryId == parentId;
      }),
      await _check('Order', 'two foreign keys and enum name storage', () async {
        final ownerId = userId;
        final itemId = productId;
        if (ownerId == null || itemId == null) return false;
        final repository = OrderRepository(database);
        final id = await repository.insert(
          Order(
            userId: ownerId,
            productId: itemId,
            quantity: 2,
            totalPrice: 39.90,
            status: OrderStatus.processing,
            notes: 'Gallery order',
            createdAt: instant,
          ),
        );
        final saved = await repository.findById(id);
        return saved?.userId == ownerId &&
            saved?.productId == itemId &&
            saved?.quantity == 2 &&
            saved?.totalPrice == 39.90 &&
            saved?.status == OrderStatus.processing;
      }),
      await _check(
        'Profile',
        'JSON maps, lists, nested objects, and dynamic values',
        () async {
          final repository = ProfileRepository(database);
          final id = await repository.insert(
            Profile(
              name: 'Gallery Profile',
              email: 'profile-$suffix@example.com',
              settings: const {'dark': true, 'density': 2},
              tags: const ['json', 'nested'],
              address: const Address(
                street: 'Main',
                city: 'Istanbul',
                zipCode: '34000',
              ),
              addresses: const [
                Address(street: 'Main', city: 'Istanbul', zipCode: '34000'),
              ],
              metadata: const {
                'values': [1, null, 'three'],
              },
            ),
          );
          final saved = await repository.findById(id);
          return saved?.settings?['dark'] == true &&
              saved?.settings?['density'] == 2 &&
              saved?.tags?.join(',') == 'json,nested' &&
              saved?.address?.city == 'Istanbul' &&
              saved?.addresses?.single.zipCode == '34000' &&
              (saved?.metadata as Map<String, dynamic>)['values'] is List;
        },
      ),
      await _check(
        'AdvancedUser',
        'Duration, Uri, num, ordinal/name enums, bool',
        () async {
          final repository = AdvancedUserRepository(database);
          final id = await repository.insert(
            AdvancedUser(
              name: 'Advanced $suffix',
              loginDuration: const Duration(minutes: 12),
              profileUrl: Uri.parse('https://example.com/$suffix'),
              score: 98.5,
              status: UserStatus.suspended,
              priority: Priority.urgent,
              createdAt: instant,
              isVerified: true,
            ),
          );
          final saved = await repository.findById(id);
          return saved?.loginDuration == const Duration(minutes: 12) &&
              saved?.profileUrl == Uri.parse('https://example.com/$suffix') &&
              saved?.score == 98.5 &&
              saved?.status == UserStatus.suspended &&
              saved?.priority == Priority.urgent &&
              saved?.isVerified == true;
        },
      ),
      await _check(
        'FreezedAdvancedUser',
        'Freezed model with shared enums and ignored field',
        () async {
          final repository = FreezedAdvancedUserRepository(database);
          final id = await repository.insert(
            FreezedAdvancedUser(
              name: 'Freezed $suffix',
              loginDuration: const Duration(seconds: 45),
              profileUrl: Uri.parse('https://example.com/freezed/$suffix'),
              score: 12,
              status: UserStatus.active,
              priority: Priority.high,
              createdAt: instant,
              isVerified: false,
            ),
          );
          final saved = await repository.findById(id);
          return saved?.name == 'Freezed $suffix' &&
              saved?.loginDuration == const Duration(seconds: 45) &&
              saved?.status == UserStatus.active &&
              saved?.priority == Priority.high &&
              saved?.score == null;
        },
      ),
      await _check('StyledItem', 'Color converter plus JSON list', () async {
        final repository = StyledItemRepository(database);
        final id = await repository.insert(
          StyledItem(
            name: 'Styled $suffix',
            backgroundColor: const Color(0xff123456),
            textColor: const Color(0xffabcdef),
            tags: const ['comma,value', ' whitespace preserved '],
            createdAt: instant,
          ),
        );
        final saved = await repository.findById(id);
        return saved?.backgroundColor.toARGB32() == 0xff123456 &&
            saved?.textColor?.toARGB32() == 0xffabcdef &&
            saved?.tags.join('|') == 'comma,value| whitespace preserved ' &&
            saved?.createdAt.millisecondsSinceEpoch ==
                instant.millisecondsSinceEpoch;
      }),
      await _check('Note', 'locally generated UUID primary key', () async {
        final repository = NoteRepository(database);
        final id = await repository.insert(Note(body: 'Gallery $suffix'));
        final saved = await repository.findById(id);
        return id.length == 36 && saved?.body == 'Gallery $suffix';
      }),
      await _check('Attachment', 'Uint8List stored as a BLOB', () async {
        final repository = AttachmentRepository(database);
        final input = Uint8List.fromList([0, 1, 2, 127, 128, 255]);
        final id = await repository.insert(
          Attachment(filename: 'sample-$suffix.bin', bytes: input),
        );
        final saved = await repository.findById(id);
        return saved?.filename == 'sample-$suffix.bin' &&
            _bytesEqual(saved?.bytes, input);
      }),
      await _check(
        'Tag',
        'renamed column and named UNIQUE class index',
        () async {
          final repository = TagRepository(database);
          final id = await repository.insert(Tag(label: 'gallery-$suffix'));
          final saved = await repository.findById(id);
          final raw = await database.query(
            'SELECT "label_text" FROM "tags" WHERE "id" = ?',
            [id],
          );
          return saved?.label == 'gallery-$suffix' &&
              raw.rows.single.single == 'gallery-$suffix';
        },
      ),
      await _check(
        'Comment',
        'nullable self-reference with ON DELETE SET NULL',
        () async {
          final repository = CommentRepository(database);
          final parentId = await repository.insert(
            Comment(body: 'Parent $suffix'),
          );
          final childId = await repository.insert(
            Comment(parentId: parentId, body: 'Child $suffix'),
          );
          final beforeDelete = await repository.findById(childId);
          await repository.delete(parentId);
          final afterDelete = await repository.findById(childId);
          return beforeDelete?.parentId == parentId &&
              afterDelete?.parentId == null &&
              afterDelete?.body == 'Child $suffix';
        },
      ),
      await _check(
        'SyncEvent',
        'row shared with platform-native background tasks',
        () async {
          final repository = SyncEventRepository(database);
          final id = await repository.insert(
            SyncEvent(
              source: 'dart-gallery',
              message: 'Foreground sample $suffix',
              createdAt: instant,
            ),
          );
          final saved = await repository.findById(id);
          return saved?.source == 'dart-gallery' &&
              saved?.message == 'Foreground sample $suffix' &&
              saved?.createdAt.millisecondsSinceEpoch ==
                  instant.millisecondsSinceEpoch;
        },
      ),
    ];
  }

  Future<ModelGalleryResult> _check(
    String model,
    String features,
    Future<bool> Function() operation,
  ) async {
    try {
      final passed = await operation();
      return ModelGalleryResult(
        model: model,
        features: features,
        passed: passed,
        detail: passed ? 'Saved values match the row read back.' : 'Mismatch',
      );
    } on Object catch (error) {
      return ModelGalleryResult(
        model: model,
        features: features,
        passed: false,
        detail: error.toString(),
      );
    }
  }

  static bool _bytesEqual(Uint8List? left, Uint8List right) {
    if (left == null || left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
