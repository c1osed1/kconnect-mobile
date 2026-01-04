import 'package:kconnect_mobile/core/utils/boolean_utils.dart';
import 'package:kconnect_mobile/features/profile/domain/models/achievement_info.dart';
import 'package:kconnect_mobile/features/profile/domain/models/connection_info.dart';
import 'package:kconnect_mobile/features/profile/domain/models/equipped_item.dart';
import 'package:kconnect_mobile/features/profile/domain/models/purchased_username.dart';
import 'package:kconnect_mobile/features/profile/domain/models/social_link.dart';
import 'package:kconnect_mobile/features/profile/domain/models/subscription_info.dart';
import 'package:kconnect_mobile/features/profile/domain/models/verification_info.dart';

/// Модель данных профиля пользователя
///
/// Содержит всю информацию о профиле пользователя включая
/// личные данные, статистику, верификацию и социальные связи.
class UserProfile {
  // Basic user info
  final int id;
  final String name;
  final String username;
  final String? about;
  final String? photo;
  final String? coverPhoto;
  final String? statusText;
  final String? statusColor;
  final String? profileId;

  // Stats
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final int postsCount;
  final int photosCount;

  // Media URLs
  final String? avatarUrl;
  final String? bannerUrl;
  final String? profileBackgroundUrl;

  // Profile colors
  final String? profileColor;

  // Status and verification
  final String verificationStatus;
  final VerificationInfo? verification;
  final bool scam;

  // Account details
  final String accountType;
  final int? mainAccountId;
  final bool elementConnected;
  final String? elementId;
  final String? telegramId;
  final String? telegramUsername;
  final DateTime registrationDate;

  // Interests
  final List<String> interests;

  // Purchased items
  final List<PurchasedUsername> purchasedUsernames;

  // Relationship status (for viewing other profiles)
  final bool? isFollowing;
  final bool? isFriend;
  final bool? notificationsEnabled;

  // Social links
  final List<SocialLink> socials;

  // Achievement and subscription
  final AchievementInfo? achievement;
  final SubscriptionInfo? subscription;

  // Connections
  final List<ConnectionInfo> connectInfo;

  // Items
  final List<EquippedItem> equippedItems;

  // Ban status
  final Map<String, dynamic>? ban;

  // Moderator info
  final bool? currentUserIsModerator;

  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.about,
    this.photo,
    this.coverPhoto,
    this.statusText,
    this.statusColor,
    this.profileId,
    required this.followersCount,
    required this.followingCount,
    required this.friendsCount,
    required this.postsCount,
    required this.photosCount,
    this.avatarUrl,
    this.bannerUrl,
    this.profileBackgroundUrl,
    this.profileColor,
    required this.verificationStatus,
    this.verification,
    required this.scam,
    required this.accountType,
    this.mainAccountId,
    required this.elementConnected,
    this.elementId,
    this.telegramId,
    this.telegramUsername,
    required this.registrationDate,
    required this.interests,
    required this.purchasedUsernames,
    this.isFollowing,
    this.isFriend,
    this.notificationsEnabled,
    required this.socials,
    this.achievement,
    this.subscription,
    required this.connectInfo,
    required this.equippedItems,
    this.ban,
    this.currentUserIsModerator,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      final profileIdValue = json['user']['profile_id'];
      final profileId = profileIdValue?.toString();

