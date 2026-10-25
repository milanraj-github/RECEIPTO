import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/warranty/data/services/brand_support_directory.dart';
import 'package:receipto/features/warranty/data/services/warranty_claim_dispatcher_service.dart';

class WarrantyClaimModal extends ConsumerStatefulWidget {
  final WarrantyModel warranty;

  const WarrantyClaimModal({
    super.key,
    required this.warranty,
  });

  static Future<void> show(BuildContext context, WarrantyModel warranty) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WarrantyClaimModal(warranty: warranty),
    );
  }

  @override
  ConsumerState<WarrantyClaimModal> createState() => _WarrantyClaimModalState();
}

class _WarrantyClaimModalState extends ConsumerState<WarrantyClaimModal> {
  late BrandSupportInfo _supportInfo;
  late final TextEditingController _issueController;
  late final TextEditingController _emailController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isLetterExpanded = false;
  String _selectedIssueChip = 'Device Not Powering On';

  final List<String> _quickIssues = [
    'Device Not Powering On',
    'Display / Screen Failure',
    'Physical Hardware Defect',
    'Battery / Charging Issue',
    'Excessive Overheating',
    'Audio / Sound Distortion',
    'Motor / Mechanical Failure',
    'Water / Liquid Leakage',
    'Performance & Freezing',
  ];

