import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/shop_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _selectedCategory;

  Future<void> _addToCart(String productId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final existing = await Supabase.instance.client
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();
      if (existing != null) {
        await Supabase.instance.client
            .from('cart_items')
            .update({'quantity': (existing['quantity'] as int) + 1})
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('cart_items').insert(
            {'user_id': userId, 'product_id': productId, 'quantity': 1});
      }
      ref.invalidate(cartItemsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Added to cart!'),
            backgroundColor: AppTheme.healthGreen,
            duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.push('/shop/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                        color: AppTheme.error, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$cartCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(productsProvider)),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyStateWidget(
                icon: Icons.shopping_bag_outlined,
                title: 'No products available',
                subtitle: 'Check back later');
          }

          // Build category list
          final categories = products
              .map((p) => p.categoryLabel ?? p.category ?? 'Other')
              .toSet()
              .toList();

          final filtered = _selectedCategory == null
              ? products
              : products
                  .where((p) =>
                      (p.categoryLabel ?? p.category) ==
                      _selectedCategory)
                  .toList();

          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                        selectedColor:
                            AppTheme.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: _selectedCategory == null
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontWeight: _selectedCategory == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (_) => setState(
                                () => _selectedCategory = cat),
                            selectedColor:
                                AppTheme.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppTheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedCategory == cat
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: _selectedCategory == cat
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.05),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                              ),
                              child: const Center(
                                child: Icon(Icons.medical_services,
                                    size: 48,
                                    color: AppTheme.primary),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                if (p.rating != null)
                                  Row(children: [
                                    const Icon(Icons.star,
                                        size: 12,
                                        color: AppTheme.warning),
                                    const SizedBox(width: 3),
                                    Text(
                                        p.rating!.toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppTheme.textSecondary)),
                                    if (p.reviewsCount != null) ...[
                                      const SizedBox(width: 3),
                                      Text(
                                          '(${p.reviewsCount})',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppTheme.textLight)),
                                    ],
                                  ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Text(
                                      '\$${p.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _addToCart(p.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(Icons.add,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
