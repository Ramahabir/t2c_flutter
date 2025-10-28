import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/redemption_request.dart';

class RedemptionScreen extends StatefulWidget {
  const RedemptionScreen({super.key});

  @override
  State<RedemptionScreen> createState() => _RedemptionScreenState();
}

class _RedemptionScreenState extends State<RedemptionScreen> {
  List<RedemptionOption> _options = [];
  bool _isLoading = true;
  RedemptionOption? _selectedOption;
  final _pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRedemptionOptions();
  }

  Future<void> _loadRedemptionOptions() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final options = await appState.loadRedemptionOptions();
    setState(() {
      _options = options;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Points'),
        backgroundColor: Colors.green[700],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(appState),
                const SizedBox(height: 16),
                _buildRedemptionOptions(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(AppStateProvider appState) {
    final points = appState.user?.points ?? 0;
    final cashValue = points * 0.01;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[600]!, Colors.purple[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${points.toStringAsFixed(0)} points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '≈ \$${cashValue.toStringAsFixed(2)} cash value',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Redemption Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_options.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No redemption options available'),
              ),
            )
          else
            ..._options.map((option) => _buildOptionCard(option)),
        ],
      ),
    );
  }

  Widget _buildOptionCard(RedemptionOption option) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userPoints = appState.user?.points ?? 0;
    final canRedeem = userPoints >= option.minimumPoints && option.isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canRedeem ? Colors.green.withOpacity(0.3) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: canRedeem ? () => _showRedemptionDialog(option) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canRedeem
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  option.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: canRedeem ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Min: ${option.minimumPoints.toStringAsFixed(0)} pts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                canRedeem ? Icons.arrow_forward_ios : Icons.lock,
                color: canRedeem ? Colors.green : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedemptionDialog(RedemptionOption option) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userPoints = appState.user?.points ?? 0;

    _pointsController.text = option.minimumPoints.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem via ${option.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${userPoints.toStringAsFixed(0)} points',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Points to redeem',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.star),
                suffixText: 'pts',
                helperText: 'Min: ${option.minimumPoints.toStringAsFixed(0)} pts',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cash value: \$${(double.tryParse(_pointsController.text) ?? 0) * 0.01}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRedemption(option);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRedemption(RedemptionOption option) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final points = double.tryParse(_pointsController.text) ?? 0;

    if (points < option.minimumPoints) {
      _showErrorDialog(
          'Insufficient Points',
          'Minimum ${option.minimumPoints.toStringAsFixed(0)} points required');
      return;
    }

    if (points > (appState.user?.points ?? 0)) {
      _showErrorDialog('Insufficient Balance',
          'You don\'t have enough points for this redemption');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing redemption...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final request = RedemptionRequest(
        userId: appState.user!.id,
        points: points,
        method: option.id,
      );

      await appState.redeemPoints(request);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      _showSuccessDialog(points, option);
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error dialog
      _showErrorDialog('Redemption Failed', e.toString());
    }
  }

  void _showSuccessDialog(double points, RedemptionOption option) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: 8),
            const Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your redemption of ${points.toStringAsFixed(0)} points via ${option.name} has been processed successfully.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your balance has been updated',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 32),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