  @override
  void initState() {
    super.initState();
    _supportInfo = BrandSupportDirectory.resolveBrandSupport(
      brand: widget.warranty.brand,
      productName: widget.warranty.productName,
      merchantName: widget.warranty.merchantName,
    );

    final user = ref.read(firebaseAuthServiceProvider).currentUser;

    _issueController = TextEditingController(
      text: 'The device stopped working during normal usage. It fails to power on and is unresponsive despite standard troubleshooting.',
    );
    _emailController = TextEditingController(text: _supportInfo.supportEmail ?? '');
    _modelController = TextEditingController(text: widget.warranty.model ?? '');
    _serialController = TextEditingController(text: widget.warranty.serialNumber ?? '');
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _issueController.dispose();
    _emailController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onIssueChipSelected(String issue) {
    setState(() {
      _selectedIssueChip = issue;
      switch (issue) {
        case 'Device Not Powering On':
          _issueController.text =
              'The device stopped powering on during normal indoor usage. There is no indicator light and it remains completely unresponsive.';
          break;
        case 'Display / Screen Failure':
          _issueController.text =
              'The display screen has malfunctioned, showing horizontal/vertical lines and flickering without any physical damage or drops.';
          break;
        case 'Physical Hardware Defect':
          _issueController.text =
              'A structural hardware component has failed under standard manufacturer operating conditions.';
          break;
        case 'Battery / Charging Issue':
          _issueController.text =
              'The product fails to retain battery charge and frequently shuts down prematurely or refuses to charge with original accessories.';
          break;
        case 'Excessive Overheating':
          _issueController.text =
              'The unit experiences abnormal thermal buildup during minimal usage, leading to automatic protective shutdowns.';
          break;
        case 'Audio / Sound Distortion':
          _issueController.text =
              'The integrated speakers/audio outputs suffer from severe cracking, static, and intermittent sound cutoff.';
          break;
        case 'Motor / Mechanical Failure':
          _issueController.text =
              'The internal motor / drive mechanism has seized or generates loud grinding friction noise during cycle operation.';
          break;
        case 'Water / Liquid Leakage':
          _issueController.text =
              'Uncontrolled water/liquid leakage is originating from internal pipe joints under normal operating pressure.';
          break;
        case 'Performance & Freezing':
          _issueController.text =
              'The firmware repeatedly freezes and hangs during routine operation, rendering the appliance unusable.';
          break;
      }
    });
  }

  String _getGeneratedClaimText() {
    final dispatcher = ref.read(warrantyClaimDispatcherServiceProvider);
    return dispatcher.generateClaimLetter(
      warranty: widget.warranty,
      supportInfo: _supportInfo,
      issueDescription: _issueController.text.trim(),
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: ref.read(firebaseAuthServiceProvider).currentUser?.email,
      customModel: _modelController.text.trim(),
      customSerial: _serialController.text.trim(),
    );
  }

  Future<void> _handleSendEmail() async {
    final dispatcher = ref.read(warrantyClaimDispatcherServiceProvider);
    final targetEmail = _emailController.text.trim();

    if (targetEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an official support email address.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final subject = '[WARRANTY CLAIM] Formal Service Request - ${widget.warranty.productName} (Inv: ${widget.warranty.invoiceNumber ?? "Verified"})';
    final claimLetter = _getGeneratedClaimText();

    final launched = await dispatcher.launchEmailClient(
      recipientEmail: targetEmail,
      subject: subject,
      body: claimLetter,
    );

    if (!launched) {
      // If default mailto app is missing, fallback to copying text & notification
      await dispatcher.copyToClipboard(claimLetter);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email app. Claim letter copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleCallSupport() async {
    final phone = _supportInfo.tollFreePhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toll-free customer care number not available for this brand.')),
      );
      return;
    }
    final dispatcher = ref.read(warrantyClaimDispatcherServiceProvider);
    final launched = await dispatcher.launchPhoneDialer(phone);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone dialer.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleLocateServiceCenter() async {
    final dispatcher = ref.read(warrantyClaimDispatcherServiceProvider);
    final launched = await dispatcher.launchServiceCenterMaps(_supportInfo.serviceCenterQuery);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open maps application.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleSharePacket() async {
    final dispatcher = ref.read(warrantyClaimDispatcherServiceProvider);
    final claimLetter = _getGeneratedClaimText();
    await dispatcher.shareClaimPacket(
      claimText: claimLetter,
      subject: 'Warranty Claim Packet: ${widget.warranty.productName}',
      imagePath: widget.warranty.imageUrl,
    );
  }

  Future<void> _handleCopyLetter() async {
    final dispatcher = ref.read(warrantyClaimDispatcherServiceProvider);
    await dispatcher.copyToClipboard(_getGeneratedClaimText());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formal warranty claim letter copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimLetter = _getGeneratedClaimText();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Warranty Claim Dispatcher',
                                style: GoogleFonts.hankenGrotesk(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '1-Click preparation & legal service dispatch',
                                style: GoogleFonts.inter(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. PRODUCT & BRAND SUMMARY CARD
                    _buildProductSummaryBanner(),
                    const SizedBox(height: 16),

                    // 2. OFFICIAL SUPPORT CONTACTS
                    _buildBrandSupportDirectoryCard(),
                    const SizedBox(height: 20),

                    // 3. DEFECT & ISSUE SELECTION
                    Text(
                      'SELECT DEFECT OR SYMPTOM',
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildQuickIssueChips(),
                    const SizedBox(height: 12),

                    // Description text input
                    TextField(
                      controller: _issueController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        hintText: 'Describe the issue or defect in detail...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // 4. OPTIONAL PRODUCT CREDENTIALS (MODEL / SERIAL)
                    _buildOptionalCredentialsFields(),
                    const SizedBox(height: 20),

                    // 5. LEGAL PROTECTION BADGE & PREVIEW
                    _buildLegalCitationBanner(),
                    const SizedBox(height: 14),

                    // 6. GENERATED CLAIM LETTER (COLLAPSIBLE)
                    _buildLetterPreviewCard(claimLetter),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action Footer
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.warranty.productName,
                  style: GoogleFonts.hankenGrotesk(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _supportInfo.brandName,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.white38)),
                    Text(
                      'Purchased: ${widget.warranty.purchaseDate}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Under Warranty',
              style: TextStyle(color: Colors.greenAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSupportDirectoryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_supportInfo.brandName} Customer Support',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_supportInfo.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Verified Channel', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Email field
          Row(
            children: [
              const Icon(Icons.email_outlined, color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    hintText: 'Brand support email (e.g. support@brand.com)',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action Pills (Call Care & Maps)
          Row(
            children: [
              if (_supportInfo.tollFreePhone != null) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: _handleCallSupport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_in_talk_outlined, color: Colors.greenAccent, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _supportInfo.tollFreePhone!,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: _handleLocateServiceCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me_outlined, color: AppColors.secondary, size: 15),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Find Centers',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickIssueChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickIssues.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final issue = _quickIssues[index];
          final isSelected = _selectedIssueChip == issue;
          return ChoiceChip(
            label: Text(
              issue,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.cardSurface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (_) => _onIssueChipSelected(issue),
          );
        },
      ),
    );
  }

  Widget _buildOptionalCredentialsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPECIFICATIONS (OPTIONAL ENHANCEMENT)',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _modelController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Model Number',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _serialController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Serial Number',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegalCitationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, color: Colors.indigoAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consumer Protection Act, 2019 Citation Included',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Claim invokes statutory protections under Section 2(47) & Chapter VI for manufacturing defect redressal.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterPreviewCard(String claimLetter) {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Formal Claim Letter Preview',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _isLetterExpanded = !_isLetterExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        _isLetterExpanded ? 'Collapse' : 'Expand Full',
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Icon(
                        _isLetterExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              _isLetterExpanded ? claimLetter : '${claimLetter.split('\n').take(6).join('\n')}\n...',
              style: GoogleFonts.firaCode(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                label: const Text('Copy Claim Text', style: TextStyle(color: AppColors.primary, fontSize: 11.5)),
                onPressed: _handleCopyLetter,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.share_outlined, size: 14, color: AppColors.secondary),
                label: const Text('Share Packet', style: TextStyle(color: AppColors.secondary, fontSize: 11.5)),
                onPressed: _handleSharePacket,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                'Dispatch Claim Email',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleSendEmail,
            ),
          ),
        ],
      ),
    );
  }
}
