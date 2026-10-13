import { useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'

import { ApiError } from '../api/client'
import { useAuth } from '../auth/AuthContext'
import { Button, ErrorState, Field, PasswordField } from '../components/ui'

/**
 * A single centred card rather than the split brand panel a SaaS product would
 * use. This is an internal tool for one municipal operator: there is nobody to
 * sell to on this screen, so it behaves like a counter you sign in at.
 */
export function Login() {
  const { t } = useTranslation()
  const { signIn } = useAuth()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    setIsSubmitting(true)
    try {
      await signIn(email.trim(), password)
    } catch (caught) {
      setError(
        caught instanceof ApiError ? caught.message : t('staffGenericError'),
      )
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-full items-center justify-center px-4 py-12 sm:px-6">
      <div className="w-full max-w-[420px]">
        <div className="overflow-hidden rounded-xl bg-surface shadow-[var(--shadow-raised)]">
          <div className="px-6 py-8 sm:px-9 sm:py-9">
            <img
              src="/brand/jsp-logo.png"
              alt="ЈСП Скопје"
              className="mx-auto h-12 w-auto"
            />

            <h1 className="mt-7 text-center text-[26px] font-semibold tracking-tight text-ink">
              {t('loginTitle')}
            </h1>
            <p className="mt-2 text-center text-[15px] leading-relaxed text-ink-2">
              {t('loginSubtitle')}
            </p>

            <form onSubmit={onSubmit} className="mt-7 space-y-4">
              {/* The label names the field; the hint string shows the shape
                  of the answer inside it. */}
              <Field
                label={t('fieldEmail')}
                placeholder={t('loginEmailHint')}
                type="email"
                autoComplete="username"
                required
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
              <PasswordField
                label={t('fieldPassword')}
                placeholder={t('loginPasswordHint')}
                autoComplete="current-password"
                required
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />

              {error ? <ErrorState message={error} /> : null}

              <Button
                type="submit"
                isLoading={isSubmitting}
                className="w-full"
              >
                {t('loginSignIn')}
              </Button>
            </form>
          </div>

          <div className="border-t border-hairline bg-black/[0.02] px-6 py-4 sm:px-9">
            <p className="text-center text-[13px] leading-relaxed text-ink-3">
              {t('loginNoAccess')} {t('loginContactDispatch')}
            </p>
          </div>
        </div>

        <p className="mt-6 text-center text-[13px] text-ink-3">
          {t('homeFooter')}
        </p>
      </div>
    </div>
  )
}
