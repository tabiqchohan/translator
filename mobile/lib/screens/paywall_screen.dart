import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String? _purchasingId;

  static const _benefits = <(IconData, String, String)>[
    (Icons.all_inclusive_rounded, 'Unlimited translations',
        'No daily limits — translate as much as you want.'),
    (Icons.block_rounded, 'Ad-free experience', 'No banners, no interstitials.'),
    (Icons.flash_on_rounded, 'Live Chat Translate',
        'Real-time translation inside WhatsApp, Messenger & more.'),
    (Icons.description_rounded, 'Document translation',
        'Translate PDF, DOCX and TXT files.'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadOffering();
    });
  }

  Future<void> _buy(SubscriptionProvider sub, Package package) async {
    setState(() => _purchasingId = package.identifier);
    final error = await sub.purchase(package);
    if (!mounted) return;
    setState(() => _purchasingId = null);
    if (sub.isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to LingoVerse Pro! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restore(SubscriptionProvider sub) async {
    setState(() => _purchasingId = 'restore');
    final ok = await sub.restore();
    if (!mounted) return;
    setState(() => _purchasingId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Purchases restored. You are Pro!'
            : 'No active subscription found.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) Navigator.pop(context, true);
  }

  String _label(Package p) {
    switch (p.packageType) {
      case PackageType.annual:
        return 'Yearly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.lifetime:
        return 'Lifetime';
      case PackageType.weekly:
        return 'Weekly';
      default:
        return p.storeProduct.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 52),
                      const SizedBox(height: 12),
                      const Text(
                        'LingoVerse Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Unlock everything and translate without limits.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            for (final b in _benefits)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(b.$1,
                                          color: const Color(0xFF6366F1),
                                          size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(b.$2,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              )),
                                          Text(
                                            b.$3,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .textTheme.bodySmall?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (sub.loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          ),
                        )
                      else if (sub.packages.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plans are not available right now.',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                              if (sub.error != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  sub.error!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Colors.white54),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => sub.loadOffering(),
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 18),
                                  label: const Text('Retry'),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (final p in sub.packages) ...[
                          _packageTile(sub, p),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton(
                          onPressed: _purchasingId != null
                              ? null
                              : () => _restore(sub),
                          child: Text(
                            'Restore Purchases',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Payment will be charged to your Google Play account. '
                          'Cancel anytime in Play Store subscriptions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _packageTile(SubscriptionProvider sub, Package p) {
    final busy = _purchasingId == p.identifier;
    final anyBusy = _purchasingId != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: anyBusy ? null : () => _buy(sub, p),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(p),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.storeProduct.priceString,
                      style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF6366F1)),
            ],
          ),
        ),
      ),
    );
  }
}
