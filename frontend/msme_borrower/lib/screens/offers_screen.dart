import 'package:flutter/material.dart';
import '../core/constants.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exclusive Offers'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildOfferCard(
              context,
              title: 'Pre-Approved Top-Up Loan',
              description: 'Get an additional 20% on your next working capital limit with zero extra documentation.',
              tag: 'Exclusive',
              color: kAccent,
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 16),
            _buildOfferCard(
              context,
              title: 'LendingKart Business Credit Card',
              description: '5% cashback on all raw material purchases. Apply instantly!',
              tag: 'Coming Soon',
              color: Colors.orange,
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 16),
            _buildOfferCard(
              context,
              title: 'Machinery Finance Promo',
              description: 'Interest rates starting from 1.25% p.m. for heavy machinery upgrades.',
              tag: 'Limited Time',
              color: kPrimary,
              icon: Icons.precision_manufacturing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, {
    required String title,
    required String description,
    required String tag,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Icon(icon, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: kHeading1(context).copyWith(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Details'),
            ),
          )
        ],
      ),
    );
  }
}
