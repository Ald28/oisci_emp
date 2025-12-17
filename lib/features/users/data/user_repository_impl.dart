import 'datasources/user_remote_datasource.dart';
import 'models/user_model.dart';

class UserRepositoryImpl {
  final UserRemoteDataSource remote;

  UserRepositoryImpl(this.remote);

  // 🔹 NO SE TOCA
  Future<UserModel> login(String email, String password) async {
    final result = await remote.login(email, password);
    final user = UserModel.fromJson(result);

    return user;
  }
}