
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final Wallet? wallet;
  final String? profilePicture;
  
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
    this.wallet,
    this.profilePicture,
  });
  
  String get fullName => '$firstName $lastName';
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      isVerified: json['isVerified'] ?? false,
      wallet: json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null,
      profilePicture: json['profilePicture'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'wallet': wallet?.toJson(),
      'profilePicture': profilePicture,
    };
  }
}

class Wallet {
  final double balance;
  final String? virtualAccountNumber;
  final String? virtualAccountName;
  final String? virtualAccountBank;
  
  Wallet({
    required this.balance,
    this.virtualAccountNumber,
    this.virtualAccountName,
    this.virtualAccountBank,
  });
  
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] is int) 
          ? (json['balance'] as int).toDouble() 
          : json['balance'],
      virtualAccountNumber: json['virtualAccountNumber'],
      virtualAccountName: json['virtualAccountName'],
      virtualAccountBank: json['virtualAccountBank'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'virtualAccountNumber': virtualAccountNumber,
      'virtualAccountName': virtualAccountName,
      'virtualAccountBank': virtualAccountBank,
    };
  }
}
