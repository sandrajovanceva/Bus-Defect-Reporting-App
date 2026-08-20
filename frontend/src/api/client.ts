import axios, { AxiosError } from 'axios'

const TOKEN_KEY = 'jsp.token'

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function setToken(token: string | null) {
  if (token) localStorage.setItem(TOKEN_KEY, token)
  else localStorage.removeItem(TOKEN_KEY)
}

/** Requests go to the same origin and are proxied to FastAPI, so there is no
 *  CORS surface in development or behind a reverse proxy in production. */
export const api = axios.create({ baseURL: '/api' })

api.interceptors.request.use((config) => {
  const token = getToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

/** Raised for anything the UI is expected to show a person. */
export class ApiError extends Error {
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

/**
 * Turns an axios failure into a message worth showing. FastAPI puts the useful
 * text in `detail`, which is either a string or a list of validation problems.
 */
export function toApiError(error: unknown, fallback: string): ApiError {
  if (error instanceof AxiosError) {
    const status = error.response?.status
    const detail = error.response?.data?.detail

    if (typeof detail === 'string') return new ApiError(detail, status)
    if (Array.isArray(detail) && detail.length > 0) {
      const first = detail[0]
      if (typeof first?.msg === 'string') return new ApiError(first.msg, status)
    }
    if (!error.response) {
      return new ApiError('Серверот не одговара. Проверете ја врската.', status)
    }
  }
  return new ApiError(fallback)
}

/** True when the failure means "your session is over", so the app can sign out
 *  rather than show an error the person cannot act on. */
export function isAuthFailure(error: unknown): boolean {
  return error instanceof AxiosError && error.response?.status === 401
}
