class UserModel {
  String id;
  String name;
  String email;
  String password;
  String subscriptionPackage;
  String type;
  String createdAt;

  UserModel.empty()
      : id = '',
        name = '',
        email = '',
        password = '',
        subscriptionPackage = '',
        type = '',
        createdAt = '';

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.subscriptionPackage,
    required this.type,
    required this.createdAt,
  });

  static fromJson(json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      subscriptionPackage: json['subscriptionPackage'],
      type: json['type'],
      createdAt: json['createdAt'],
    );
  }
}
