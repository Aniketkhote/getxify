import 'package:flutter/material.dart';

/// Demo product model for the GetXify E-Commerce example app
class DemoProduct {
  final String id;
  final String name;
  final String category;
  final double price;
  final double oldPrice;
  final double rating;
  final int reviewCount;
  final String description;
  final String badge;
  final IconData iconData;
  final Color themeColor;
  final bool isFeatured;

  const DemoProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.badge,
    required this.iconData,
    required this.themeColor,
    this.isFeatured = false,
  });

  double get discountPercent {
    if (oldPrice <= price) return 0;
    return (((oldPrice - price) / oldPrice) * 100).roundToDouble();
  }

  static const List<DemoProduct> sampleProducts = [
    DemoProduct(
      id: 'prod-101',
      name: 'Wireless Noise-Canceling Headphones',
      category: 'Electronics',
      price: 3999.00,
      oldPrice: 4999.00,
      rating: 4.8,
      reviewCount: 342,
      description:
          'High-fidelity wireless sound with ultra-low latency and dynamic spatial audio for immersive listening.',
      badge: 'Best Seller',
      iconData: Icons.headphones,
      themeColor: Colors.deepPurple,
      isFeatured: true,
    ),
    DemoProduct(
      id: 'prod-102',
      name: 'Smart Watch Pro Series 8',
      category: 'Electronics',
      price: 5999.00,
      oldPrice: 6999.00,
      rating: 4.9,
      reviewCount: 512,
      description:
          'Track workouts, monitor health metrics, and stay connected with a vibrant AMOLED display.',
      badge: 'Hot Deal',
      iconData: Icons.watch_outlined,
      themeColor: Colors.indigo,
      isFeatured: true,
    ),
    DemoProduct(
      id: 'prod-103',
      name: 'Ergonomic Mechanical Keyboard',
      category: 'Accessories',
      price: 2499.00,
      oldPrice: 3199.00,
      rating: 4.7,
      reviewCount: 189,
      description:
          'Customizable RGB backlighting with hot-swappable tactile mechanical switches for typing speed.',
      badge: 'Top Rated',
      iconData: Icons.keyboard_alt_outlined,
      themeColor: Colors.teal,
      isFeatured: false,
    ),
    DemoProduct(
      id: 'prod-104',
      name: 'Ultra-HD Smart Camera Drone',
      category: 'Electronics',
      price: 12999.00,
      oldPrice: 15999.00,
      rating: 4.6,
      reviewCount: 97,
      description:
          'Compact drone with 4K HDR camera, obstacle sensing, and intelligent flight modes.',
      badge: 'New Arrival',
      iconData: Icons.camera_indoor_outlined,
      themeColor: Colors.orange,
      isFeatured: true,
    ),
    DemoProduct(
      id: 'prod-105',
      name: 'Minimalist Leather Backpack',
      category: 'Fashion',
      price: 1899.00,
      oldPrice: 2499.00,
      rating: 4.5,
      reviewCount: 230,
      description:
          'Crafted from genuine full-grain leather with dedicated 15-inch laptop compartment.',
      badge: 'Trending',
      iconData: Icons.card_travel,
      themeColor: Colors.brown,
      isFeatured: false,
    ),
    DemoProduct(
      id: 'prod-106',
      name: 'Portable Bluetooth Speaker',
      category: 'Electronics',
      price: 1499.00,
      oldPrice: 1999.00,
      rating: 4.8,
      reviewCount: 410,
      description:
          'Waterproof IPX7 speaker with 24-hour battery life and deep bass performance.',
      badge: 'Sale',
      iconData: Icons.speaker,
      themeColor: Colors.pink,
      isFeatured: true,
    ),
  ];
}
