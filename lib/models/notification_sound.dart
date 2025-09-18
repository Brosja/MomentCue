class NotificationSound {
  final String id;
  final String name;
  final String? soundPath;
  final bool isDefault;

  const NotificationSound({
    required this.id,
    required this.name,
    this.soundPath,
    this.isDefault = false,
  });

  static const List<NotificationSound> availableSounds = [
    NotificationSound(
      id: 'default',
      name: 'Default',
      isDefault: true,
    ),
    NotificationSound(
      id: 'gentle',
      name: 'Gentle',
      soundPath: 'sounds/gentle.wav',
    ),
    NotificationSound(
      id: 'chime',
      name: 'Chime',
      soundPath: 'sounds/chime.wav',
    ),
    NotificationSound(
      id: 'bell',
      name: 'Bell',
      soundPath: 'sounds/bell.wav',
    ),
    NotificationSound(
      id: 'soft',
      name: 'Soft',
      soundPath: 'sounds/soft.wav',
    ),
    NotificationSound(
      id: 'none',
      name: 'None (Silent)',
    ),
  ];

  static NotificationSound getDefault() {
    return availableSounds.firstWhere((sound) => sound.isDefault);
  }

  static NotificationSound? fromId(String id) {
    try {
      return availableSounds.firstWhere((sound) => sound.id == id);
    } catch (e) {
      return null;
    }
  }
}
