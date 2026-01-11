import 'package:get/get.dart';

import '../../data/models/app_info_model.dart';
import '../../data/repositories/app_info_repository.dart';

class AboutController extends GetxController {
  AboutController(this._repository);

  final AppInfoRepository _repository;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();
  final Rxn<AppInfoModel> appInfo = Rxn<AppInfoModel>();
  final Rxn<DeveloperInfoModel> developerInfo = Rxn<DeveloperInfoModel>();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      error.value = null;

      final results = await Future.wait([
        _repository.fetchAppInfo(),
        _repository.fetchDeveloperInfo(),
      ]);

      appInfo.value = results[0] as AppInfoModel;
      developerInfo.value = results[1] as DeveloperInfoModel;
    } catch (e) {
      error.value = 'Failed to load app information: $e';
    } finally {
      isLoading.value = false;
    }
  }
}

