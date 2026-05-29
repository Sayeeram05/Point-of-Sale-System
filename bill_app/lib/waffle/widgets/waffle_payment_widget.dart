import 'package:flutter/material.dart';
import '../providers/waffle_order_provider.dart';
import '../themes/waffle_theme.dart';

class WafflePaymentWidget extends StatelessWidget {
  final WaffleOrderProvider provider;

  const WafflePaymentWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: WaffleTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMethodButton(context, 'Cash', WafflePaymentMode.cash),
                _buildMethodButton(context, 'UPI', WafflePaymentMode.upi),
                _buildMethodButton(context, 'Both', WafflePaymentMode.both),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.paymentMode != WafflePaymentMode.upi)
              _buildAmountField(
                context,
                label: 'Cash Amount',
                value: provider.cashAmount.toStringAsFixed(2),
                onChanged: provider.updateCashAmount,
              ),
            if (provider.paymentMode != WafflePaymentMode.cash) ...[
              const SizedBox(height: 12),
              _buildAmountField(
                context,
                label: 'UPI Amount',
                value: provider.upiAmount.toStringAsFixed(2),
                onChanged: provider.updateUpiAmount,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              provider.isPaymentValid
                  ? 'Payment ready for ₹${provider.totalPrice.toStringAsFixed(2)}'
                  : 'Enter a valid payment amount to match total',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: provider.isPaymentValid
                    ? Colors.green
                    : WaffleTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton(
    BuildContext context,
    String title,
    WafflePaymentMode mode,
  ) {
    final selected = provider.paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setPaymentMode(mode),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? WaffleTheme.primaryColor : WaffleTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? WaffleTheme.primaryColor
                  : WaffleTheme.borderColor,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selected ? Colors.white : WaffleTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: onChanged,
    );
  }
}
