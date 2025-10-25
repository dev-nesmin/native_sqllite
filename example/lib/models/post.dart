import 'package:native_sqlite_annotation/native_sqlite_annotation.dart';

part 'post.table.g.dart';

/// Example Post model with foreign key relationship
@Table(name: 'posts')
@Index(columns: ['userId', 'createdAt'])
class Post {
  @PrimaryKey(autoIncrement: true)
  final int? id;

  @Column()
  final String title;

  @Column()
  final String content;

  @Column()
  @ForeignKey(
    table: 'users',
    column: 'id',
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
  )
  final int userId;

  @Column()
  final DateTime createdAt;

  @Column()
  final DateTime updatedAt;

  @Column(defaultValue: '0')
  final int viewCount;

  const Post({
    this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
  });

  Post copyWith({
    int? id,
    String? title,
    String? content,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, title: $title, userId: $userId, '
        'viewCount: $viewCount, createdAt: $createdAt)';
  }
}
