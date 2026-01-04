import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/utils/theme_extensions.dart';
import '../../domain/models/account.dart';

class AccountSwitchingAnimation extends StatefulWidget {
  final Account targetAccount;
  final VoidCallback onAnimationComplete;

  const AccountSwitchingAnimation({
    super.key,
    required this.targetAccount,
    required this.onAnimationComplete,
  });

  @override
  State<AccountSwitchingAnimation> createState() => _AccountSwitchingAnimationState();
}

class _AccountSwitchingAnimationState extends State<AccountSwitchingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('🎨 AccountSwitchingAnimation: initState for ${widget.targetAccount.username}');

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0, // 2 полных оборота
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.linear),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDark.withValues(alpha:0.9),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.dynamicPrimaryColor.withValues(alpha:0.3),
                        context.dynamicPrimaryColor.withValues(alpha:0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Крутящийся бордер
                      Transform.rotate(
                        angle: _rotationAnimation.value * 3.14159,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.dynamicPrimaryColor,
                              width: 3,
                            ),
                          ),
                        ),
                      ),

                      // Аватарка в центре
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                          border: Border.all(
                            color: context.dynamicPrimaryColor,
                            width: 2,
                          ),
                        ),
                        child: widget.targetAccount.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  widget.targetAccount.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    color: AppColors.bgWhite,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: AppColors.bgWhite,
                                size: 40,
                              ),
                      ),

                      // Текст под аватаркой
                      Positioned(
                        bottom: -25,
                        child: Text(
                          'Переключение...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
