
class CartItem {
  final String name;
  final double price;
  final String imageUrl; // Add this
  int quantity;
  final String category;

  CartItem({
    required this.name,
    required this.price,
    required this.imageUrl, // Add this
    this.quantity = 1,
    required this.category,
  });
}

class CartManager {
  // Global list to store cart items
  static List<CartItem> cartItems = [];

  // Update the addToCart method to support quantity
  static void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    int index = cartItems.indexWhere((item) => item.name == product['name']);

    if (index != -1) {
      cartItems[index].quantity += quantity;
    } else {
      cartItems.add(CartItem(
        name: product['name'],
        price: product['price'],
        imageUrl: product['image_url'] ?? '',
        category: product['category'] ?? 'General',
        quantity: quantity,
      ));
    }
  }

  static double getTotalPrice() {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}