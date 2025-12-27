import 'package:vector_math/vector_math_64.dart';

enum StickerType { emoji, text, image, shape }

enum StickerState { placing, editing, locked }

class ARSticker {
  final String id;
  final StickerType type;
  final String content; // emoji, text, or asset path
  final Vector3 position;
  final Vector3 rotation;
  final Vector3 scale;
  final String? anchorId;
  final DateTime createdAt;
  final Map<String, dynamic> properties;
  StickerState state;

  ARSticker({
    required this.id,
    required this.type,
    required this.content,
    required this.position,
    Vector3? rotation,
    Vector3? scale,
    this.anchorId,
    DateTime? createdAt,
    Map<String, dynamic>? properties,
    this.state = StickerState.placing,
  }) : rotation = rotation ?? Vector3.zero(),
       scale = scale ?? Vector3.all(1.0),
       createdAt = createdAt ?? DateTime.now(),
       properties = properties ?? {};

  ARSticker copyWith({
    String? id,
    StickerType? type,
    String? content,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
    String? anchorId,
    DateTime? createdAt,
    Map<String, dynamic>? properties,
    StickerState? state,
  }) {
    return ARSticker(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      anchorId: anchorId ?? this.anchorId,
      createdAt: createdAt ?? this.createdAt,
      properties: properties ?? this.properties,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'content': content,
      'position': [position.x, position.y, position.z],
      'rotation': [rotation.x, rotation.y, rotation.z],
      'scale': [scale.x, scale.y, scale.z],
      'anchorId': anchorId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'properties': properties,
      'state': state.index,
    };
  }

  factory ARSticker.fromJson(Map<String, dynamic> json) {
    final positionList = List<double>.from(json['position']);
    final rotationList = List<double>.from(json['rotation']);
    final scaleList = List<double>.from(json['scale']);

    return ARSticker(
      id: json['id'],
      type: StickerType.values[json['type']],
      content: json['content'],
      position: Vector3(positionList[0], positionList[1], positionList[2]),
      rotation: Vector3(rotationList[0], rotationList[1], rotationList[2]),
      scale: Vector3(scaleList[0], scaleList[1], scaleList[2]),
      anchorId: json['anchorId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      properties: Map<String, dynamic>.from(json['properties']),
      state: StickerState.values[json['state']],
    );
  }
}

class ARStickerTemplate {
  final String id;
  final String name;
  final StickerType type;
  final String content;
  final String? previewAsset;
  final Map<String, dynamic> defaultProperties;

  const ARStickerTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    this.previewAsset,
    this.defaultProperties = const {},
  });
}

// Predefined sticker templates
class StickerTemplates {
  static const List<ARStickerTemplate> emojis = [
    ARStickerTemplate(
      id: 'emoji_happy',
      name: 'Happy',
      type: StickerType.emoji,
      content: '😀',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_laugh',
      name: 'Laugh',
      type: StickerType.emoji,
      content: '😂',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_love',
      name: 'Love',
      type: StickerType.emoji,
      content: '😍',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_think',
      name: 'Think',
      type: StickerType.emoji,
      content: '🤔',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_cool',
      name: 'Cool',
      type: StickerType.emoji,
      content: '😎',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_fire',
      name: 'Fire',
      type: StickerType.emoji,
      content: '🔥',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_hundred',
      name: '100',
      type: StickerType.emoji,
      content: '💯',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_heart',
      name: 'Heart',
      type: StickerType.emoji,
      content: '❤️',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_thumbs_up',
      name: 'Thumbs Up',
      type: StickerType.emoji,
      content: '👍',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_star',
      name: 'Star',
      type: StickerType.emoji,
      content: '⭐',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_sparkles',
      name: 'Sparkles',
      type: StickerType.emoji,
      content: '✨',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
    ARStickerTemplate(
      id: 'emoji_party',
      name: 'Party',
      type: StickerType.emoji,
      content: '🎉',
      defaultProperties: {'fontSize': 48.0, 'color': 0xFFFFFFFF},
    ),
  ];

  static const List<ARStickerTemplate> shapes = [
    ARStickerTemplate(
      id: 'shape_arrow',
      name: 'Arrow',
      type: StickerType.shape,
      content: 'arrow',
      defaultProperties: {'color': 0xFFFF6B35, 'size': 0.2},
    ),
    ARStickerTemplate(
      id: 'shape_circle',
      name: 'Circle',
      type: StickerType.shape,
      content: 'circle',
      defaultProperties: {'color': 0xFF4ECDC4, 'size': 0.15},
    ),
    ARStickerTemplate(
      id: 'shape_square',
      name: 'Square',
      type: StickerType.shape,
      content: 'square',
      defaultProperties: {'color': 0xFF45B7D1, 'size': 0.15},
    ),
    ARStickerTemplate(
      id: 'shape_triangle',
      name: 'Triangle',
      type: StickerType.shape,
      content: 'triangle',
      defaultProperties: {'color': 0xFF96CEB4, 'size': 0.15},
    ),
  ];

  static List<ARStickerTemplate> get all => [...emojis, ...shapes];
}
