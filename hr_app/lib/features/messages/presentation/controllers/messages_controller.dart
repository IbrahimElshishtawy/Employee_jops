import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';

enum MessagesTab {
  all('All Conversations'),
  unread('Unread Inquiries'),
  resolved('Resolved');

  final String label;
  const MessagesTab(this.label);
}

/// State controller for HR Messages and Direct Internal Communications
class MessagesController extends ChangeNotifier {
  final MessagesRepository _repository;

  List<ConversationEntity> _conversations = [];
  ConversationEntity? _selectedConversation;
  List<ChatMessageEntity> _messages = [];
  MessagesKpiSummary? _kpis;

  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;

  MessagesTab _activeTab = MessagesTab.all;
  String? _searchQuery;
  String? _errorMessage;

  MessagesController(this._repository, {bool autoFetch = true}) {
    if (autoFetch) {
      fetchConversations();
      fetchKpis();
    }
  }

  List<ConversationEntity> get conversations => _conversations;
  ConversationEntity? get selectedConversation => _selectedConversation;
  List<ChatMessageEntity> get messages => _messages;
  MessagesKpiSummary? get kpis => _kpis;

  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;

  MessagesTab get activeTab => _activeTab;
  String? get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  void setActiveTab(MessagesTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    fetchConversations();
  }

  void onSearch(String query) {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    fetchConversations();
  }

  Future<void> fetchKpis() async {
    try {
      _kpis = await _repository.getMessagesKpis();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchConversations() async {
    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final filter = ConversationFilter(
        searchQuery: _searchQuery,
        onlyUnread: _activeTab == MessagesTab.unread ? true : null,
        status: _activeTab == MessagesTab.resolved ? ConversationStatus.resolved : null,
        pageSize: 50,
      );

      final result = await _repository.getConversations(filter);
      _conversations = result.items;

      // Maintain selection or auto-select first conversation if available
      if (_selectedConversation == null && _conversations.isNotEmpty) {
        selectConversation(_conversations.first);
      } else if (_selectedConversation != null) {
        final existing = _conversations.where((c) => c.id == _selectedConversation!.id).firstOrNull;
        if (existing != null) {
          _selectedConversation = existing;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(ConversationEntity conversation) async {
    _selectedConversation = conversation;
    _isLoadingMessages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final msgs = await _repository.getMessages(conversation.id);
      _messages = msgs;

      // If unread messages exist, mark as read
      if (conversation.unreadCount > 0) {
        await _repository.markConversationAsRead(conversation.id);
        final idx = _conversations.indexWhere((c) => c.id == conversation.id);
        if (idx != -1) {
          _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
          _selectedConversation = _conversations[idx];
        }
        await fetchKpis();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String content) async {
    if (_selectedConversation == null || content.trim().isEmpty) return false;

    _isSendingMessage = true;
    notifyListeners();

    try {
      final sentMsg = await _repository.sendMessage(_selectedConversation!.id, content.trim());
      _messages = [..._messages, sentMsg];

      // Update active conversation preview in the list
      final idx = _conversations.indexWhere((c) => c.id == _selectedConversation!.id);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(
          lastMessageContent: content.trim(),
          lastMessageTime: DateTime.now(),
          lastMessageSenderType: MessageSenderType.hr,
          unreadCount: 0,
        );
        _selectedConversation = _conversations[idx];
      }

      await fetchKpis();
      _isSendingMessage = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }

  Future<ConversationEntity?> startNewConversation(String employeeId, String initialMessage) async {
    try {
      final newConv = await _repository.startConversation(employeeId, initialMessage);
      _selectedConversation = newConv;
      await fetchConversations();
      _selectedConversation = newConv;
      await selectConversation(newConv);
      await fetchKpis();
      return newConv;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
