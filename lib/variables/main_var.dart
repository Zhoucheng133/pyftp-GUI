import 'package:get/get.dart';

class MainVar extends GetxController {
  RxString python=''.obs;
  RxBool running=false.obs;
  RxString sharePath=''.obs;
  RxString sharePort=''.obs;
  RxBool enableWrite=false.obs;
  RxBool useAuth=false.obs;
  RxString username=''.obs;
  RxString password=''.obs;
}