import { ENV } from '../config/env.config';
import { TokenStorage } from '../storage/token-storage';

export interface ApiResponse<T = any> {
  success: boolean;
  statusCode: number;
  data: T;
  meta?: any;
  message?: string;
  timestamp?: string;
}

class ApiClient {
  private baseUrl = ENV.API_BASE_URL;
  private isRefreshing = false;
  private refreshSubscribers: ((token: string) => void)[] = [];

  private subscribeTokenRefresh(cb: (token: string) => void) {
    this.refreshSubscribers.push(cb);
  }

  private onRefreshed(token: string) {
    this.refreshSubscribers.forEach((cb) => cb(token));
    this.refreshSubscribers = [];
  }

  async request<T = any>(
    endpoint: string,
    options: RequestInit = {},
    retryCount = 0,
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;
    const token = TokenStorage.getAccessToken();

    const headers = new Headers(options.headers || {});
    if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
      headers.set('Content-Type', 'application/json');
    }
    if (token && !headers.has('Authorization')) {
      headers.set('Authorization', `Bearer ${token}`);
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers,
      });

      // Handle 401 Unauthorized (Token expired)
      if (response.status === 401 && retryCount === 0 && !endpoint.includes('/auth/login')) {
        const refreshToken = TokenStorage.getRefreshToken();
        if (!refreshToken) {
          TokenStorage.clear();
          window.location.href = '/login';
          throw new Error('Session expired');
        }

        if (!this.isRefreshing) {
          this.isRefreshing = true;
          try {
            const refreshRes = await fetch(`${this.baseUrl}/auth/refresh`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ refreshToken }),
            });

            if (!refreshRes.ok) {
              throw new Error('Failed to refresh token');
            }

            const refreshData = await refreshRes.json();
            const newAccessToken = refreshData?.data?.accessToken || refreshData?.accessToken;
            const newRefreshToken = refreshData?.data?.refreshToken || refreshData?.refreshToken;

            if (newAccessToken) {
              TokenStorage.setTokens(newAccessToken, newRefreshToken);
              this.onRefreshed(newAccessToken);
            }
          } catch (err) {
            TokenStorage.clear();
            window.location.href = '/login';
            throw err;
          } finally {
            this.isRefreshing = false;
          }
        }

        return new Promise((resolve) => {
          this.subscribeTokenRefresh(() => {
            resolve(this.request<T>(endpoint, options, retryCount + 1));
          });
        });
      }

      const isJson = response.headers.get('content-type')?.includes('application/json');
      const data = isJson ? await response.json() : await response.text();

      if (!response.ok) {
        const errorMessage =
          typeof data === 'object' && data !== null
            ? data.message || data.error || 'API request failed'
            : 'API request failed';
        const error: any = new Error(
          Array.isArray(errorMessage) ? errorMessage.join(', ') : errorMessage,
        );
        error.status = response.status;
        error.data = data;
        throw error;
      }

      if (isJson && data && typeof data === 'object' && 'data' in data) {
        return data as ApiResponse<T>;
      }

      return {
        success: true,
        statusCode: response.status,
        data: data as T,
      };
    } catch (err: any) {
      throw err;
    }
  }

  get<T = any>(endpoint: string, options?: RequestInit) {
    return this.request<T>(endpoint, { ...options, method: 'GET' });
  }

  post<T = any>(endpoint: string, body?: any, options?: RequestInit) {
    return this.request<T>(endpoint, {
      ...options,
      method: 'POST',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  }

  patch<T = any>(endpoint: string, body?: any, options?: RequestInit) {
    return this.request<T>(endpoint, {
      ...options,
      method: 'PATCH',
      body: body instanceof FormData ? body : JSON.stringify(body),
    });
  }

  delete<T = any>(endpoint: string, options?: RequestInit) {
    return this.request<T>(endpoint, { ...options, method: 'DELETE' });
  }
}

export const api = new ApiClient();
