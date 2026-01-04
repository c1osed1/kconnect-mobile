/// Информация о подписке между пользователями
///
/// Хранит статус подписки: подписан ли текущий пользователь,
/// является ли другой пользователь другом, подписан ли он обратно.
class FollowingInfo {
  final bool currentUserFollows;
  final bool currentUserIsFriend;
  final bool followsBack;

  const FollowingInfo({
    required this.currentUserFollows,
    required this.currentUserIsFriend,
    required this.followsBack,
  });

  factory FollowingInfo.fromJson(Map<String, dynamic> json) {
    return FollowingInfo(
      currentUserFollows: json['current_user_follows'] ?? false,
      currentUserIsFriend: json['is_friend'] ?? false,
      followsBack: true, // When this entry is found, it means profile follows current user
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_user_follows': currentUserFollows,
      'current_user_is_friend': currentUserIsFriend,
      'follows_back': followsBack,
    };
  }
}
