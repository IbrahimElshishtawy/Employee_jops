import 'dart:convert';

enum ChatMediaQuality {
  low,
  standard,
  high,
  original;

  String localizedName(bool isArabic) {
    switch (this) {
      case ChatMediaQuality.low:
        return isArabic ? 'منخفضة' : 'Low';
      case ChatMediaQuality.standard:
        return isArabic ? 'قياسية (موصى بها)' : 'Standard (Recommended)';
      case ChatMediaQuality.high:
        return isArabic ? 'عالية' : 'High';
      case ChatMediaQuality.original:
        return isArabic ? 'الجودة الأصلية' : 'Original';
    }
  }
}

class ChatSettings {
  // 1. Notifications
  final bool messageNotifications;
  final bool messageSound;
  final bool vibration;
  final bool messagePreview;

  // 2. Privacy
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool typingIndicator;
  final bool readReceipts;

  // 3. Media & Data
  final bool autoDownloadImages;
  final bool autoDownloadVideos;
  final bool wifiOnly;
  final ChatMediaQuality mediaQuality;

  // 4. Security
  final bool biometricChatLock;
  final bool hideMessagePreview;

  const ChatSettings({
    this.messageNotifications = true,
    this.messageSound = true,
    this.vibration = true,
    this.messagePreview = true,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.typingIndicator = true,
    this.readReceipts = true,
    this.autoDownloadImages = true,
    this.autoDownloadVideos = false,
    this.wifiOnly = false,
    this.mediaQuality = ChatMediaQuality.standard,
    this.biometricChatLock = false,
    this.hideMessagePreview = false,
  });

  ChatSettings copyWith({
    bool? messageNotifications,
    bool? messageSound,
    bool? vibration,
    bool? messagePreview,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? typingIndicator,
    bool? readReceipts,
    bool? autoDownloadImages,
    bool? autoDownloadVideos,
    bool? wifiOnly,
    ChatMediaQuality? mediaQuality,
    bool? biometricChatLock,
    bool? hideMessagePreview,
  }) {
    return ChatSettings(
      messageNotifications: messageNotifications ?? this.messageNotifications,
      messageSound: messageSound ?? this.messageSound,
      vibration: vibration ?? this.vibration,
      messagePreview: messagePreview ?? this.messagePreview,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      typingIndicator: typingIndicator ?? this.typingIndicator,
      readReceipts: readReceipts ?? this.readReceipts,
      autoDownloadImages: autoDownloadImages ?? this.autoDownloadImages,
      autoDownloadVideos: autoDownloadVideos ?? this.autoDownloadVideos,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      mediaQuality: mediaQuality ?? this.mediaQuality,
      biometricChatLock: biometricChatLock ?? this.biometricChatLock,
      hideMessagePreview: hideMessagePreview ?? this.hideMessagePreview,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageNotifications': messageNotifications,
      'messageSound': messageSound,
      'vibration': vibration,
      'messagePreview': messagePreview,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'typingIndicator': typingIndicator,
      'readReceipts': readReceipts,
      'autoDownloadImages': autoDownloadImages,
      'autoDownloadVideos': autoDownloadVideos,
      'wifiOnly': wifiOnly,
      'mediaQuality': mediaQuality.name,
      'biometricChatLock': biometricChatLock,
      'hideMessagePreview': hideMessagePreview,
    };
  }

  factory ChatSettings.fromMap(Map<String, dynamic> map) {
    return ChatSettings(
      messageNotifications: map['messageNotifications'] as bool? ?? true,
      messageSound: map['messageSound'] as bool? ?? true,
      vibration: map['vibration'] as bool? ?? true,
      messagePreview: map['messagePreview'] as bool? ?? true,
      showOnlineStatus: map['showOnlineStatus'] as bool? ?? true,
      showLastSeen: map['showLastSeen'] as bool? ?? true,
      typingIndicator: map['typingIndicator'] as bool? ?? true,
      readReceipts: map['readReceipts'] as bool? ?? true,
      autoDownloadImages: map['autoDownloadImages'] as bool? ?? true,
      autoDownloadVideos: map['autoDownloadVideos'] as bool? ?? false,
      wifiOnly: map['wifiOnly'] as bool? ?? false,
      mediaQuality: ChatMediaQuality.values.firstWhere(
        (e) => e.name == map['mediaQuality'],
        orElse: () => ChatMediaQuality.standard,
      ),
      biometricChatLock: map['biometricChatLock'] as bool? ?? false,
      hideMessagePreview: map['hideMessagePreview'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatSettings.fromJson(String source) =>
      ChatSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Storage breakdown model
class ChatStorageBreakdown {
  final int imagesBytes;
  final int videosBytes;
  final int filesBytes;
  final int voiceMessagesBytes;
  final int cachedDataBytes;

  const ChatStorageBreakdown({
    this.imagesBytes = 0,
    this.videosBytes = 0,
    this.filesBytes = 0,
    this.voiceMessagesBytes = 0,
    this.cachedDataBytes = 0,
  });

  int get totalBytes =>
      imagesBytes + videosBytes + filesBytes + voiceMessagesBytes + cachedDataBytes;

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(count >= 10 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}

/// Per-conversation settings model
class ConversationCustomSettings {
  final String conversationId;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;

  const ConversationCustomSettings({
    required this.conversationId,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
  });

  ConversationCustomSettings copyWith({
    String? conversationId,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
  }) {
    return ConversationCustomSettings(
      conversationId: conversationId ?? this.conversationId,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isArchived': isArchived,
    };
  }

  factory ConversationCustomSettings.fromMap(Map<String, dynamic> map) {
    return ConversationCustomSettings(
      conversationId: map['conversationId'] as String? ?? '',
      isMuted: map['isMuted'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }
}
