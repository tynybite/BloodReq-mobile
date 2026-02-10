import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../../shared/models/support_ticket_model.dart';

class SupportProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<SupportTicket> _tickets = [];
  SupportTicketDetail? _currentTicket;
  bool _isLoading = false;
  String? _error;

  List<SupportTicket> get tickets => _tickets;
  SupportTicketDetail? get currentTicket => _currentTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiEndpoints.supportTickets);
      if (response.success && response.data != null) {
        final ticketsList = response.data['tickets'] as List<dynamic>? ?? [];
        _tickets = ticketsList.map((t) => SupportTicket.fromJson(t)).toList();
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load tickets';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTicketDetail(String ticketId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(
        ApiEndpoints.supportTicketDetail(ticketId),
      );
      if (response.success && response.data != null) {
        _currentTicket = SupportTicketDetail.fromJson(response.data);
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load ticket';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTicket({
    required String subject,
    required String category,
    required String message,
    String priority = 'medium',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.supportTickets,
        body: {
          'subject': subject,
          'category': category,
          'message': message,
          'priority': priority,
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.success) {
        await loadTickets();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create ticket';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendReply(String ticketId, String message) async {
    try {
      final response = await _api.post(
        ApiEndpoints.supportTicketReply(ticketId),
        body: {'message': message},
      );

      if (response.success) {
        // Optimistically add the message locally
        if (_currentTicket != null) {
          _currentTicket = SupportTicketDetail(
            id: _currentTicket!.id,
            userId: _currentTicket!.userId,
            userEmail: _currentTicket!.userEmail,
            userName: _currentTicket!.userName,
            subject: _currentTicket!.subject,
            category: _currentTicket!.category,
            status: _currentTicket!.status,
            priority: _currentTicket!.priority,
            messages: [
              ..._currentTicket!.messages,
              SupportMessage(
                senderId: _currentTicket!.userId,
                text: message,
                isAdmin: false,
                createdAt: DateTime.now(),
              ),
            ],
            createdAt: _currentTicket!.createdAt,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearCurrentTicket() {
    _currentTicket = null;
    notifyListeners();
  }
}
