
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

  // Update the addToCart method
  static void addToCart(Map<String, dynamic> product) {
    int index = cartItems.indexWhere((item) => item.name == product['name']);

    if (index != -1) {
      cartItems[index].quantity++;
    } else {
      cartItems.add(CartItem(
        name: product['name'],
        price: product['price'],
        imageUrl: product['image_url'] ?? '', // Add this
        category: product['category'] ?? 'General',
        quantity: 1,
      ));
    }
  }

  static double getTotalPrice() {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}