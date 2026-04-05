import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/shop_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _updateQty(
      BuildContext context, WidgetRef ref, String itemId, int newQty) async {
    try {
      if (newQty <= 0) {
        await Supabase.instance.client
            .from('cart_items')
            .delete()
            .eq('id', itemId);
      } else {
        await Supabase.instance.client
            .from('cart_items')
            .update({'quantity': newQty}).eq('id', itemId);
      }
      ref.invalidate(cartItemsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: cartAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(cartItemsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
                icon: Icons.shopping_cart_outlined,
                title: 'Cart is empty',
                subtitle: 'Add products from the shop');
          }
          final total =
              items.fold<double>(0, (s, i) => s + i.total);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: AppTheme.primary
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(10)),
                          child: const Icon(Icons.medical_services,
                              color: AppTheme.primary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  item.product?.name ??
                                      'Product',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(
                                  '\$${item.product?.price.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primary,
                                      fontWeight:
                                          FontWeight.w500)),
                            ],
                          ),
                        ),
                        Row(children: [
                          _QtyBtn(
                            icon: Icons.remove,
                            onTap: () => _updateQty(
                                context,
                                ref,
                                item.id,
                                item.quantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: Text('${item.quantity}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold)),
                          ),
                          _QtyBtn(
                            icon: Icons.add,
                            onTap: () => _updateQty(
                                context,
                                ref,
                                item.id,
                                item.quantity + 1),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border:
                      Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary)),
                      ]),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content:
                                      Text('Order placed! 🎉'),
                                  backgroundColor:
                                      AppTheme.healthGreen));
                        },
                        child: const Text('Place Order'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}
