import '../../../../core/utils/boolean_utils.dart';

/// Модель экипированного предмета пользователя
///
/// Хранит информацию о предмете, который пользователь экипировал:
/// название, изображение, редкость, возможность апгрейда и статус экипировки.
class EquippedItem {
  final int id;
  final String itemName;
  final String? imageUrl;
  final String rarity;
  final bool upgradeable;
  final bool isEquipped;

  const EquippedItem({
    required this.id,
    required this.itemName,
    this.imageUrl,
    required this.rarity,
    required this.upgradeable,
    required this.isEquipped,
  });

  factory EquippedItem.fromJson(Map<String, dynamic> json) {
    return EquippedItem(
      id: json['id'] ?? 0,
      itemName: json['item_name'] ?? '',
      imageUrl: json['image_url'],
      rarity: json['rarity'] ?? '',
      upgradeable: BooleanUtils.toBool(json['upgradeable']),
      isEquipped: BooleanUtils.toBool(json['is_equipped']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'image_url': imageUrl,
      'rarity': rarity,
      'upgradeable': upgradeable,
      'is_equipped': isEquipped,
    };
  }
}
