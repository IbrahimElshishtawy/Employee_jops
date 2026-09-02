import React, { useEffect, useState } from 'react';
import { MessageSquare, Send, User } from 'lucide-react';
import { api } from '../../core/network/api-client';
import { Button } from '../../shared/components/Button';
import { useAuth } from '../../core/routing/auth-context';

export const MessagesPage: React.FC = () => {
  const { user } = useAuth();
  const [conversations, setConversations] = useState<any[]>([]);
  const [activeConv, setActiveConv] = useState<any | null>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  const fetchConversations = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/messages/conversations');
      const list = Array.isArray(res.data) ? res.data : res.data?.data || [];
      setConversations(list);
      if (list.length > 0 && !activeConv) {
        setActiveConv(list[0]);
      }
    } catch {
      // Fallback
    } finally {
      setIsLoading(false);
    }
  };

  const fetchMessages = async (convId: string) => {
    try {
      const res = await api.get(`/messages/conversations/${convId}`);
      setMessages(Array.isArray(res.data) ? res.data : res.data?.data || []);
    } catch {
      // Fallback
    }
  };

  useEffect(() => {
    fetchConversations();
  }, []);

  useEffect(() => {
    if (activeConv?.id) {
      fetchMessages(activeConv.id);
    }
  }, [activeConv]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputText.trim() || !activeConv?.id) return;

    try {
      const sent = await api.post(`/messages/conversations/${activeConv.id}/messages`, {
        content: inputText,
      });
      setInputText('');
      setMessages((prev) => [...prev, sent.data || { content: inputText, senderId: user?.id, createdAt: new Date() }]);
    } catch (err: any) {
      alert(err.message || 'Failed to send message');
    }
  };

  return (
    <div className="flex flex-col gap-4" style={{ height: 'calc(100vh - 120px)' }}>
      <div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800 }}>Internal Staff Messaging</h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
          Secure, audit-logged internal communications between HR administration and employees
        </p>
      </div>

      <div
        className="card"
        style={{
          flex: 1,
          display: 'flex',
          padding: 0,
          overflow: 'hidden',
          minHeight: '480px',
        }}
      >
        {/* Conversations Sidebar */}
        <div
          style={{
            width: '320px',
            borderRight: '1px solid var(--border-color)',
            display: 'flex',
            flexDirection: 'column',
            backgroundColor: 'var(--bg-tertiary)',
          }}
        >
          <div style={{ padding: '1rem', borderBottom: '1px solid var(--border-color)' }}>
            <h4 style={{ fontSize: '0.95rem' }}>Conversations ({conversations.length})</h4>
          </div>

          <div style={{ flex: 1, overflowY: 'auto', padding: '0.5rem' }} className="flex flex-col gap-1">
            {isLoading ? (
              <p style={{ padding: '1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>Loading threads...</p>
            ) : conversations.length === 0 ? (
              <p style={{ padding: '1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>No conversations started</p>
            ) : (
              conversations.map((c) => {
                const isSelected = activeConv?.id === c.id;
                return (
                  <button
                    key={c.id}
                    onClick={() => setActiveConv(c)}
                    style={{
                      padding: '0.75rem',
                      borderRadius: 'var(--radius-sm)',
                      backgroundColor: isSelected ? 'var(--bg-secondary)' : 'transparent',
                      border: '1px solid',
                      borderColor: isSelected ? 'var(--border-color)' : 'transparent',
                      textAlign: 'left',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.75rem',
                    }}
                  >
                    <div
                      style={{
                        width: '36px',
                        height: '36px',
                        borderRadius: '50%',
                        backgroundColor: 'var(--primary-light)',
                        color: 'var(--primary)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexShrink: 0,
                      }}
                    >
                      <User size={18} />
                    </div>
                    <div style={{ minWidth: 0, flex: 1 }}>
                      <strong style={{ fontSize: '0.85rem', display: 'block' }}>
                        {c.title || 'Staff Thread'}
                      </strong>
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        Active conversation
                      </span>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* Chat Thread */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          {activeConv ? (
            <>
              {/* Thread Header */}
              <div
                style={{
                  padding: '1rem 1.5rem',
                  borderBottom: '1px solid var(--border-color)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.75rem',
                }}
              >
                <MessageSquare size={18} color="var(--primary)" />
                <h4 style={{ fontSize: '1rem' }}>{activeConv.title || 'Direct Conversation'}</h4>
              </div>

              {/* Message History */}
              <div style={{ flex: 1, overflowY: 'auto', padding: '1.5rem' }} className="flex flex-col gap-3">
                {messages.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
                    No messages in this conversation yet.
                  </div>
                ) : (
                  messages.map((m, i) => {
                    const isMe = m.senderId === user?.id;
                    return (
                      <div
                        key={m.id || i}
                        style={{
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: isMe ? 'flex-end' : 'flex-start',
                        }}
                      >
                        <div
                          style={{
                            maxWidth: '70%',
                            padding: '0.75rem 1rem',
                            borderRadius: '12px',
                            backgroundColor: isMe ? 'var(--primary)' : 'var(--bg-tertiary)',
                            color: isMe ? '#ffffff' : 'var(--text-primary)',
                            fontSize: '0.875rem',
                          }}
                        >
                          {m.content}
                        </div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: '0.2rem' }}>
                          {m.createdAt ? new Date(m.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ''}
                        </span>
                      </div>
                    );
                  })
                )}
              </div>

              {/* Message Input */}
              <form
                onSubmit={handleSendMessage}
                style={{
                  padding: '1rem 1.5rem',
                  borderTop: '1px solid var(--border-color)',
                  display: 'flex',
                  gap: '0.75rem',
                }}
              >
                <input
                  className="input"
                  placeholder="Type a message to employee..."
                  value={inputText}
                  onChange={(e) => setInputText(e.target.value)}
                />
                <Button type="submit" variant="primary" icon={<Send size={16} />}>
                  Send
                </Button>
              </form>
            </>
          ) : (
            <div className="flex flex-col items-center justify-center flex-1" style={{ color: 'var(--text-muted)' }}>
              <MessageSquare size={36} style={{ marginBottom: '0.5rem', opacity: 0.4 }} />
              <p>Select a thread to open message history</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
