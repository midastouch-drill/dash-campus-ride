
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/services/api_service.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';
import 'package:campus_dash/features/wallet/models/transaction_model.dart';

class WalletState {
  final bool isLoadingBalance;
  final bool isLoadingTransactions;
  final String? error;
  final List<Transaction> transactions;
  final bool hasMoreTransactions;
  final int currentPage;

  WalletState({
    this.isLoadingBalance = false,
    this.isLoadingTransactions = false,
    this.error,
    this.transactions = const [],
    this.hasMoreTransactions = true,
    this.currentPage = 1,
  });

  WalletState copyWith({
    bool? isLoadingBalance,
    bool? isLoadingTransactions,
    String? error,
    List<Transaction>? transactions,
    bool? hasMoreTransactions,
    int? currentPage,
  }) {
    return WalletState(
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      isLoadingTransactions: isLoadingTransactions ?? this.isLoadingTransactions,
      error: error ?? this.error,
      transactions: transactions ?? this.transactions,
      hasMoreTransactions: hasMoreTransactions ?? this.hasMoreTransactions,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final ApiService _apiService;
  final AuthNotifier _authNotifier;

  WalletNotifier(this._apiService, this._authNotifier) : super(WalletState());

  Future<void> fetchWalletBalance() async {
    if (state.isLoadingBalance) return;
    
    state = state.copyWith(isLoadingBalance: true, error: null);
    
    try {
      final response = await _apiService.get('/wallet/balance');
      
      // Update wallet balance by refreshing user profile which contains wallet data
      await _authNotifier.getUserProfile();
      
      state = state.copyWith(isLoadingBalance: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingBalance: false,
        error: 'Failed to load wallet balance: ${e.toString()}',
      );
    }
  }

  Future<void> fetchTransactions({int limit = 10}) async {
    if (state.isLoadingTransactions) return;
    
    final currentPage = state.currentPage;
    
    if (currentPage > 1 && !state.hasMoreTransactions) return;
    
    state = state.copyWith(isLoadingTransactions: true, error: null);
    
    try {
      final queryParams = {
        'limit': limit.toString(),
        'page': currentPage.toString(),
      };
      
      final response = await _apiService.get(
        '/wallet/transactions',
        queryParameters: queryParams,
      );
      
      final List<Transaction> newTransactions = (response['data']['transactions'] as List)
          .map((transaction) => Transaction.fromJson(transaction))
          .toList();
      
      final List<Transaction> updatedTransactions = currentPage == 1
          ? newTransactions
          : [...state.transactions, ...newTransactions];
      
      state = state.copyWith(
        isLoadingTransactions: false,
        transactions: updatedTransactions,
        hasMoreTransactions: newTransactions.length >= limit,
        currentPage: currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTransactions: false,
        error: 'Failed to load transactions: ${e.toString()}',
      );
    }
  }

  Future<void> refreshWallet() async {
    state = state.copyWith(
      currentPage: 1,
      hasMoreTransactions: true,
      error: null,
    );
    
    await fetchWalletBalance();
    await fetchTransactions();
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return WalletNotifier(apiService, authNotifier);
});
