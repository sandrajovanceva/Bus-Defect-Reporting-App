import clsx from 'clsx'
import { useState } from 'react'
import type {
  ButtonHTMLAttributes,
  InputHTMLAttributes,
  ReactNode,
} from 'react'
import { useTranslation } from 'react-i18next'

import {
  PRIORITY_CLASSES,
  STATUS_CLASSES,
  STATUS_DOT,
  priorityLabel,
  statusLabel,
} from '../lib/domain'
import type { DefectStatus, Priority } from '../types'

// --- button -----------------------------------------------------------------

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger'
type ButtonSize = 'sm' | 'md'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  size?: ButtonSize
  isLoading?: boolean
  icon?: ReactNode
}

const BUTTON_VARIANTS: Record<ButtonVariant, string> = {
  primary:
    'bg-accent text-white shadow-sm hover:bg-accent-dark active:scale-[0.98]',
  // A filled neutral rather than an outline — Apple's secondary is a tinted
  // fill, and outlines are most of what made the old set look drawn-on.
  secondary:
    'bg-black/[0.05] text-ink hover:bg-black/[0.08] active:scale-[0.98]',
  ghost: 'text-ink-2 hover:bg-black/[0.05] hover:text-ink',
  danger: 'bg-accent-soft text-accent hover:bg-accent hover:text-white',
}

const BUTTON_SIZES: Record<ButtonSize, string> = {
  sm: 'h-8 gap-1.5 px-3 text-[13px]',
  md: 'h-10 gap-2 px-4 text-sm',
}

export function Button({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  icon,
  className,
  children,
  disabled,
  ...rest
}: ButtonProps) {
  return (
    <button
      type="button"
      disabled={disabled || isLoading}
      className={clsx(
        'inline-flex items-center justify-center rounded-md font-medium',
        'transition-all duration-150',
        'disabled:pointer-events-none disabled:opacity-40',
        BUTTON_SIZES[size],
        BUTTON_VARIANTS[variant],
        className,
      )}
      {...rest}
    >
      {isLoading ? <Spinner /> : icon}
      {children}
    </button>
  )
}

export function Spinner({ className }: { className?: string }) {
  return (
    <span
      role="status"
      aria-label="loading"
      className={clsx(
        'inline-block size-3.5 animate-spin rounded-full',
        'border-2 border-current border-t-transparent opacity-60',
        className,
      )}
    />
  )
}

// --- surfaces ---------------------------------------------------------------

export function Panel({
  className,
  children,
}: {
  className?: string
  children: ReactNode
}) {
  return (
    <div
      className={clsx(
        'rounded-lg bg-surface shadow-[var(--shadow-card)]',
        className,
      )}
    >
      {children}
    </div>
  )
}

export function SectionLabel({ children }: { children: ReactNode }) {
  return <h2 className="section-title mb-3">{children}</h2>
}

// --- data chips -------------------------------------------------------------

export function StatusPill({
  status,
  className,
}: {
  status: DefectStatus
  className?: string
}) {
  const { t } = useTranslation()
  return (
    <span
      className={clsx(
        'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1',
        'text-[12px] font-medium whitespace-nowrap',
        STATUS_CLASSES[status],
        className,
      )}
    >
      <span className={clsx('size-1.5 rounded-full', STATUS_DOT[status])} />
      {statusLabel(t, status)}
    </span>
  )
}

export function PriorityChip({ priority }: { priority: Priority }) {
  const { t } = useTranslation()
  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full px-2 py-0.5',
        'text-[12px] font-medium',
        PRIORITY_CLASSES[priority],
      )}
    >
      {priorityLabel(t, priority)}
    </span>
  )
}

// --- form controls ----------------------------------------------------------

interface FieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string
}

export const INPUT_CLASSES =
  'w-full rounded-md bg-black/[0.04] px-3.5 py-2.5 text-[15px] text-ink ' +
  'placeholder:text-ink-3 transition-shadow ' +
  'focus:bg-surface focus:outline-none focus:ring-2 focus:ring-accent/30'

export function Field({ label, className, ...rest }: FieldProps) {
  return (
    <label className="block">
      <span className="field-label mb-1.5 block">{label}</span>
      <input className={clsx(INPUT_CLASSES, className)} {...rest} />
    </label>
  )
}

/**
 * Password entry with a reveal toggle.
 *
 * Depot passwords are handed out by a dispatcher and typed by someone who did
 * not choose them, so being able to check what was typed prevents a lockout.
 */
export function PasswordField({
  label,
  className,
  ...rest
}: Omit<FieldProps, 'type'>) {
  const { t } = useTranslation()
  const [isVisible, setIsVisible] = useState(false)

  return (
    <label className="block">
      <span className="field-label mb-1.5 block">{label}</span>
      <div className="relative">
        <input
          type={isVisible ? 'text' : 'password'}
          className={clsx(INPUT_CLASSES, 'pr-11', className)}
          {...rest}
        />
        <button
          type="button"
          onClick={() => setIsVisible((value) => !value)}
          aria-label={
            isVisible ? t('actionHidePassword') : t('actionShowPassword')
          }
          aria-pressed={isVisible}
          className="absolute top-1/2 right-1.5 -translate-y-1/2 rounded-sm p-1.5 text-ink-3 transition-colors hover:text-ink"
        >
          <EyeIcon isOff={isVisible} />
        </button>
      </div>
    </label>
  )
}

function EyeIcon({ isOff }: { isOff: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="size-[18px]"
      aria-hidden
    >
      <path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7Z" />
      <circle cx="12" cy="12" r="3" />
      {/* The slash is the "currently visible" state: clicking it hides. */}
      {isOff ? <path d="m3 3 18 18" /> : null}
    </svg>
  )
}

export function Select({
  label,
  className,
  children,
  ...rest
}: {
  label?: string
  className?: string
  children: ReactNode
} & InputHTMLAttributes<HTMLSelectElement>) {
  const select = (
    <select
      className={clsx(
        INPUT_CLASSES,
        'appearance-none bg-[length:16px] bg-[right_0.75rem_center] bg-no-repeat pr-9',
        className,
      )}
      style={{
        backgroundImage:
          "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='%238a8a91' stroke-width='1.6' stroke-linecap='round'%3E%3Cpath d='m4 6 4 4 4-4'/%3E%3C/svg%3E\")",
      }}
      {...rest}
    >
      {children}
    </select>
  )

  if (!label) return select
  return (
    <label className="block">
      <span className="field-label mb-1.5 block">{label}</span>
      {select}
    </label>
  )
}

// --- feedback ---------------------------------------------------------------

export function EmptyState({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="flex flex-col items-center justify-center px-6 py-20 text-center">
      <p className="text-[15px] text-ink-2">{title}</p>
      {hint ? <p className="mt-1 text-sm text-ink-3">{hint}</p> : null}
    </div>
  )
}

export function ErrorState({ message }: { message: string }) {
  return (
    <div className="rounded-md bg-accent-soft px-4 py-3">
      <p className="text-sm text-accent-dark">{message}</p>
    </div>
  )
}

export function LoadingState() {
  return (
    <div className="flex items-center justify-center py-20 text-ink-3">
      <Spinner className="size-5" />
    </div>
  )
}
