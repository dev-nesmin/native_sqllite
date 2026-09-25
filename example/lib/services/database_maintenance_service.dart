import 'dart:typed_data';

import 'package:native_sqlite/native_sqlite.dart';

import '../generated/database_manager.dart';
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

class DatabaseMaintenanceService {
  const DatabaseMaintenanceService(this.database);

  final NativeSqliteDatabase database;

  /// Inserts a related sample set covering every generated table atomically.
  Future<Map<String, int>> generateSampleData({
    bool forceFailure = false,
  }) async {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now().millisecondsSinceEpoch;

    return database.transaction((transaction) async {
      final counts = <String, int>{
        for (final table in DatabaseManager.tableNames) table: 0,
      };

      final userId = await transaction.insert(UserSchema.tableName, {
        UserSchema.NAME: 'Sample User $suffix',
        UserSchema.EMAIL: 'sample-$suffix@example.com',
        UserSchema.PHONE_NUMBER: 'sample-$suffix',
        UserSchema.AGE: 28,
        UserSchema.IS_ACTIVE: 1,
        UserSchema.CREATED_AT: now,
      });
      counts[UserSchema.tableName] = 1;

      final categoryId = await transaction.insert(CategorySchema.tableName, {
        CategorySchema.NAME: 'Sample Category $suffix',
        CategorySchema.DESCRIPTION: 'Repeatable generated data',
        CategorySchema.CREATED_AT: now,
      });
      counts[CategorySchema.tableName] = 1;

      final productId = await transaction.insert(ProductSchema.tableName, {
        ProductSchema.NAME: 'Sample Product $suffix',
        ProductSchema.DESCRIPTION: 'Related sample row',
        ProductSchema.PRICE: 49.95,
        ProductSchema.STOCK: 10,
        ProductSchema.IS_AVAILABLE: 1,
        ProductSchema.CATEGORY_ID: categoryId,
        ProductSchema.CREATED_AT: now,
      });
      counts[ProductSchema.tableName] = 1;

      await transaction.insert(OrderSchema.tableName, {
        OrderSchema.USER_ID: userId,
        OrderSchema.PRODUCT_ID: productId,
        OrderSchema.QUANTITY: 2,
        OrderSchema.TOTAL_PRICE: 99.90,
        OrderSchema.STATUS: OrderStatus.processing.name,
        OrderSchema.NOTES: 'Generated in one transaction',
        OrderSchema.CREATED_AT: now,
      });
      counts[OrderSchema.tableName] = 1;

      await transaction.insert(AdvancedUserSchema.tableName, {
        AdvancedUserSchema.NAME: 'Advanced Sample $suffix',
        AdvancedUserSchema.LOGIN_DURATION: const Duration(
          minutes: 5,
        ).inMilliseconds,
        AdvancedUserSchema.PROFILE_URL: 'https://example.com/$suffix',
        AdvancedUserSchema.SCORE: 9.5,
        AdvancedUserSchema.STATUS: UserStatus.active.index,
        AdvancedUserSchema.PRIORITY: Priority.high.name,
        AdvancedUserSchema.CREATED_AT: now,
        AdvancedUserSchema.IS_VERIFIED: 1,
      });
      counts[AdvancedUserSchema.tableName] = 1;

      await transaction.insert(FreezedAdvancedUserSchema.tableName, {
        FreezedAdvancedUserSchema.NAME: 'Freezed Sample $suffix',
        FreezedAdvancedUserSchema.LOGIN_DURATION: const Duration(
          seconds: 30,
        ).inMilliseconds,
        FreezedAdvancedUserSchema.PROFILE_URL:
            'https://example.com/freezed/$suffix',
        FreezedAdvancedUserSchema.STATUS: UserStatus.inactive.index,
        FreezedAdvancedUserSchema.PRIORITY: Priority.medium.index,
        FreezedAdvancedUserSchema.CREATED_AT: now,
        FreezedAdvancedUserSchema.IS_VERIFIED: 0,
      });
      counts[FreezedAdvancedUserSchema.tableName] = 1;

      await transaction.insert(StyledItemSchema.tableName, {
        StyledItemSchema.NAME: 'Styled Sample $suffix',
        StyledItemSchema.BACKGROUND_COLOR: 0xff1565c0,
        StyledItemSchema.TEXT_COLOR: 0xffffffff,
        StyledItemSchema.TAGS: NativeSqliteCodec.jsonEncode(['sample', suffix]),
        StyledItemSchema.CREATED_AT: now,
      });
      counts[StyledItemSchema.tableName] = 1;

      await transaction.insert(NoteSchema.tableName, {
        NoteSchema.ID: NativeSqliteUuid.generate(),
        NoteSchema.BODY: 'UUID sample $suffix',
      });
      counts[NoteSchema.tableName] = 1;

      await transaction.insert(AttachmentSchema.tableName, {
        AttachmentSchema.FILENAME: 'sample-$suffix.bin',
        AttachmentSchema.BYTES: Uint8List.fromList([0, 1, 2, 127, 255]),
      });
      counts[AttachmentSchema.tableName] = 1;

      await transaction.insert(TagSchema.tableName, {
        TagSchema.LABEL: 'sample-$suffix',
      });
      counts[TagSchema.tableName] = 1;

      final parentId = await transaction.insert(CommentSchema.tableName, {
        CommentSchema.BODY: 'Parent sample $suffix',
      });
      await transaction.insert(CommentSchema.tableName, {
        CommentSchema.PARENT_ID: parentId,
        CommentSchema.BODY: 'Child sample $suffix',
      });
      counts[CommentSchema.tableName] = 2;

      await transaction.insert(ProfileSchema.tableName, {
        ProfileSchema.NAME: 'Profile Sample $suffix',
        ProfileSchema.EMAIL: 'profile-$suffix@example.com',
        ProfileSchema.SETTINGS: NativeSqliteCodec.jsonEncode({
          'theme': 'system',
          'sample': true,
        }),
        ProfileSchema.TAGS: NativeSqliteCodec.jsonEncode(['sample', 'json']),
        ProfileSchema.ADDRESS: NativeSqliteCodec.jsonEncode({
          'street': 'Main',
          'city': 'Istanbul',
          'zipCode': '34000',
        }),
        ProfileSchema.ADDRESSES: NativeSqliteCodec.jsonEncode([
          {'street': 'Main', 'city': 'Istanbul', 'zipCode': '34000'},
        ]),
        ProfileSchema.METADATA: NativeSqliteCodec.jsonEncode({
          'suffix': suffix,
        }),
      });
      counts[ProfileSchema.tableName] = 1;

      await transaction.insert(SyncEventSchema.tableName, {
        SyncEventSchema.SOURCE: 'dart-sample',
        SyncEventSchema.MESSAGE: 'Sample sync event $suffix',
        SyncEventSchema.CREATED_AT: now,
      });
      counts[SyncEventSchema.tableName] = 1;

      if (forceFailure) throw StateError('Forced sample-data rollback');
      return counts;
    });
  }

  /// Closes, deletes, and recreates the generated application database.
  static Future<void> resetDatabase() async {
    final name = DatabaseManager.currentDatabaseName;
    await DatabaseManager.close();
    await NativeSqlite.deleteDatabase(name);
    await DatabaseManager.init(name: name);
  }
}
