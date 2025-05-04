
import 'package:flutter/material.dart';
import 'package:campus_dash/features/wallet/models/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final Color amountColor = transaction.type == TransactionType.credit
        ? Colors.green.shade700
        : Colors.red.shade700;

    final IconData transactionIcon = transaction.type == TransactionType.credit
        ? Icons.arrow_downward
        : Icons.arrow_upward;

    final String amountPrefix = transaction.type == TransactionType.credit
        ? '+'
        : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Transaction icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                transactionIcon,
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM d, h:mm a').format(transaction.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(transaction.status),
                    ],
                  ),
                ],
              ),
            ),
            
            // Transaction amount
            Text(
              '$amountPrefix₦${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    Color color;
    String text;

    switch (status) {
      case TransactionStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TransactionStatus.successful:
        color = Colors.green;
        text = 'Success';
        break;
      case TransactionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
