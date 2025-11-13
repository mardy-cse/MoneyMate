import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/points_service.dart';
import '../models/gamification.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PointsService _pointsService = PointsService();
  UserPoints? _userPoints;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() => _isLoading = true);
    final totalPoints = await _pointsService.getTotalPoints();
    final hasSignup = await _pointsService.hasCompletedSignup();
    setState(() {
      _userPoints = UserPoints(
        totalPoints: totalPoints,
        isPremium: hasSignup,
        premiumExpiryDate: null,
      );
      _isLoading = false;
    });
  }

  Future<void> _unlockPremium() async {
    final hasSignup = await _pointsService.hasCompletedSignup();

    if (hasSignup) {
      Get.snackbar(
        'Already Premium',
        'You already have premium access!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return;
    }

    // Show info dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Premium'),
        content: const Text(
          'Complete signup to unlock premium features!\n\nSign up to get:\n• 50 bonus points\n• Debt/Loan Tracker\n• Cloud Backup & Sync',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed('/auth');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Sign Up Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium & Points'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPoints,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Points Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_userPoints!.totalPoints}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Total Points',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_userPoints!.dailyStreak} Days Streak',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Premium Status Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _userPoints!.isActivePremium
                                      ? Icons.check_circle
                                      : Icons.lock,
                                  color: _userPoints!.isActivePremium
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userPoints!.isActivePremium
                                            ? 'Premium Active'
                                            : 'Premium Locked',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_userPoints!.isActivePremium)
                                        Text(
                                          'Premium Active',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!_userPoints!.isActivePremium) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Unlock with ${PointsConfig.premiumUnlockCost} points',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value:
                                    _userPoints!.totalPoints /
                                    PointsConfig.premiumUnlockCost,
                                backgroundColor: Colors.grey[300],
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_userPoints!.totalPoints}/${PointsConfig.premiumUnlockCost} points',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    _userPoints!.totalPoints >=
                                        PointsConfig.premiumUnlockCost
                                    ? _unlockPremium
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                child: const Text('Unlock Premium (30 Days)'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Premium Features
                    const Text(
                      'Premium Features (Unlock with 250 points)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.account_balance,
                      title: 'Debt/Loan Tracker',
                      description:
                          'Track money lent and borrowed with payment history',
                      isUnlocked: _userPoints!.isActivePremium,
                      isPremium: true,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.cloud_sync,
                      title: 'Cloud Backup & Sync',
                      description:
                          'Auto backup and sync across all your devices',
                      isUnlocked: _userPoints!.isActivePremium,
                      isPremium: true,
                    ),
                    const SizedBox(height: 24),

                    // How to Earn Points
                    const Text(
                      'How to Earn Points',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEarnPointsItem(
                              icon: Icons.account_circle,
                              title: 'Sign Up (One-time)',
                              points: PointsConfig.signupBonusPoints,
                            ),
                            const Divider(),
                            _buildEarnPointsItem(
                              icon: Icons.login,
                              title: 'Daily App Use',
                              points: PointsConfig.dailyLoginPoints,
                            ),
                            const Divider(),
                            const Text(
                              '💡 Tip: Sign up today and use daily for 20 days to unlock premium features!',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isUnlocked,
    bool isPremium = true,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 32,
          color: isUnlocked
              ? Colors.green
              : (isPremium ? Colors.grey : Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Icon(
          isUnlocked
              ? Icons.check_circle
              : (isPremium ? Icons.lock : Icons.check_circle),
          color: isUnlocked
              ? Colors.green
              : (isPremium ? Colors.grey : Colors.blue),
        ),
      ),
    );
  }

  Widget _buildEarnPointsItem({
    required IconData icon,
    required String title,
    required int points,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+$points',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
