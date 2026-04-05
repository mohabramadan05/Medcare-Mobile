import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

SupabaseClient get _client => Supabase.instance.client;

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final data = await _client
      .from('products')
      .select()
      .eq('is_active', true)
      .order('name', ascending: true);
  return (data as List).map((e) => ProductModel.fromJson(e)).toList();
});

final cartItemsProvider = FutureProvider<List<CartItemModel>>((ref) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await _client
      .from('cart_items')
      .select('*, products(*)')
      .eq('user_id', userId);
  return (data as List).map((e) => CartItemModel.fromJson(e)).toList();
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartItemsProvider);
  return cart.whenOrNull(data: (items) => items.fold<int>(0, (s, i) => s + i.quantity)) ?? 0;
});
