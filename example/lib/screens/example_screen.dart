import 'package:flutter/material.dart';
import 'package:golden_test_example/l10n/app_localizations.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + bottomInset,
          ),
          children: [
            _Header(theme: theme, colorScheme: colorScheme, l10n: l10n),
            const SizedBox(height: 24),
            _BalanceCard(theme: theme, colorScheme: colorScheme, l10n: l10n),
            const SizedBox(height: 20),
            _QuickActions(colorScheme: colorScheme, l10n: l10n),
            const SizedBox(height: 28),
            _MiniChart(colorScheme: colorScheme, l10n: l10n),
            const SizedBox(height: 28),
            Text(l10n.recentTransactions,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._buildTransactions(l10n).map(
              (t) => _TransactionTile(transaction: t, theme: theme),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    required this.colorScheme,
    required this.l10n,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colorScheme.primaryContainer,
          child:
              Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.goodMorning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(150),
                  )),
              Text('Sarah Johnson',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_outlined,
              color: colorScheme.onSurface.withAlpha(180)),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.theme,
    required this.colorScheme,
    required this.l10n,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: colorScheme.onPrimary.withAlpha(200), size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.totalBalance,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$24,562.80',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up_rounded,
                    color: colorScheme.onPrimary, size: 16),
                const SizedBox(width: 4),
                Text(
                  l10n.thisMonth,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_downward_rounded,
                  label: l10n.income,
                  value: '\$8,240',
                  color: colorScheme.onPrimary,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: colorScheme.onPrimary.withAlpha(60),
              ),
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_upward_rounded,
                  label: l10n.spending,
                  value: '\$3,680',
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color.withAlpha(180)),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withAlpha(180),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.colorScheme, required this.l10n});

  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        l10n.send,
        Icons.send_rounded,
        colorScheme.primary,
        colorScheme.primaryContainer
      ),
      (
        l10n.request,
        Icons.call_received_rounded,
        colorScheme.tertiary,
        colorScheme.tertiaryContainer
      ),
      (
        l10n.topUp,
        Icons.add_rounded,
        colorScheme.secondary,
        colorScheme.secondaryContainer
      ),
      (
        l10n.more,
        Icons.more_horiz_rounded,
        colorScheme.outline,
        colorScheme.surfaceContainerHighest
      ),
    ];

    return Row(
      children: actions.map((a) {
        final (label, icon, iconColor, bgColor) = a;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.colorScheme, required this.l10n});

  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const barHeights = [0.3, 0.5, 0.4, 0.7, 0.6, 0.9, 0.75];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const maxBarHeight = 80.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.weeklySpending,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$526',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: maxBarHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isHighlighted = i == 5;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeights[i] * maxBarHeight,
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? colorScheme.primary
                                : colorScheme.primary.withAlpha(60),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[i],
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isHighlighted
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withAlpha(120),
                                    fontWeight: isHighlighted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Transaction {
  const _Transaction({
    required this.icon,
    required this.name,
    required this.category,
    required this.amount,
    required this.isPositive,
    required this.color,
  });

  final IconData icon;
  final String name;
  final String category;
  final String amount;
  final bool isPositive;
  final Color color;
}

List<_Transaction> _buildTransactions(AppLocalizations l10n) => [
      _Transaction(
        icon: Icons.movie_rounded,
        name: 'StreamFlix',
        category: l10n.entertainment,
        amount: '-\$15.99',
        isPositive: false,
        color: const Color(0xFFE53935),
      ),
      _Transaction(
        icon: Icons.laptop_mac_rounded,
        name: 'Tech Store',
        category: l10n.technology,
        amount: '-\$249.00',
        isPositive: false,
        color: const Color(0xFF607D8B),
      ),
      _Transaction(
        icon: Icons.swap_horiz_rounded,
        name: 'Jane Smith',
        category: l10n.transferReceived,
        amount: '+\$1,200.00',
        isPositive: true,
        color: const Color(0xFF4CAF50),
      ),
      _Transaction(
        icon: Icons.local_cafe_rounded,
        name: 'Bean Brew',
        category: l10n.foodAndDrink,
        amount: '-\$6.40',
        isPositive: false,
        color: const Color(0xFF795548),
      ),
      _Transaction(
        icon: Icons.headphones_rounded,
        name: 'Musicly',
        category: l10n.entertainment,
        amount: '-\$9.99',
        isPositive: false,
        color: const Color(0xFF26A69A),
      ),
    ];

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.theme,
  });

  final _Transaction transaction;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: transaction.color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(transaction.icon, size: 22, color: transaction.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text(
                  transaction.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.amount,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: transaction.isPositive ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
