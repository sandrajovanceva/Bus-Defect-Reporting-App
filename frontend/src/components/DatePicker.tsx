import * as Popover from '@radix-ui/react-popover'
import clsx from 'clsx'
import { CalendarDays, ChevronLeft, ChevronRight } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'

import {
  formatDayShort,
  localDayKey,
  monthName,
  weekdayHeaders,
} from '../lib/domain'
import { INPUT_CLASSES } from './ui'

function fromKey(key: string): Date {
  const [year, month, day] = key.split('-').map(Number)
  return new Date(year, month - 1, day)
}

/** The six weeks shown for a month, Monday first, padded with the days of
 *  the neighbouring months so the grid never changes height. */
function monthGrid(year: number, month: number): Date[] {
  const first = new Date(year, month, 1)
  const offset = (first.getDay() + 6) % 7
  return Array.from(
    { length: 42 },
    (_, i) => new Date(year, month, 1 - offset + i),
  )
}

/**
 * A day picker in the system style: the field shows the chosen day in
 * words, and opens a month calendar in a floating panel. Replaces the
 * browser's own date input, which renders in US format and looks different
 * in every browser.
 *
 * `value` and `max` are local YYYY-MM-DD keys.
 */
export function DatePicker({
  value,
  onChange,
  max,
  className,
}: {
  value: string
  onChange: (key: string) => void
  max?: string
  className?: string
}) {
  const { t, i18n } = useTranslation()
  const selected = fromKey(value)
  const today = localDayKey(new Date())

  const [open, setOpen] = useState(false)
  // The month on display; follows the selection each time the panel opens.
  const [shown, setShown] = useState({
    year: selected.getFullYear(),
    month: selected.getMonth(),
  })

  function onOpenChange(next: boolean) {
    if (next) {
      setShown({ year: selected.getFullYear(), month: selected.getMonth() })
    }
    setOpen(next)
  }

  function step(months: number) {
    const d = new Date(shown.year, shown.month + months, 1)
    setShown({ year: d.getFullYear(), month: d.getMonth() })
  }

  const canGoForward =
    !max || localDayKey(new Date(shown.year, shown.month + 1, 1)) <= max

  return (
    <Popover.Root open={open} onOpenChange={onOpenChange}>
      <Popover.Trigger
        className={clsx(
          INPUT_CLASSES,
          'flex items-center gap-2.5 text-left whitespace-nowrap',
          'data-[state=open]:bg-surface data-[state=open]:ring-2 data-[state=open]:ring-accent/30',
          className,
        )}
      >
        <CalendarDays size={17} strokeWidth={1.9} className="shrink-0 text-ink-3" />
        <span className="min-w-0 truncate">
          {formatDayShort(selected, i18n.language)}
        </span>
      </Popover.Trigger>

      <Popover.Portal>
        <Popover.Content
          align="start"
          sideOffset={6}
          collisionPadding={12}
          className={clsx(
            'z-50 w-[19.5rem] rounded-xl bg-surface/95 p-3 backdrop-blur-xl',
            'shadow-[var(--shadow-raised)] ring-1 ring-black/[0.06]',
            'origin-[var(--radix-popover-content-transform-origin)] animate-[pop-in_140ms_ease-out]',
          )}
        >
          <div className="mb-2 flex items-center gap-1 pl-2">
            <p className="flex-1 text-[15px] font-semibold tracking-tight text-ink first-letter:uppercase">
              {monthName(shown.month, i18n.language)} {shown.year}
            </p>
            <MonthButton label={t('drPrevMonth')} onClick={() => step(-1)}>
              <ChevronLeft size={18} />
            </MonthButton>
            <MonthButton
              label={t('drNextMonth')}
              disabled={!canGoForward}
              onClick={() => step(1)}
            >
              <ChevronRight size={18} />
            </MonthButton>
          </div>

          <div className="grid grid-cols-7">
            {weekdayHeaders(i18n.language).map((day) => (
              <span
                key={day}
                className="pb-1.5 text-center text-[11px] font-semibold text-ink-3"
              >
                {day}
              </span>
            ))}

            {monthGrid(shown.year, shown.month).map((date) => {
              const key = localDayKey(date)
              const inMonth = date.getMonth() === shown.month
              const isSelected = key === value
              const isToday = key === today
              const isDisabled = Boolean(max && key > max)

              return (
                <button
                  key={key}
                  type="button"
                  disabled={isDisabled}
                  onClick={() => {
                    onChange(key)
                    setOpen(false)
                  }}
                  aria-pressed={isSelected}
                  aria-label={formatDayShort(date, i18n.language)}
                  className={clsx(
                    'tabular mx-auto my-0.5 flex size-9 items-center justify-center rounded-full text-[14px]',
                    'transition-colors duration-100',
                    isSelected
                      ? 'bg-accent font-semibold text-white'
                      : isToday
                        ? 'font-semibold text-accent hover:bg-accent/10'
                        : inMonth
                          ? 'text-ink hover:bg-black/[0.06]'
                          : 'text-ink-3/60 hover:bg-black/[0.04]',
                    'disabled:pointer-events-none disabled:text-ink-3/30',
                  )}
                >
                  {date.getDate()}
                </button>
              )
            })}
          </div>
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  )
}

function MonthButton({
  label,
  disabled,
  onClick,
  children,
}: {
  label: string
  disabled?: boolean
  onClick: () => void
  children: React.ReactNode
}) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      disabled={disabled}
      onClick={onClick}
      className="rounded-full p-1.5 text-accent transition-colors hover:bg-accent/10 disabled:pointer-events-none disabled:text-ink-3/40"
    >
      {children}
    </button>
  )
}
