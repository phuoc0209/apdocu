import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet.dart';
import '../providers/auth.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  String _selectedType = 'deposit'; // deposit or withdraw

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  void _loadWalletData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      walletProvider.loadBalance(authProvider.userId!);
      walletProvider.loadTransactions(authProvider.userId!, limit: 50);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleTransaction() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    if (authProvider.userId == null) return;

    Map<String, dynamic> result;
    if (_selectedType == 'deposit') {
      result = await walletProvider.deposit(
        authProvider.userId!,
        amount,
        description: 'Nạp tiền vào ví',
      );
    } else {
      result = await walletProvider.withdraw(
        authProvider.userId!,
        amount,
        description: 'Rút tiền từ ví',
      );
    }

    if (mounted) {
      if (result['success'] == true) {
        _amountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String),
            backgroundColor: Colors.green,
          ),
        );
        // Cập nhật balance trong AuthProvider
        await authProvider.refreshWalletBalance();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Lỗi khi thực hiện giao dịch'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'deposit':
        return 'Nạp tiền';
      case 'withdraw':
        return 'Rút tiền';
      case 'payment':
        return 'Thanh toán';
      case 'refund':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'deposit':
        return Icons.add_circle;
      case 'withdraw':
        return Icons.remove_circle;
      case 'payment':
        return Icons.payment;
      case 'refund':
        return Icons.undo;
      default:
        return Icons.info;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'deposit':
      case 'refund':
        return Colors.green;
      case 'withdraw':
      case 'payment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ví của tôi'),
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Vui lòng đăng nhập để sử dụng ví',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x4D6C63FF),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Số dư ví',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(walletProvider.balance)}₫',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Transaction Type Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, size: 18),
                          SizedBox(width: 4),
                          Text('Nạp tiền'),
                        ],
                      ),
                      selected: _selectedType == 'deposit',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = 'deposit');
                      },
                      selectedColor: Colors.green,
                      labelStyle: TextStyle(
                        color: _selectedType == 'deposit' ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle, size: 18),
                          SizedBox(width: 4),
                          Text('Rút tiền'),
                        ],
                      ),
                      selected: _selectedType == 'withdraw',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = 'withdraw');
                      },
                      selectedColor: Colors.red,
                      labelStyle: TextStyle(
                        color: _selectedType == 'withdraw' ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Amount Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Số tiền (VNĐ)',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Nhập số tiền',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: walletProvider.isLoading ? null : _handleTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == 'deposit' ? Colors.green : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: walletProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _selectedType == 'deposit' ? 'Nạp tiền' : 'Rút tiền',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction History
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  const Text(
                    'Lịch sử giao dịch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            walletProvider.isLoading && walletProvider.transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : walletProvider.transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Chưa có giao dịch nào',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: walletProvider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = walletProvider.transactions[index];
                          final type = transaction['transaction_type'] as String;
                          final amount = transaction['amount'] as double;
                          final balanceAfter = transaction['balance_after'] as double;
                          final description = transaction['description'] as String?;
                          final createdAt = transaction['created_at'];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTransactionColor(type).withAlpha(26),
                                child: Icon(
                                  _getTransactionIcon(type),
                                  color: _getTransactionColor(type),
                                ),
                              ),
                              title: Text(
                                _getTransactionTypeLabel(type),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (description != null) Text(description),
                                  Text(
                                    createdAt != null
                                        ? DateTime.parse(createdAt.toString())
                                            .toString()
                                            .substring(0, 16)
                                        : '',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_selectedType == 'deposit' ? '+' : '-'}${_formatCurrency(amount)}₫',
                                    style: TextStyle(
                                      color: _getTransactionColor(type),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Số dư: ${_formatCurrency(balanceAfter)}₫',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}

