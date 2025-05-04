
enum TransactionType {
  credit,
  debit,
}

enum TransactionStatus {
  pending,
  successful,
  failed,
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? reference;
  
  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reference,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'].toString().toLowerCase() == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : json['amount'],
      description: json['description'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      reference: json['reference'],
    );
  }
  
  static TransactionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'successful':
        return TransactionStatus.successful;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == TransactionType.credit ? 'credit' : 'debit',
      'amount': amount,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'reference': reference,
    };
  }
}
