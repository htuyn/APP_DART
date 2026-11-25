import 'package:flutter/material.dart';

import '../../data/models/achievement_certificate_model.dart';

class DigitalCertificateCard extends StatelessWidget {
  const DigitalCertificateCard({
    super.key,
    required this.certificate,
    required this.title,
    required this.statusLabel,
    required this.labels,
    required this.onCopy,
    this.studentName,
    this.studentEmail,
  });

  final AchievementCertificateModel certificate;
  final String title;
  final String statusLabel;
  final Map<String, String> labels;
  final ValueChanged<String> onCopy;
  final String? studentName;
  final String? studentEmail;

  static const _gold = Color(0xFFF59E0B);
  static const _paleGold = Color(0xFFFDE68A);
  static const _darkGold = Color(0xFFD97706);
  static const _ink = Color(0xFF0F172A);
  static const _slate = Color(0xFF1E293B);
  static const _mint = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final confirmed = certificate.status == CertificateStatus.confirmed;
    final revoked = certificate.status == CertificateStatus.revoked;
    final statusColor = confirmed
        ? _mint
        : revoked
            ? const Color(0xFFF87171)
            : _amber;
    final wallet = certificate.recipientAddress;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gold, _paleGold, _darkGold],
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: .20),
                blurRadius: 28,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _paleGold.withValues(alpha: .48), width: 1),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_ink, _slate],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _DiplomaGridPainter())),
                Positioned(
                  top: -95,
                  right: -75,
                  child: IgnorePointer(
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [_gold.withValues(alpha: .16), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school_rounded, color: _paleGold, size: 27),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                labels['academy']!,
                                style: const TextStyle(
                                  color: _paleGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: .13),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: statusColor.withValues(alpha: .58)),
                                ),
                                child: Text(
                                  statusLabel,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 27),
                      Text(
                        labels['diploma_heading']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _paleGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Icon(Icons.workspace_premium_rounded, size: 54, color: _gold),
                      const SizedBox(height: 10),
                      Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 23),
                      if ((studentName != null && studentName!.isNotEmpty) ||
                          (studentEmail != null && studentEmail!.isNotEmpty)) ...[
                        _StudentPanel(
                          label: labels['certified_student'] ?? 'HỌC VIÊN ĐẠT THÀNH TÍCH',
                          name: studentName,
                          email: studentEmail,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _WalletPanel(
                        label: labels['recipient']!,
                        address: wallet,
                        copyLabel: labels['copy_wallet']!,
                        onCopy: () => onCopy(wallet),
                      ),
                      const SizedBox(height: 17),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: .08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProofRow(label: labels['certificate_id']!, value: certificate.certificateId),
                            const SizedBox(height: 11),
                            _ProofRow(label: labels['achievement_hash']!, value: certificate.achievementHash),
                            const SizedBox(height: 11),
                            _ProofRow(
                              label: labels['transaction_hash']!,
                              value: certificate.transactionHash ?? labels['not_available']!,
                              copyLabel: labels['copy_transaction']!,
                              onCopy: certificate.transactionHash == null
                                  ? null
                                  : () => onCopy(certificate.transactionHash!),
                            ),
                            const SizedBox(height: 11),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _ProofRow(
                                  label: labels['block_number']!,
                                  value: certificate.blockNumber == null
                                      ? labels['not_available']!
                                      : '#${certificate.blockNumber}',
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _ProofRow(
                                  label: labels['issued_at']!,
                                  value: certificate.issuedAt?.toLocal().toString().split('.').first ??
                                      labels['not_available']!,
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(color: _paleGold.withValues(alpha: .55)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, size: 16, color: _paleGold),
                              const SizedBox(width: 5),
                              Text(
                                labels['sepolia_seal']!,
                                style: const TextStyle(
                                  color: _paleGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletPanel extends StatelessWidget {
  const _WalletPanel({
    required this.label,
    required this.address,
    required this.copyLabel,
    required this.onCopy,
  });

  final String label;
  final String address;
  final String copyLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final shortAddress = address.length > 18
        ? '${address.substring(0, 10)}…${address.substring(address.length - 8)}'
        : address;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 5, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 4),
                SelectableText(
                  shortAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: copyLabel,
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.copy_rounded, color: DigitalCertificateCard._paleGold, size: 19),
          ),
        ],
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({
    required this.label,
    required this.value,
    this.copyLabel,
    this.onCopy,
  });

  final String label;
  final String value;
  final String? copyLabel;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  tooltip: copyLabel,
                  onPressed: onCopy,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.copy_rounded, color: DigitalCertificateCard._paleGold, size: 15),
                ),
            ],
          ),
          SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.35,
              fontFamily: 'monospace',
            ),
          ),
        ],
      );
}

class _StudentPanel extends StatelessWidget {
  const _StudentPanel({
    required this.label,
    this.name,
    this.email,
  });

  final String label;
  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final displayName = (name != null && name!.isNotEmpty) ? name! : (email ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DigitalCertificateCard._paleGold.withValues(alpha: .30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: DigitalCertificateCard._paleGold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: DigitalCertificateCard._paleGold,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (email != null && email!.isNotEmpty && email != displayName) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: DigitalCertificateCard._mint.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DigitalCertificateCard._mint.withValues(alpha: .40)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: DigitalCertificateCard._mint, size: 12),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: DigitalCertificateCard._mint,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiplomaGridPainter extends CustomPainter {
  const _DiplomaGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: .025)
      ..strokeWidth = .5;
    const step = 22.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
