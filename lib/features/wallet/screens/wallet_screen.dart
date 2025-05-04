
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';
import 'package:campus_dash/features/wallet/providers/wallet_provider.dart';
import 'package:campus_dash/features/wallet/widgets/transaction_item.dart';
import 'package:campus_dash/shared/widgets/shimmer_loading.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Fetch wallet data when screen loads
    Future.microtask(() {
      ref.read(walletProvider.notifier).fetchWalletBalance();
      ref.read(walletProvider.notifier).fetchTransactions();
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final walletState = ref.read(walletProvider);
      
      if (!walletState.isLoadingTransactions && walletState.hasMoreTransactions) {
        ref.read(walletProvider.notifier).fetchTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final user = authState.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(walletProvider.notifier).refreshWallet();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Wallet balance card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildWalletCard(user?.wallet?.balance ?? 0.0, walletState.isLoadingBalance),
              ),
            ),
            
            // Virtual account info
            if (user?.wallet?.virtualAccountNumber != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildVirtualAccountCard(
                    accountNumber: user!.wallet!.virtualAccountNumber!,
                    accountName: user.wallet!.virtualAccountName!,
                    bankName: user.wallet!.virtualAccountBank!,
                  ),
                ),
              ),
            
            // Transaction history header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (walletState.transactions.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Open filter/sorting options
                        },
                        child: Row(
                          children: [
                            Text(
                              'Filter',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Transaction list
            walletState.isLoadingTransactions && walletState.transactions.isEmpty
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ShimmerLoading(height: 80),
                        );
                      },
                      childCount: 5,
                    ),
                  )
                : walletState.transactions.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == walletState.transactions.length) {
                              return walletState.isLoadingTransactions
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final transaction = walletState.transactions[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: TransactionItem(transaction: transaction),
                            );
                          },
                          childCount: walletState.transactions.length +
                              (walletState.hasMoreTransactions ? 1 : 0),
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open deposit dialog
          _showTopUpDialog(context);
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Top Up',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildWalletCard(double balance, bool isLoading) {
    if (isLoading) {
      return const ShimmerLoading(height: 150);
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              secondaryColor,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '₦${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildWalletAction(
                  icon: Icons.add,
                  label: 'Deposit',
                  onTap: () => _showTopUpDialog(context),
                ),
                const SizedBox(width: 16),
                _buildWalletAction(
                  icon: Icons.history,
                  label: 'History',
                  onTap: () {
                    // Already on wallet screen with history
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualAccountCard({
    required String accountNumber,
    required String accountName,
    required String bankName,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Virtual Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildAccountInfoRow('Account Number', accountNumber),
            const SizedBox(height: 8),
            _buildAccountInfoRow('Account Name', accountName),
            const SizedBox(height: 8),
            _buildAccountInfoRow('Bank', bankName),
            const SizedBox(height: 16),
            Text(
              'Use this account to top up your wallet instantly',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                // Copy to clipboard functionality
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transactions will appear here',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Top Up Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the amount you want to add to your wallet.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₦ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                // Process payment
                Navigator.of(context).pop();
                
                // For demo purposes, we'll just show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Top Up successful!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('TOP UP'),
            ),
          ],
        );
      },
    );
  }
}
