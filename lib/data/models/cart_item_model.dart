class CartItemModel {
  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  final String? productOwnerId;
  int quantity;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.productOwnerId,
    this.quantity = 1,
  });

  double get total => price * quantity;
}