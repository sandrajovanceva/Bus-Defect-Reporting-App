import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import clsx from 'clsx'
import {
  Bus,
  ClipboardList,
  SlidersHorizontal,
  LayoutGrid,
  LogOut,
  Users,
  Wrench,
  type LucideIcon,
} from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { NavLink, Outlet, useLocation } from 'react-router'

import { useAuth } from '../auth/AuthContext'
import { LANGUAGES, setLanguage, type LanguageCode } from '../i18n'
import { departmentLabel, roleLabel } from '../lib/domain'
import type { UserRole } from '../types'

interface NavItem {
  to: string
  labelKey: string
  icon: LucideIcon
  roles: UserRole[]
}

/**
 * The whole navigation, declared once. Which entries a person sees is derived
 * from their role rather than from a menu screen — the reason this client does
 * not need the phone app's home screen of cards.
 */
const NAV: NavItem[] = [
  {
    to: '/overview',
    labelKey: 'navOverview',
    icon: LayoutGrid,
    roles: ['dispatcher'],
  },
  {
    to: '/armatura',
    labelKey: 'navArmatura',
    icon: SlidersHorizontal,
    roles: ['armatura'],
  },
  { to: '/queue', labelKey: 'navQueue', icon: Wrench, roles: ['service'] },
  {
    to: '/defects',
    labelKey: 'navDefects',
    icon: ClipboardList,
    roles: ['dispatcher', 'service', 'driver', 'armatura'],
  },
  { to: '/fleet', labelKey: 'navFleet', icon: Bus, roles: ['dispatcher'] },
  { to: '/staff', labelKey: 'navStaff', icon: Users, roles: ['dispatcher'] },
]

export function AppShell() {
  const { t } = useTranslation()
  const { user } = useAuth()
  const location = useLocation()

  const items = NAV.filter((item) => user && item.roles.includes(user.role))
  const current = items.find((item) => location.pathname.startsWith(item.to))

  return (
    <div className="relative h-full overflow-hidden">
      {/* A saturated wash under everything. The frosted chrome needs colour
          and shape beneath it: blurring flat cream reads as a tint. */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            'radial-gradient(55rem 38rem at 10% -8%, rgb(220 38 38 / 0.10), transparent 62%),' +
            'radial-gradient(48rem 36rem at 96% 104%, rgb(196 158 96 / 0.20), transparent 62%),' +
            'radial-gradient(40rem 30rem at 60% 40%, rgb(120 140 190 / 0.07), transparent 65%)',
        }}
      />

      {/* One scroll surface for the whole app. Content runs the full height
          and width and is inset by the chrome's size, so cards physically
          pass beneath the bar and the nav rather than stopping at them —
          that movement is what makes the frost read as glass. */}
      <main className="h-full overflow-auto pt-14 pl-[248px]">
        <h1 className="sr-only">{current ? t(current.labelKey) : ''}</h1>
        <Outlet />
      </main>

      <Sidebar items={items} />
      <TopBar />
    </div>
  )
}

