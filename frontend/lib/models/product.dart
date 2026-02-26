class Product {
  final String title;
  final String? price;
  final String? link;
  final String? thumbnail;
  final String? source;
  final double? rating;
  final int? ratingCount;

  const Product({
    required this.title,
    this.price,
    this.link,
    this.thumbnail,
    this.source,
    this.rating,
    this.ratingCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        title: json['title'] as String? ?? 'Unknown Product',
        price: json['price'] as String?,
        link: json['link'] as String?,
        thumbnail: json['thumbnail'] as String?,
        source: json['source'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        ratingCount: json['ratingCount'] as int?,
      );
}
