class MovieModel {
  String id;
  String title;
  String description;
  String category;
  String subscriptionPackage;
  String imageUrl;
  String trailerUrl;
  String createdAt;

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subscriptionPackage,
    required this.imageUrl,
    required this.trailerUrl,
    required this.createdAt,
  });

  static fromJson(json) {
    return MovieModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      subscriptionPackage: json['subscriptionPackage'],
      imageUrl: json['imageUrl'],
      trailerUrl: json['trailerUrl'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'subscriptionPackage': subscriptionPackage,
      'imageUrl': imageUrl,
      'trailerUrl': trailerUrl,
      'createdAt': createdAt,
    };
  }
}
