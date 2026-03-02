import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkChecker {
  final InternetConnectionChecker _checker;

  NetworkChecker({InternetConnectionChecker? checker})
    : _checker = checker ?? InternetConnectionChecker();

  Future<bool> get hasConnection => _checker.hasConnection;
}
