import 'package:uuid/uuid.dart';

class LinkItem {
  final String id;
  final String url;
  final String title;
  final List<String> tags;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isRead;
  final String? thumbnail;
  final String? note;
  final String? collectionId;

  LinkItem({
    String? id,
    required this.url,
    required this.title,
    List<String>? tags,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isRead,
    this.thumbnail,
    this.note,
    this.collectionId,
  }) : id = id ?? const Uuid().v4(),
       tags = tags ?? const [],
       createdAt = createdAt ?? DateTime.now(),
       isFavorite = isFavorite ?? false,
       isRead = isRead ?? false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'tags': tags.join(','),
      'savedAt': createdAt.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
      'is_read': isRead ? 1 : 0,
      'thumbnail': thumbnail ?? '',
      'note': note ?? '',
      'collection_id': collectionId ?? '',
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    final metadata = <String, dynamic>{
      'tags': tags,
      'isFavorite': isFavorite,
      'isRead': isRead,
    };
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      metadata['thumbnail'] = thumbnail;
    }
    if (note != null && note!.isNotEmpty) {
      metadata['note'] = note;
    }
    if (collectionId != null && collectionId!.isNotEmpty) {
      metadata['collectionId'] = collectionId;
    }
    return {
      'url': url,
      'title': title,
      'savedAt': createdAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory LinkItem.fromMap(Map<String, dynamic> map) {
    DateTime? createdDate;

    if (map.containsKey('savedAt') && map['savedAt'] != null) {
      final timestamp = map['savedAt'];
      if (timestamp is int) {
        createdDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        createdDate = DateTime.tryParse(timestamp);
      }
    } else if (map.containsKey('createdAt') && map['createdAt'] != null) {
      final raw = map['createdAt'];
      if (raw is String) {
        createdDate = DateTime.tryParse(raw);
      }
    }

    return LinkItem(
      id: map['id'] as String? ?? const Uuid().v4(),
      url: map['url'] as String,
      title: map['title'] as String,
      tags: _parseTags(map),
      createdAt: createdDate ?? DateTime.now(),
      isFavorite: _parseFavorite(map),
      isRead: _parseIsRead(map),
      thumbnail: _parseThumbnail(map),
      note: _parseNote(map),
      collectionId: _parseCollectionId(map),
    );
  }

  static bool _parseFavorite(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    if (metadata is Map && metadata['isFavorite'] is bool) {
      return metadata['isFavorite'] as bool;
    }
    if (map['is_favorite'] is int) return (map['is_favorite'] as int) == 1;
    return false;
  }

  static bool _parseIsRead(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    if (metadata is Map && metadata['isRead'] is bool) {
      return metadata['isRead'] as bool;
    }
    if (map['is_read'] is int) return (map['is_read'] as int) == 1;
    return false;
  }

  static String? _parseThumbnail(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    if (metadata is Map && metadata['thumbnail'] is String) {
      final val = metadata['thumbnail'] as String;
      return val.isEmpty ? null : val;
    }
    if (map['thumbnail'] is String) {
      final val = map['thumbnail'] as String;
      return val.isEmpty ? null : val;
    }
    return null;
  }

  static String? _parseNote(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    if (metadata is Map && metadata['note'] is String) {
      final val = metadata['note'] as String;
      return val.isEmpty ? null : val;
    }
    if (map['note'] is String) {
      final val = map['note'] as String;
      return val.isEmpty ? null : val;
    }
    return null;
  }

  static String? _parseCollectionId(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    if (metadata is Map && metadata['collectionId'] is String) {
      final val = metadata['collectionId'] as String;
      return val.isEmpty ? null : val;
    }
    if (map['collection_id'] is String) {
      final val = map['collection_id'] as String;
      return val.isEmpty ? null : val;
    }
    return null;
  }

  static List<String> _parseTags(Map<String, dynamic> map) {
    final metadata = map['metadata'];
    if (metadata is Map && metadata['tags'] is List) {
      return (metadata['tags'] as List)
          .map((t) => t.toString().toUpperCase())
          .toList();
    }
    if (map['tags'] is String && (map['tags'] as String).isNotEmpty) {
      return (map['tags'] as String)
          .split(',')
          .map((t) => t.trim().toUpperCase())
          .where((t) => t.isNotEmpty)
          .toList();
    }
    return [];
  }

  LinkItem copyWith({
    String? url,
    String? title,
    List<String>? tags,
    bool? isFavorite,
    bool? isRead,
    String? thumbnail,
    String? note,
    String? collectionId,
    bool clearCollectionId = false,
  }) {
    return LinkItem(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isRead: isRead ?? this.isRead,
      thumbnail: thumbnail ?? this.thumbnail,
      note: note ?? this.note,
      collectionId: clearCollectionId ? null : (collectionId ?? this.collectionId),
    );
  }

  @override
  String toString() =>
      'LinkItem(id: $id, url: $url, title: $title, tags: $tags, isFavorite: $isFavorite, isRead: $isRead)';
}
