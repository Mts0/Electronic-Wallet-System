enum MobileOperatorType {
  unknown,
  yemenMobile,
  you,
  sabafon,
  way,
}

class MobileOperatorInfo {
  final MobileOperatorType type;
  final String name;
  final String? assetPath;
  final bool isKnown;

  const MobileOperatorInfo({
    required this.type,
    required this.name,
    required this.assetPath,
    required this.isKnown,
  });

  const MobileOperatorInfo.unknown()
      : type = MobileOperatorType.unknown,
        name = 'غير معروف',
        assetPath = null,
        isKnown = false;
}

class MobileOperatorResolver {
  static MobileOperatorInfo resolve(String rawPhone) {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('77') || phone.startsWith('78')) {
      return const MobileOperatorInfo(
        type: MobileOperatorType.yemenMobile,
        name: 'يمن موبايل',
        assetPath: 'assets/images/operators/yemen_mobile.png',
        isKnown: true,
      );
    }

    if (phone.startsWith('73')) {
      return const MobileOperatorInfo(
        type: MobileOperatorType.you,
        name: 'YOU',
        assetPath: 'assets/images/operators/you.png',
        isKnown: true,
      );
    }

    if (phone.startsWith('71')) {
      return const MobileOperatorInfo(
        type: MobileOperatorType.sabafon,
        name: 'سبأفون',
        assetPath: 'assets/images/operators/sabafon.png',
        isKnown: true,
      );
    }

    if (phone.startsWith('70')) {
      return const MobileOperatorInfo(
        type: MobileOperatorType.way,
        name: 'واي',
        assetPath: 'assets/images/operators/way.png',
        isKnown: true,
      );
    }

    return const MobileOperatorInfo.unknown();
  }

  static bool isValidTopupPhone(String rawPhone) {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final operator = resolve(phone);

    return phone.length == 9 && phone.startsWith('7') && operator.isKnown;
  }
}