import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/chat_controller.dart';
import 'package:talkzy_beta1/controllers/friend_requests_controller.dart';
import 'package:talkzy_beta1/controllers/friends_controller.dart';
import 'package:talkzy_beta1/controllers/home_controller.dart';
import 'package:talkzy_beta1/controllers/main_controller.dart';
import 'package:talkzy_beta1/controllers/notification_controller.dart';
import 'package:talkzy_beta1/controllers/privacy_controller.dart';
import 'package:talkzy_beta1/controllers/profile_controller.dart';
import 'package:talkzy_beta1/controllers/user_list_controller.dart';
import 'package:talkzy_beta1/routes/app_routes.dart';
import 'package:talkzy_beta1/views/auth/login_view.dart';
import 'package:talkzy_beta1/views/auth/register_view.dart';
import 'package:talkzy_beta1/views/auth/forget_password_view.dart';
import 'package:talkzy_beta1/views/chat_view.dart';
import 'package:talkzy_beta1/views/find_people_view.dart';
import 'package:talkzy_beta1/views/friend_requests_view.dart';
import 'package:talkzy_beta1/views/friends_view.dart';
import 'package:talkzy_beta1/views/home_view.dart';
import 'package:talkzy_beta1/views/main_view.dart';
import 'package:talkzy_beta1/views/notification_view.dart';
import 'package:talkzy_beta1/views/profile/change_password_view.dart';
import 'package:talkzy_beta1/views/profile/new_profile_view.dart';
import 'package:talkzy_beta1/views/profile/personal_information_view.dart';
import 'package:talkzy_beta1/views/profile/account_settings_view.dart';
import 'package:talkzy_beta1/views/profile/chat_settings_view.dart';
import 'package:talkzy_beta1/views/profile/help_center_view.dart';
import 'package:talkzy_beta1/views/profile/privacy_settings_view.dart';
import 'package:talkzy_beta1/views/splash_view.dart';
import 'package:talkzy_beta1/views/welcome_view.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.welcome, page: () => const WelcomeView()),
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgetPasswordView()),
    GetPage(name: AppRoutes.changePassword, page: () => const ChangePasswordView()),
    GetPage(name: AppRoutes.privacySettings, page: () => const PrivacySettingsView(), binding: BindingsBuilder(() { Get.lazyPut(() => PrivacyController()); })),
    GetPage(name: AppRoutes.main, page: () => MainView(), binding: BindingsBuilder(() { Get.put(MainController()); })),
    GetPage(name: AppRoutes.home, page: () => HomeView(), binding: BindingsBuilder(() { Get.put(HomeController()); })),
    GetPage(name: AppRoutes.profile, page: () => const NewProfileView(), binding: BindingsBuilder(() { Get.put(ProfileController()); })),
    GetPage(name: AppRoutes.chat, page: () => const ChatView(), binding: BindingsBuilder(() { Get.put(ChatController()); })),
    GetPage(name: AppRoutes.usersList, page: () => FindPeopleView(), binding: BindingsBuilder(() { Get.put(UserListController()); })),
    GetPage(name: AppRoutes.friends, page: () => FriendsView(), binding: BindingsBuilder(() { Get.put(FriendsController()); })),
    GetPage(name: AppRoutes.friendRequests, page: () => FriendRequestsView(), binding: BindingsBuilder(() { Get.put(FriendRequestsController()); })),
    GetPage(name: AppRoutes.notifications, page: () => NotificationView(), binding: BindingsBuilder(() { Get.put(NotificationController()); })),
    GetPage(name: AppRoutes.personalInformation, page: () => const PersonalInformationView(), binding: BindingsBuilder(() { Get.lazyPut(() => ProfileController()); })),
    GetPage(name: AppRoutes.accountSettings, page: () => const AccountSettingsView()),
    GetPage(name: AppRoutes.chatSettings, page: () => const ChatSettingsView()),
    GetPage(name: AppRoutes.helpCenter, page: () => const HelpCenterView()),
  ];
}
