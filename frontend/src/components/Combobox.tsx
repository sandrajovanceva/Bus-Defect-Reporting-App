import * as Popover from '@radix-ui/react-popover'
import clsx from 'clsx'
import { Check, ChevronDown } from 'lucide-react'
import { useEffect, useId, useMemo, useRef, useState, type ReactNode } from 'react'

import { INPUT_CLASSES } from './ui'

export interface ComboboxOption {
  value: string
  label: string
  /** Secondary text on the right of the row, e.g. a depot. */
  hint?: string
}

/** Matches that start with what was typed come first: typing "11" should
 *  put 1110 above 2111. */
function rank(options: ComboboxOption[], query: string): ComboboxOption[] {
  const needle = query.trim().toLowerCase()
  if (!needle) return options
  const starts: ComboboxOption[] = []
  const contains: ComboboxOption[] = []
  for (const option of options) {
    const label = option.label.toLowerCase()
    if (label.startsWith(needle)) starts.push(option)
    else if (label.includes(needle)) contains.push(option)
  }
  return [...starts, ...contains]
}

/**
 * A text field that suggests as you type — the system-style replacement for
 * a long dropdown nobody wants to scroll on a phone.
 *
 * With `allowCustom`, whatever is typed is the value and the list only
 * helps. Without it, only a listed option can be chosen: leaving the field
 * with anything else typed puts the last valid choice back.
 */
export function Combobox({
  label,
  value,
  onChange,
  options,
  placeholder,
  emptyText,
  allowCustom = false,
  disabled = false,
  inputMode,
  leading,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  options: ComboboxOption[]
  placeholder?: string
  emptyText: string
  allowCustom?: boolean
  disabled?: boolean
  inputMode?: 'text' | 'numeric'
  leading?: ReactNode
}) {
  const id = useId()
  const listRef = useRef<HTMLUListElement>(null)
  const labelFor = (v: string) =>
    options.find((option) => option.value === v)?.label ?? (allowCustom ? v : '')

  const [query, setQuery] = useState(() => labelFor(value))
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)

  // Keep the text in step when the value is changed from outside, e.g. the
  // form being reset or the depot switched.
  useEffect(() => {
    setQuery(labelFor(value))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value, options])

  const matches = useMemo(() => rank(options, open ? query : ''), [options, query, open])

  useEffect(() => {
    listRef.current
      ?.querySelector<HTMLElement>(`[data-index="${active}"]`)
      ?.scrollIntoView({ block: 'nearest' })
  }, [active])

  function choose(option: ComboboxOption) {
    onChange(option.value)
    setQuery(option.label)
    setOpen(false)
  }

  function commitOnLeave() {
    setOpen(false)
    if (allowCustom) return
    const exact = options.find(
      (option) => option.label.toLowerCase() === query.trim().toLowerCase(),
    )
    if (exact) choose(exact)
    else setQuery(labelFor(value))
  }

  return (
    <div className="block">
      <label htmlFor={id} className="field-label mb-1.5 block">
        {label}
      </label>
      <Popover.Root open={open && !disabled} onOpenChange={setOpen}>
        <Popover.Anchor asChild>
          <div className="relative">
            {leading ? (
              <span className="pointer-events-none absolute top-1/2 left-3.5 -translate-y-1/2 text-ink-3">
                {leading}
              </span>
            ) : null}
            <input
              id={id}
              role="combobox"
              aria-expanded={open}
              aria-controls={`${id}-list`}
              aria-autocomplete="list"
              autoComplete="off"
              inputMode={inputMode}
              disabled={disabled}
              value={query}
              placeholder={placeholder}
              onFocus={(event) => {
                event.target.select()
                setOpen(true)
                setActive(0)
              }}
              onClick={() => setOpen(true)}
              onChange={(event) => {
                setQuery(event.target.value)
                setOpen(true)
                setActive(0)
                if (allowCustom) onChange(event.target.value)
              }}
              onBlur={commitOnLeave}
              onKeyDown={(event) => {
                if (event.key === 'ArrowDown') {
                  event.preventDefault()
                  setOpen(true)
                  setActive((i) => Math.min(i + 1, matches.length - 1))
                } else if (event.key === 'ArrowUp') {
                  event.preventDefault()
                  setActive((i) => Math.max(i - 1, 0))
                } else if (event.key === 'Enter' && open && matches[active]) {
                  event.preventDefault()
                  choose(matches[active])
                } else if (event.key === 'Escape' && open) {
                  // Close the list, not the dialog around it.
                  event.stopPropagation()
                  setOpen(false)
                }
              }}
              className={clsx(
                INPUT_CLASSES,
                'pr-9 disabled:cursor-not-allowed disabled:opacity-50',
                leading && 'pl-10',
              )}
            />
            <ChevronDown
              size={16}
              className="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-ink-3"
            />
          </div>
        </Popover.Anchor>

        <Popover.Portal>
          <Popover.Content
            align="start"
            sideOffset={6}
            collisionPadding={12}
            // Focus stays in the field so typing keeps filtering.
            onOpenAutoFocus={(event) => event.preventDefault()}
            onInteractOutside={(event) => {
              if ((event.target as HTMLElement).id === id) event.preventDefault()
            }}
            className={clsx(
              'z-50 w-[var(--radix-popover-trigger-width)] overflow-hidden',
              'rounded-xl bg-surface/95 shadow-[var(--shadow-raised)] backdrop-blur-xl',
              'ring-1 ring-black/[0.06]',
              'origin-[var(--radix-popover-content-transform-origin)] animate-[pop-in_140ms_ease-out]',
            )}
          >
            {matches.length === 0 ? (
              <p className="px-4 py-3 text-[14px] text-ink-3">{emptyText}</p>
            ) : (
              <ul
                id={`${id}-list`}
                ref={listRef}
                role="listbox"
                className="max-h-[min(18rem,var(--radix-popover-content-available-height))] overflow-y-auto p-1.5"
              >
                {matches.map((option, index) => (
                  <li
                    key={option.value}
                    data-index={index}
                    role="option"
                    aria-selected={option.value === value}
                    // mousedown, not click: it must land before the field's
                    // blur reverts the text.
                    onMouseDown={(event) => {
                      event.preventDefault()
                      choose(option)
                    }}
                    onMouseMove={() => setActive(index)}
                    className={clsx(
                      'relative flex cursor-default items-center gap-3 rounded-md py-2 pr-3 pl-8 text-[14px]',
                      index === active ? 'bg-accent text-white' : 'text-ink',
                    )}
                  >
                    {option.value === value ? (
                      <Check
                        size={14}
                        strokeWidth={2.5}
                        className="absolute left-2.5"
                      />
                    ) : null}
                    <span className="min-w-0 flex-1 truncate font-medium">
                      {option.label}
                    </span>
                    {option.hint ? (
                      <span
                        className={clsx(
                          'shrink-0 text-[12px]',
                          index === active ? 'text-white/80' : 'text-ink-3',
                        )}
                      >
                        {option.hint}
                      </span>
                    ) : null}
                  </li>
                ))}
              </ul>
            )}
          </Popover.Content>
        </Popover.Portal>
      </Popover.Root>
    </div>
  )
}