function Sidebar({ items }: { items: NavItem[] }) {
  const { t } = useTranslation()
  const { user } = useAuth()

  return (
    <aside className="glass glass-edge-right fixed top-14 bottom-0 left-0 z-20 flex w-[248px] flex-col border-r border-hairline">
      <nav className="flex-1 px-3 py-4">
        <ul className="space-y-0.5">
          {items.map((item) => (
            <li key={item.to}>
              <NavLink
                to={item.to}
                className={({ isActive }) =>
                  clsx(
                    'flex items-center gap-2.5 rounded-md px-3 py-2 text-[14px] font-medium',
                    'transition-colors duration-150',
                    isActive
                      ? 'bg-accent/[0.09] text-accent'
                      : 'text-ink-2 hover:bg-black/[0.04] hover:text-ink',
                  )
                }
              >
                <item.icon size={17} strokeWidth={1.9} aria-hidden />
                {t(item.labelKey)}
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>

      {user ? (
        <div className="m-3 flex items-center gap-2.5 rounded-md bg-black/[0.035] px-3 py-2.5">
          <Avatar name={user.full_name} />
          <div className="min-w-0">
            <p className="truncate text-[14px] font-medium text-ink">
              {user.full_name}
            </p>
            <p className="truncate text-[12px] text-ink-3">
              {roleLabel(t, user.role)}
              {user.department
                ? ` · ${departmentLabel(t, user.department)}`
                : ''}
            </p>
          </div>
        </div>
      ) : null}
    </aside>
  )
}

function TopBar() {
  const { t } = useTranslation()
  const { user, signOut } = useAuth()

  return (
    <header className="glass glass-edge-bottom fixed inset-x-0 top-0 z-30 flex h-14 items-center gap-3 border-b border-hairline px-5">
      <img src="/brand/jsp-logo.png" alt="ЈСП Скопје" className="h-7 w-auto" />
      <span aria-hidden className="h-5 w-px bg-hairline-strong" />
      {/* The product's name, not the page's, and not a description of it —
          the mark already says ЈСП, so this does not repeat it. */}
      <p className="text-[15px] font-semibold tracking-tight text-ink">
        {t('appName')}
      </p>

      <div className="ml-auto flex items-center gap-1">
        <LanguageMenu />
        {user ? <UserMenu name={user.full_name} onSignOut={signOut} /> : null}
      </div>
    </header>
  )
}

/** Initials stand in for a photograph; there are no avatars in the system. */
function Avatar({ name, className }: { name: string; className?: string }) {
  const initials = name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('')

  return (
    <span
      aria-hidden
      className={clsx(
        'flex size-8 shrink-0 items-center justify-center rounded-full',
        'bg-accent/10 text-[12px] font-semibold text-accent',
        className,
      )}
    >
      {initials}
    </span>
  )
}

function UserMenu({
  name,
  onSignOut,
}: {
  name: string
  onSignOut: () => void
}) {
  const { t } = useTranslation()

  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger
        aria-label={name}
        className="rounded-full transition-opacity hover:opacity-80"
      >
        <Avatar name={name} />
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content
          align="end"
          sideOffset={6}
          className="min-w-52 rounded-lg bg-surface p-1.5 shadow-[var(--shadow-raised)]"
        >
          <div className="px-3 py-2">
            <p className="truncate text-[14px] font-medium text-ink">{name}</p>
          </div>
          <DropdownMenu.Separator className="my-1 h-px bg-hairline" />
          <DropdownMenu.Item
            onSelect={onSignOut}
            className="flex cursor-pointer items-center gap-2 rounded-sm px-3 py-2 text-[14px] text-ink outline-none data-[highlighted]:bg-black/[0.05]"
          >
            <LogOut size={15} strokeWidth={1.9} aria-hidden />
            {t('navSignOut')}
          </DropdownMenu.Item>
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  )
}

function LanguageMenu() {
  const { t, i18n } = useTranslation()

  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger className="rounded-md px-2.5 py-1.5 text-[13px] font-medium text-ink-2 transition-colors hover:bg-black/[0.05] hover:text-ink">
        {i18n.language.toUpperCase()}
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content
          align="end"
          sideOffset={6}
          className="min-w-44 rounded-lg bg-surface p-1.5 shadow-[var(--shadow-raised)]"
        >
          {LANGUAGES.map((language) => (
            <DropdownMenu.Item
              key={language.code}
              onSelect={() => setLanguage(language.code as LanguageCode)}
              className={clsx(
                'cursor-pointer rounded-sm px-3 py-2 text-[14px] outline-none',
                'data-[highlighted]:bg-black/[0.05]',
                i18n.language === language.code
                  ? 'font-medium text-accent'
                  : 'text-ink',
              )}
            >
              {t(language.labelKey)}
            </DropdownMenu.Item>
          ))}
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  )
}
