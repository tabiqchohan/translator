import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/ad_service.dart';

/// Wraps RevenueCat and exposes the user's Pro entitlement to the UI.
class SubscriptionProvider extends ChangeNotifier {
  /// RevenueCat SDK key (Google Play, production).
  static const String _googleApiKey = 'goog_IDwAEjvhImrmGWbxDqjZcUSUxLB';

  static const String entitlementPro = 'pro';

  bool _configured = false;
  bool _isPro = false;
  bool _loading = false;
  List<Package> _packages = [];
  String? _error;

  bool get isPro => _isPro;
  bool get loading => _loading;
  bool get configured => _configured;
  List<Package> get packages => _packages;
  String? get error => _error;

  Future<void> init() async {
    if (_configured) return;
    // Skip configuration while the placeholder key is still in place so the
    // app stays usable during development.
    if (_googleApiKey.contains('REPLACE')) {
      debugPrint('RevenueCat: placeholder API key, skipping configure.');
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(_googleApiKey));
      _configured = true;
      await _refresh();
    } catch (e) {
      debugPrint('RevenueCat configure error: $e');
    }
  }

  /// Links the signed-in user so the backend webhook can map purchases.
  Future<void> identify(String appUserId) async {
    if (!_configured) await init();
    if (!_configured) return;
    try {
      final result = await Purchases.logIn(appUserId);
      _apply(result.customerInfo);
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  Future<void> _refresh() async {
    if (!_configured) return;
    try {
      _apply(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo error: $e');
    }
  }

  void _apply(CustomerInfo info) {
    final pro = info.entitlements.active.containsKey(entitlementPro);
    _isPro = pro;
    AdService.instance.adFree = pro;
    notifyListeners();
  }

  Future<void> loadOffering() async {
    if (!_configured) await init();
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      _packages = current?.availablePackages ?? [];
      debugPrint(
          'RevenueCat offerings: all=${offerings.all.keys.toList()} '
          'current=${current?.identifier} packages=${_packages.length}');
      if (current == null) {
        _error =
            'No "Current" offering set in RevenueCat. Open RevenueCat → Offerings, '
            'set one as Current with Monthly/Yearly/Lifetime packages.';
      } else if (_packages.isEmpty) {
        _error =
            'Offering "${current.identifier}" has no packages. Attach your Play '
            'products to Monthly/Yearly/Lifetime packages in RevenueCat.';
      }
    } catch (e) {
      debugPrint('RevenueCat getOfferings error: $e');
      _packages = [];
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Returns null on success or user-cancel, otherwise an error message.
  Future<String?> purchase(Package package) async {
    try {
      // Note: in some newer versions purchasePackage returns PurchaseResult.
      // Keep compatible by handling both shapes via dynamic.
      final dynamic result = await Purchases.purchasePackage(package);
      if (result is CustomerInfo) {
        _apply(result);
      } else if (result != null && (result as dynamic).customerInfo is CustomerInfo) {
        _apply((result as dynamic).customerInfo as CustomerInfo);
      } else {
        await _refresh();
      }
      return null;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return null;
      return e.message ?? 'Purchase failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> restore() async {
    if (!_configured) return false;
    try {
      _apply(await Purchases.restorePurchases());
      return _isPro;
    } catch (e) {
      debugPrint('RevenueCat restore error: $e');
      return false;
    }
  }
}
