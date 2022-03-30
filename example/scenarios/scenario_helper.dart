import '../user.dart';
import '../users_connection.dart';

class ScenarioHelper{
  User getUserByIndex(UsersConnection users,List<String> keys, int userOffset, int index){
    return users.users[keys[index + userOffset]]!;
  }
}