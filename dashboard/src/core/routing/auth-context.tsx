import React, { createContext, useContext, useEffect, useState } from 'react';
import { api } from '../network/api-client';
import { TokenStorage } from '../storage/token-storage';
import { Role } from '../constants/permissions';

export interface UserProfile {
  id: string;
  email: string;
  role: Role;
  status: string;
  employeeProfile?: {
    id: string;
    employeeCode: string;
    firstName: string;
    lastName: string;
    department: string;
    jobTitle: string;
    avatarUrl?: string;
  };
}

interface AuthContextType {
  user: UserProfile | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: { email: string; passwordHash: string; rememberMe?: boolean }) => Promise<void>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  hasRole: (roles: Role[]) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(() => TokenStorage.getUser());
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const refreshProfile = async () => {
    try {
      const res = await api.get<UserProfile>('/auth/me');
      if (res.data) {
        setUser(res.data);
        TokenStorage.setUser(res.data);
      }
    } catch {
      TokenStorage.clear();
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (TokenStorage.getAccessToken()) {
      refreshProfile();
    } else {
      setIsLoading(false);
    }
  }, []);

  const login = async ({
    email,
    passwordHash,
    rememberMe = true,
  }: {
    email: string;
    passwordHash: string;
    rememberMe?: boolean;
  }) => {
    setIsLoading(true);
    try {
      const res = await api.post('/auth/login', { email, passwordHash });
      const authData = res.data;
      if (authData.accessToken) {
        TokenStorage.setTokens(authData.accessToken, authData.refreshToken, rememberMe);
        if (authData.user) {
          setUser(authData.user);
          TokenStorage.setUser(authData.user, rememberMe);
        } else {
          await refreshProfile();
        }
      }
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    try {
      const refreshToken = TokenStorage.getRefreshToken();
      if (refreshToken) {
        await api.post('/auth/logout', { refreshToken });
      }
    } catch {
      // Ignore logout errors
    } finally {
      TokenStorage.clear();
      setUser(null);
      window.location.href = '/login';
    }
  };

  const hasRole = (roles: Role[]): boolean => {
    if (!user) return false;
    if (user.role === Role.SUPER_ADMIN) return true;
    return roles.includes(user.role);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        login,
        logout,
        refreshProfile,
        hasRole,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
};
