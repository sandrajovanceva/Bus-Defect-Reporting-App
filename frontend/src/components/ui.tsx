import * as RadixSelect from '@radix-ui/react-select'
import clsx from 'clsx'
import { Check, ChevronDown, ChevronUp } from 'lucide-react'
import { Children, isValidElement, useState } from 'react'
import type {
  ButtonHTMLAttributes,
  InputHTMLAttributes,
  OptgroupHTMLAttributes,
  OptionHTMLAttributes,
  ReactElement,
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

/** Radix reserves "" for "nothing selected", so a real "" option (the "—"
 *  placeholder) travels under this stand-in. */
const EMPTY_VALUE = '__empty__'

interface SelectOption {
  value: string
  label: ReactNode
  disabled?: boolean
}

interface SelectSection {
  label: string | null
  options: SelectOption[]
}

/** Reads `<option>` / `<optgroup>` children in order, so callers write the
 *  same markup a native select takes. */
function readSections(children: ReactNode): SelectSection[] {
  const sections: SelectSection[] = []
  const toOption = (el: ReactElement<OptionHTMLAttributes<HTMLOptionElement>>) => ({
    value: String(el.props.value ?? ''),
    label: el.props.children,
    disabled: el.props.disabled,
  })

  Children.forEach(children, (child) => {
    if (!isValidElement(child)) return
    if (child.type === 'option') {
      const last = sections[sections.length - 1]
      const option = toOption(child as ReactElement<OptionHTMLAttributes<HTMLOptionElement>>)
      if (last && last.label === null) last.options.push(option)
      else sections.push({ label: null, options: [option] })
    } else if (child.type === 'optgroup') {
      const group = child as ReactElement<OptgroupHTMLAttributes<HTMLOptGroupElement>>
      const options: SelectOption[] = []
      Children.forEach(group.props.children, (inner) => {
        if (isValidElement(inner) && inner.type === 'option') {
          options.push(
            toOption(inner as ReactElement<OptionHTMLAttributes<HTMLOptionElement>>),
          )
        }
      })
      if (options.length) {
        sections.push({ label: String(group.props.label ?? ''), options })
      }
    }
  })
  return sections
}

/**
 * A dropdown in the system style: a soft field that opens a floating,
 * rounded list with a check against the current choice — not the browser's
 * native menu, which looks different on every OS and dated on most.
 *
 * Takes `<option>` / `<optgroup>` children and reports changes as
 * `{ target: { value } }`, so it drops in where a native select was.
 */
export function Select({
  label,
  className,
  children,
  value,
  onChange,
  disabled,
}: {
  label?: string
  className?: string
  children: ReactNode
  value: string
  onChange?: (event: { target: { value: string } }) => void
  disabled?: boolean
}) {
  const sections = readSections(children)
  const toRadix = (v: string) => (v === '' ? EMPTY_VALUE : v)

  const select = (
    <RadixSelect.Root
      value={toRadix(value)}
      disabled={disabled}
      onValueChange={(next) =>
        onChange?.({ target: { value: next === EMPTY_VALUE ? '' : next } })
      }
    >
      <RadixSelect.Trigger
        className={clsx(
          INPUT_CLASSES,
          'flex items-center justify-between gap-2 text-left',
          'data-[state=open]:bg-surface data-[state=open]:ring-2 data-[state=open]:ring-accent/30',
          'disabled:opacity-50',
          className,
        )}
      >
        <span className="min-w-0 truncate">
          <RadixSelect.Value />
        </span>
        <RadixSelect.Icon className="shrink-0 text-ink-3">
          <ChevronDown size={16} strokeWidth={2} />
        </RadixSelect.Icon>
      </RadixSelect.Trigger>

      <RadixSelect.Portal>
        <RadixSelect.Content
          position="popper"
          sideOffset={6}
          className={clsx(
            'z-50 max-h-[min(22rem,var(--radix-select-content-available-height))]',
            'min-w-[var(--radix-select-trigger-width)] overflow-hidden',
            'rounded-xl bg-surface/95 shadow-[var(--shadow-raised)] backdrop-blur-xl',
            'ring-1 ring-black/[0.06]',
            'origin-[var(--radix-select-content-transform-origin)] animate-[pop-in_140ms_ease-out]',
          )}
        >
          <RadixSelect.ScrollUpButton className="flex h-6 items-center justify-center text-ink-3">
            <ChevronUp size={14} />
          </RadixSelect.ScrollUpButton>
          <RadixSelect.Viewport className="p-1.5">
            {sections.map((section, index) => (
              <RadixSelect.Group key={section.label ?? `loose-${index}`}>
                {index > 0 ? (
                  <RadixSelect.Separator className="mx-2 my-1.5 h-px bg-hairline" />
                ) : null}
                {section.label ? (
                  <RadixSelect.Label className="px-3 pt-1.5 pb-1 text-[12px] font-semibold text-ink-3">
                    {section.label}
                  </RadixSelect.Label>
                ) : null}
                {section.options.map((option) => (
                  <RadixSelect.Item
                    key={option.value}
                    value={toRadix(option.value)}
                    disabled={option.disabled}
                    className={clsx(
                      'relative flex cursor-default items-center rounded-md py-2 pr-3 pl-8',
                      'text-[14px] text-ink outline-none select-none',
                      'data-[highlighted]:bg-accent data-[highlighted]:text-white',
                      'data-[disabled]:opacity-40',
                    )}
                  >
                    <RadixSelect.ItemIndicator className="absolute left-2.5 inline-flex">
                      <Check size={14} strokeWidth={2.5} />
                    </RadixSelect.ItemIndicator>
                    <RadixSelect.ItemText>{option.label}</RadixSelect.ItemText>
                  </RadixSelect.Item>
                ))}
              </RadixSelect.Group>
            ))}
          </RadixSelect.Viewport>
          <RadixSelect.ScrollDownButton className="flex h-6 items-center justify-center text-ink-3">
            <ChevronDown size={14} />
          </RadixSelect.ScrollDownButton>
        </RadixSelect.Content>
      </RadixSelect.Portal>
    </RadixSelect.Root>
  )

  if (!label) return select
  // A <div> rather than a <label>: the trigger is a button, and a wrapping
  // label would re-open the list on any click inside it.
  return (
    <div className="block">
      <span className="field-label mb-1.5 block">{label}</span>
      {select}
    </div>
  )
}

/**
 * Apple's segmented control: a few mutually exclusive choices side by side,
 * the chosen one raised on a white pill. `value` may be null until the
 * person picks, so nothing looks chosen by default.
 */
export function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
}: {
  options: { value: T; label: string }[]
  value: T | null
  onChange: (value: T) => void
}) {
  return (
    <div
      role="radiogroup"
      className="grid gap-1 rounded-[13px] bg-black/[0.05] p-1"
      style={{ gridTemplateColumns: `repeat(${options.length}, minmax(0, 1fr))` }}
    >
      {options.map((option) => {
        const isActive = option.value === value
        return (
          <button
            key={option.value}
            type="button"
            role="radio"
            aria-checked={isActive}
            onClick={() => onChange(option.value)}
            className={clsx(
              'truncate rounded-[9px] px-3 py-2 text-[14px] font-medium transition-all duration-150',
              isActive
                ? 'bg-surface text-ink shadow-[0_1px_3px_rgb(0_0_0/0.12)]'
                : 'text-ink-2 hover:text-ink',
            )}
          >
            {option.label}
          </button>
        )
      })}
    </div>
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