      return UserProfile(
        id: json['user']['id'] is int ? json['user']['id'] : 0,
        name: (json['user']['name'] ?? '').toString(),
        username: (json['user']['username'] ?? '').toString(),
        about: json['user']['about']?.toString(),
        photo: json['user']['photo']?.toString(),
        coverPhoto: json['user']['cover_photo']?.toString(),
        statusText: json['user']['status_text']?.toString(),
        statusColor: json['user']['status_color']?.toString(),
        profileId: profileId,
        followersCount: json['followers_count'] is int ? json['followers_count'] : 0,
        followingCount: json['following_count'] is int ? json['following_count'] : 0,
        friendsCount: json['friends_count'] is int ? json['friends_count'] : 0,
        postsCount: json['posts_count'] is int ? json['posts_count'] : 0,
        photosCount: json['photos_count'] is int ? json['photos_count'] : 0,
        avatarUrl: json['user']['avatar_url']?.toString(),
        bannerUrl: json['user']['banner_url']?.toString(),
        profileBackgroundUrl: json['user']['profile_background_url']?.toString(),
        profileColor: json['user']['profile_color']?.toString(),
        verificationStatus: (json['user']['verification_status'] ?? 'none').toString(),
        verification: json['verification'] != null && json['verification'] is Map<String, dynamic>
            ? VerificationInfo.fromJson(json['verification'])
            : null,
        scam: BooleanUtils.toBool(json['user']['scam']),
        accountType: (json['user']['account_type'] ?? 'user').toString(),
        mainAccountId: json['user']['main_account_id'] is int ? json['user']['main_account_id'] as int : null,
        elementConnected: BooleanUtils.toBool(json['user']['element_connected']),
        elementId: json['user']['element_id']?.toString(),
        telegramId: json['user']['telegram_id']?.toString(),
        telegramUsername: json['user']['telegram_username']?.toString(),
        registrationDate: (() {
          final regDateRaw = json['user']['registration_date'];
          if (regDateRaw is int) {
            return DateTime.fromMillisecondsSinceEpoch(regDateRaw * 1000);
          } else if (regDateRaw is String) {
            return DateTime.parse(regDateRaw);
          }
          return DateTime.now();
        })(),
        interests: json['user']['interests'] is List<dynamic>
            ? List<String>.from(json['user']['interests'] ?? [])
            : [],
        purchasedUsernames: (json['user']['purchased_usernames'] is List)
                ? (json['user']['purchased_usernames'] as List<dynamic>)
                    .map((e) => PurchasedUsername.fromJson(e))
                    .toList()
                : [],
        isFollowing: json['is_following'] != null ? BooleanUtils.toBool(json['is_following']) : null,
        isFriend: json['is_friend'] != null ? BooleanUtils.toBool(json['is_friend']) : null,
        notificationsEnabled: json['notifications_enabled'] != null ? BooleanUtils.toBool(json['notifications_enabled']) : null,
        socials: (json['socials'] is List)
                ? (json['socials'] as List<dynamic>)
                    .map((e) => SocialLink.fromJson(e))
                    .toList()
                : [],
        achievement: json['achievement'] != null && json['achievement'] is Map<String, dynamic>
            ? AchievementInfo.fromJson(json['achievement'])
            : null,
        subscription: json['subscription'] != null && json['subscription'] is Map<String, dynamic>
            ? SubscriptionInfo.fromJson(json['subscription'])
            : null,
        connectInfo: (json['connect_info'] is List)
                ? (json['connect_info'] as List<dynamic>)
                    .map((e) => ConnectionInfo.fromJson(e))
                    .toList()
                : [],
        equippedItems: (json['equipped_items'] is List)
                ? (json['equipped_items'] as List<dynamic>)
                    .map((e) => EquippedItem.fromJson(e))
                    .toList()
                : [],
        ban: json['ban'],
        currentUserIsModerator: json['current_user_is_moderator'] != null ? BooleanUtils.toBool(json['current_user_is_moderator']) : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'name': name,
        'username': username,
        'about': about,
        'photo': photo,
        'cover_photo': coverPhoto,
        'status_text': statusText,
        'status_color': statusColor,
        'profile_id': profileId,
        'avatar_url': avatarUrl,
        'banner_url': bannerUrl,
        'profile_background_url': profileBackgroundUrl,
        'profile_color': profileColor,
        'verification_status': verificationStatus,
        'scam': scam,
        'account_type': accountType,
        'main_account_id': mainAccountId,
        'element_connected': elementConnected,
        'element_id': elementId,
        'telegram_id': telegramId,
        'telegram_username': telegramUsername,
        'registration_date': registrationDate.toIso8601String(),
        'interests': interests,
        'purchased_usernames': purchasedUsernames.map((e) => e.toJson()).toList(),
      },
      'followers_count': followersCount,
      'following_count': followingCount,
      'friends_count': friendsCount,
      'posts_count': postsCount,
      'photos_count': photosCount,
      'is_following': isFollowing,
      'is_friend': isFriend,
      'notifications_enabled': notificationsEnabled,
      'socials': socials.map((e) => e.toJson()).toList(),
      'verification': verification?.toJson(),
      'achievement': achievement?.toJson(),
      'subscription': subscription?.toJson(),
      'connect_info': connectInfo.map((e) => e.toJson()).toList(),
      'equipped_items': equippedItems.map((e) => e.toJson()).toList(),
      'ban': ban,
      'current_user_is_moderator': currentUserIsModerator,
    };
  }

  // Helper methods for UI
  bool get isVerified => verificationStatus == 'verified';
  bool get isBanned => ban?['is_banned'] ?? false;
  bool get hasPremium => subscription?.active ?? false;
}
