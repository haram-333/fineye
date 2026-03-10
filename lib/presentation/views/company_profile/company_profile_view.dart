import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';
import '../../controllers/company_profile_controller.dart';
import '../../../core/constants/app_colors.dart';

class CompanyProfileView extends GetView<CompanyProfileController> {
  const CompanyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
     if (!Get.isRegistered<CompanyProfileController>()) {
      Get.put(CompanyProfileController());
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  children: [
                    _buildCompanyInfoSection(),
                    const SizedBox(height: 24),
                    _buildTaxRegistrationSection(),
                    const SizedBox(height: 24),
                    _buildTaxSetupSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
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
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
              'company_profile_title'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
             const SizedBox(height: 4),
             Text(
              'company_profile_subtitle'.tr,
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
      actions: const [], // explicitly empty to avoid any defaults
    );
  }

  Widget _buildSectionContainer({required String title, required Widget child, Widget? headerTrailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (headerTrailing != null) 
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: headerTrailing,
                ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildCompanyInfoSection() {
    return _buildSectionContainer(
      title: 'company_info_section'.tr,
      headerTrailing: _buildCompletenessBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('legal_entity'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text('legal_entity_desc'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          _buildTextField('${'company_name_label'.tr} *', controller.companyNameController),
          const SizedBox(height: 16),
          _buildTextField('${'company_email_label'.tr} *', controller.emailController, keyboardType: TextInputType.emailAddress, textDirection: ui.TextDirection.ltr),
          const SizedBox(height: 16),
          // Phone Number with Country Code
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'phone_label'.tr} *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
              const SizedBox(height: 8),
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Row(
                  children: [
                    // Country Code Field
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: controller.countryCodeController,
                        keyboardType: TextInputType.phone,
                        textDirection: ui.TextDirection.ltr,
                        style: const TextStyle(fontSize: 15, color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: '+971',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFFaFaFa),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Phone Number Field
                    Expanded(
                      child: TextField(
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: ui.TextDirection.ltr,
                        style: const TextStyle(fontSize: 15, color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'phone_hint_uae'.tr,
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFFaFaFa),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Obx(() => Text(
        'profile_completeness'.trParams({'percent': (controller.completeness.value * 100).toInt().toString()}),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF006064),
        ),
      )),
    );
  }

  Widget _buildTaxRegistrationSection() {
    return _buildSectionContainer(
      title: 'tax_registration_section'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // VAT Registration Toggle
          Text('${'vat_registered_label'.tr} *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildToggleOption(
                  'vat_registered_yes'.tr,
                  controller.isVatRegistered.value == true,
                  () => controller.isVatRegistered.value = true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleOption(
                  'vat_registered_no'.tr,
                  controller.isVatRegistered.value == false,
                  () => controller.isVatRegistered.value = false,
                ),
              ),
            ],
          )),
          
          // TRN Field (only visible if VAT registered)
          Obx(() => controller.isVatRegistered.value
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text('${'trn_label'.tr} *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildTextField('', controller.trnController, hint: 'trn_hint'.tr),
                ],
              )
            : const SizedBox.shrink()),
          
          const SizedBox(height: 16),
          
          // Warning Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Amber 50
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFC107)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA000), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'trn_warning'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'trn_warning_desc'.tr,
                        style: const TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Verify Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
               onPressed: controller.verifyTrnOnFta,
               style: OutlinedButton.styleFrom(
                 side: const BorderSide(color: AppColors.primaryBlue),
                 padding: const EdgeInsets.symmetric(vertical: 14),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: Text(
                 'verify_trn_btn'.tr,
                 style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
               ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTaxSetupSection() {
    return _buildSectionContainer(
      title: 'tax_setup_section'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Use a helper that maps keys to display values
           _buildDropdownWithKeys(
             '${'tax_period_label'.tr} *',
             controller.taxPeriod,
             {
               'monthly': 'tax_period_monthly'.tr,
               'quarterly': 'tax_period_quarterly'.tr,
             },
           ),
           const SizedBox(height: 16),
           
           // Financial Year Start - Full Width
           _buildDatePicker('${'financial_year_start_label'.tr} *', controller.financialYearStart),
           const SizedBox(height: 16),
           
           // Financial Year End - Full Width
           _buildDatePicker('${'financial_year_end_label'.tr} *', controller.financialYearEnd),
           const SizedBox(height: 16),
           
           _buildDropdownWithKeys(
             'nature_of_business'.tr,
             controller.natureOfBusiness,
             {
               'retail': 'biz_nature_retail'.tr,
               'services': 'biz_nature_services'.tr,
               'technology': 'biz_nature_technology'.tr,
               'real_estate': 'biz_nature_real_estate'.tr,
               'other': 'biz_nature_other'.tr,
             },
             hint: 'nature_of_business_hint'.tr,
           ),
           const SizedBox(height: 16),
           
           _buildDropdownWithKeys(
             'ct_regime'.tr,
             controller.corporateTaxRegime,
             {
               'standard_uae_9': 'ct_regime_standard'.tr,
               'freezone_0': 'ct_regime_freezone'.tr,
               'small_business': 'ct_regime_small_business'.tr,
             },
           ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'save_profile'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboardType, TextDirection? textDirection}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          textDirection: textDirection,
          style: const TextStyle(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFFaFaFa),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }



    Widget _buildDatePicker(String label, Rx<DateTime> date) {
    return GestureDetector(
      onTap: () => controller.selectDate(date),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFaFaFa),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                     FormatHelper.date(date.value),
                     style: const TextStyle(fontSize: 15, color: AppColors.ink),
                  ),
                )),
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : const Color(0xFFFaFaFa),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryBlue : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  // Dropdown that uses keys instead of translated values to prevent language toggle errors
  Widget _buildDropdownWithKeys(String label, RxString valueKey, Map<String, String> keyToDisplayMap, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink)),
        const SizedBox(height: 8),
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFaFaFa),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: valueKey.value.isEmpty ? null : valueKey.value,
              hint: hint != null ? Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)) : null,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: keyToDisplayMap.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key, // Store the key
                  child: Text(entry.value, style: const TextStyle(fontSize: 15, color: AppColors.ink)), // Display the translation
                );
              }).toList(),
              onChanged: (newKey) {
                if (newKey != null) valueKey.value = newKey;
              },
            ),
          ),
        )),
      ],
    );
  }
}
