import '../entities/parental_control_entity.dart';
import '../repositories/parental_control_repository.dart';

class GetParentalControlStatusUseCase {
  final ParentalControlRepository repository;
  GetParentalControlStatusUseCase(this.repository);

  Future<bool> execute() async {
    return await repository.getParentalControlStatus();
  }
}

class SetParentalControlStatusUseCase {
  final ParentalControlRepository repository;
  SetParentalControlStatusUseCase(this.repository);

  Future<bool> execute(bool isEnabled) async {
    return await repository.setParentalControlStatus(isEnabled);
  }
}

class GetParentalDevicesUseCase {
  final ParentalControlRepository repository;
  GetParentalDevicesUseCase(this.repository);

  Future<List<ParentalDevice>> execute() async {
    return await repository.getParentalDevices();
  }
}

class SaveParentalRuleUseCase {
  final ParentalControlRepository repository;
  SaveParentalRuleUseCase(this.repository);

  Future<bool> execute(String mac, int startTime, int endTime, int repeatMode, int index) async {
    return await repository.saveParentalRule(mac, startTime, endTime, repeatMode, index);
  }
}

class DeleteParentalRuleUseCase {
  final ParentalControlRepository repository;
  DeleteParentalRuleUseCase(this.repository);

  Future<bool> execute(String mac) async {
    return await repository.deleteParentalRule(mac);
  }
}