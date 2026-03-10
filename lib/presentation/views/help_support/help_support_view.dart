import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/help_support_controller.dart';

class HelpSupportView extends GetView<HelpSupportController> {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HelpSupportController>()) {
      Get.put(HelpSupportController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('FAQ'),
                    const SizedBox(height: 12),
                    _buildFAQSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Support'),
                    const SizedBox(height: 12),
                    _buildContactSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: const Color(0xFFF5F7FA).withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: BackButton(color: AppColors.ink),
        ),
      ),
      toolbarHeight: 90,
      title: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'help_title'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'help_subtitle'.tr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.mutedText,
      ),
    );
  }

  Widget _buildFAQSection() {
    final sections = <_FAQSection>[
      _FAQSection(
        title: 'GETTING STARTED',
        items: [
          _FAQItem(
            question: 'What is FinEye?',
            answer:
                'FinEye is a VAT organization and tracking tool designed to help UAE businesses manage invoices and monitor VAT amounts.',
          ),
          _FAQItem(
            question: 'How do I get started with FinEye?',
            answer:
                'Complete your company setup, then upload your first invoice and classify it correctly as Sales or Purchase.',
          ),
          _FAQItem(
            question:
                'Is FinEye officially connected to the Federal Tax Authority (FTA)?',
            answer:
                'No. FinEye is an independent VAT management tool and is not officially connected to the FTA.',
          ),
          _FAQItem(
            question: 'Does FinEye submit tax returns?',
            answer:
                'No. VAT returns must be submitted through the official FTA portal.',
          ),
        ],
      ),
      _FAQSection(
        title: 'INVOICES',
        items: [
          _FAQItem(
            question: 'How do I upload an invoice?',
            answer:
                'Tap "Upload Invoice," review the extracted data, classify the invoice, then confirm and save.',
          ),
          _FAQItem(
            question: 'Can I edit an invoice after uploading?',
            answer:
                'Yes. You can edit or delete invoices at any time from the invoice list.',
          ),
          _FAQItem(
            question: 'What is the difference between Sales and Purchase?',
            answer:
                'Sales are invoices you issue to customers. Purchase invoices are bills you receive from suppliers.',
          ),
          _FAQItem(
            question: 'When should I select Sales - Output VAT?',
            answer: 'Select this when you are charging VAT to your customer.',
          ),
          _FAQItem(
            question: 'When should I select Purchase - Input VAT?',
            answer: 'Select this when you have paid VAT to a supplier.',
          ),
          _FAQItem(
            question: 'What does VAT Inclusive mean?',
            answer:
                'The entered amount already includes VAT. The system extracts the VAT portion automatically.',
          ),
          _FAQItem(
            question: 'What does VAT Exclusive mean?',
            answer:
                'The entered amount does not include VAT. The system adds 5% VAT automatically.',
          ),
          _FAQItem(
            question: 'What is Net Amount?',
            answer: 'Net Amount is the base value before VAT is applied.',
          ),
          _FAQItem(
            question: 'What is the difference between VAT and Final Total?',
            answer:
                'VAT is the tax amount only. Final Total is the full amount including VAT.',
          ),
          _FAQItem(
            question: 'What happens if I upload a duplicate invoice?',
            answer:
                'The system detects duplicate invoice numbers and prevents saving to protect VAT accuracy.',
          ),
          _FAQItem(
            question: 'What does CT Deductible mean?',
            answer:
                'It indicates whether the expense may be deductible for Corporate Tax purposes. It does not affect VAT calculation.',
          ),
        ],
      ),
      _FAQSection(
        title: 'VAT & DASHBOARD',
        items: [
          _FAQItem(
            question: 'How is Net VAT calculated?',
            answer: 'Net VAT = Output VAT - Input VAT.',
          ),
          _FAQItem(
            question: 'What does "Payable" mean?',
            answer: 'It means you owe VAT to the tax authority.',
          ),
          _FAQItem(
            question: 'What does "Credit" mean?',
            answer:
                'It means you have paid more VAT than collected and may carry forward or request a refund.',
          ),
          _FAQItem(
            question: 'Are VAT amounts final?',
            answer:
                'VAT amounts are calculated automatically based on recorded invoices. You should review them before submitting your official VAT return.',
          ),
          _FAQItem(
            question: 'How are VAT deadlines calculated?',
            answer:
                'Deadlines are based on your selected VAT filing frequency (monthly or quarterly).',
          ),
        ],
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            _buildFAQGroupHeader(sections[i].title),
            for (int j = 0; j < sections[i].items.length; j++)
              _buildFAQItem(
                sections[i].items[j].question,
                sections[i].items[j].answer,
                showDivider:
                    !(i == sections.length - 1 &&
                        j == sections[i].items.length - 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFAQGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFAQItem(
    String question,
    String answer, {
    bool showDivider = false,
  }) {
    return Column(
      children: [
        ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment:
              Get.locale?.languageCode == 'ar'
                  ? Alignment.topRight
                  : Alignment.topLeft,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primaryBlue,
          collapsedIconColor: Colors.grey,
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(
                Icons.email_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            title: Text(
              'email_support'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            subtitle: Text(
              'email_desc'.tr,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: const Text(
              'support@fineye.ai',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: controller.sendEmail,
          ),
          const Divider(height: 1, indent: 70, endIndent: 0),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(
                Icons.bug_report_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            title: Text(
              'report_bug'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            subtitle: Text(
              'report_bug_desc'.tr,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Text(
              'send'.tr,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: controller.reportBug,
          ),
        ],
      ),
    );
  }
}

class _FAQSection {
  final String title;
  final List<_FAQItem> items;

  _FAQSection({required this.title, required this.items});
}

class _FAQItem {
  final String question;
  final String answer;

  _FAQItem({required this.question, required this.answer});
}
