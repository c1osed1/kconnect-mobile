import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../../core/utils/theme_extensions.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../routes/route_names.dart';
import '../../../../routes/app_router.dart';
import '../blocs/account_bloc.dart';
import '../blocs/account_event.dart';
import '../blocs/account_state.dart';
import '../../domain/models/account.dart';

class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Загружаем аккаунты при первом построении
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountBloc = context.read<AccountBloc>();
      if (accountBloc.state is AccountInitial) {
        accountBloc.add(LoadAccountsEvent());
      }
    });

    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        if (state is AccountLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AccountError) {
          return Center(
            child: Text(
              'Ошибка: ${state.message}',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          );
        }

        if (state is AccountLoaded) {
          return _buildMenu(context, state.accounts, state.activeAccount);
        }

        if (state is AccountSwitching) {
          return _buildSwitchingMenu(context, state.fromAccount, state.toAccount);
        }

        if (state is AccountSwitched) {
          return _buildMenu(context, [], state.activeAccount);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMenu(BuildContext context, List<Account> accounts, Account? activeAccount) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 280),
      child: LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 15,
          glassColor: Color(0x33FFFFFF),
          lightIntensity: 1.5,
          chromaticAberration: 1,
          saturation: 1.1,
          ambientStrength: 1,
          blur: 4,
          refractiveIndex: 1.8,
        ),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha:0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Аккаунты',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Список аккаунтов
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final isActive = account.id == activeAccount?.id;
                      return _buildAccountItem(context, account, isActive);
                    },
                  ),
                ),

                // Разделитель
                if (accounts.isNotEmpty)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.textSecondary.withValues(alpha:0.3),
                  ),

                // Кнопка добавить аккаунт
                _buildAddAccountButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchingMenu(BuildContext context, Account? fromAccount, Account toAccount) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 280),
      child: LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 15,
          glassColor: Color(0x33FFFFFF),
          lightIntensity: 1.5,
          chromaticAberration: 1,
          saturation: 1.1,
          ambientStrength: 1,
          blur: 4,
          refractiveIndex: 1.8,
        ),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha:0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Переключение аккаунта',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Индикатор загрузки
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Выполняется вход...',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem(BuildContext context, Account account, bool isActive) {
    return InkWell(
      onTap: () {
        if (!isActive) {
          // Просто выполняем переключение аккаунта
          context.read<AccountBloc>().add(SwitchAccountEvent(account));
          Navigator.of(context).pop(); // Закрыть меню
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Аватар
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? context.dynamicPrimaryColor : AppColors.textSecondary.withValues(alpha:0.2),
                border: isActive ? Border.all(color: context.dynamicPrimaryColor, width: 2) : null,
              ),
              child: account.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        account.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: isActive ? AppColors.bgWhite : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: isActive ? AppColors.bgWhite : AppColors.textSecondary,
                      size: 20,
                    ),
            ),

            const SizedBox(width: 12),

            // Информация об аккаунте
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.username,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (isActive)
                    Text(
                      'Активный',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: context.dynamicPrimaryColor,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),

            // Кнопка удаления
            IconButton(
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 18,
              ),
              onPressed: () {
                _showDeleteConfirmation(context, account);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountButton(BuildContext context) {
    return InkWell(
      onTap: () {
        debugPrint('AccountMenu: Add account button pressed');

        Navigator.of(context).pop(); // Закрыть меню

        // Используем глобальный navigator key с задержкой для надежности
        Future.delayed(const Duration(milliseconds: 100), () {
          debugPrint('AccountMenu: Attempting navigation to AddAccountScreen');
          AppRouter.navigatorKey.currentState?.pushNamed(RouteNames.addAccount);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary.withValues(alpha:0.2),
              ),
              child: Icon(
                Icons.add,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Добавить аккаунт',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgDark,
        title: Text(
          'Удалить аккаунт',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Вы уверены, что хотите удалить аккаунт "${account.username}"? Все данные этого аккаунта будут потеряны.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Отмена',
              style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AccountBloc>().add(RemoveAccountEvent(account.id));
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Удалить',
              style: AppTextStyles.button.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
