import * as Dialog from '@radix-ui/react-dialog'
import { useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'

import { ApiError, toApiError } from '../api/client'
import {
  Button,
  ErrorState,
  Field,
  LoadingState,
  PasswordField,
  Panel,
  Select,
} from '../components/ui'
import {
  useCreateUser,
  useDeleteUser,
  useUpdateUser,
  useUsers,
} from '../hooks/queries'
import { departmentLabel, roleLabel } from '../lib/domain'
import {
  USER_ROLES,
  WORKER_DEPARTMENTS,
  type Department,
  type User,
  type UserRole,
} from '../types'

export function Staff() {
  const { t } = useTranslation()
  const { data, isPending, error } = useUsers()
  const update = useUpdateUser()
  const remove = useDeleteUser()

  const [isCreating, setIsCreating] = useState(false)

  return (
    <div className="flex flex-col p-4 sm:p-7 lg:h-full">
      <div className="mb-6 flex shrink-0 items-center gap-4">
        <p className="text-[13px] text-ink-3">{t('staffTitle')}</p>
        <Button className="ml-auto" onClick={() => setIsCreating(true)}>
          {t('staffNewUser')}
        </Button>
      </div>

      <Panel className="flex min-h-0 flex-1 flex-col overflow-hidden">
        {isPending ? (
          <LoadingState />
        ) : error ? (
          <div className="p-4">
            <ErrorState message={error.message} />
          </div>
        ) : !data || data.length === 0 ? (
          <p className="p-8 text-center text-sm text-ink-2">
            {t('staffEmpty')}
          </p>
        ) : (
          <>
          {/* A phone gets one card per person; the table needs a wide screen. */}
          <ul className="divide-y divide-hairline md:hidden">
            {data.map((account) => (
              <li key={account.id} className="px-4 py-3.5">
                <p className="text-[15px] font-semibold text-ink">
                  {account.full_name}
                  {!account.is_active ? (
                    <span className="ml-2 text-[12px] font-medium text-accent">
                      {t('staffInactive')}
                    </span>
                  ) : null}
                </p>
                <p className="mt-0.5 truncate font-mono text-[12px] text-ink-3">
                  {account.email}
                </p>
                <p className="mt-1 text-[13px] text-ink-2">
                  {roleLabel(t, account.role)}
                  {account.department
                    ? ` · ${departmentLabel(t, account.department)}`
                    : ''}
                </p>
                <div className="mt-2 flex justify-end gap-2">
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() =>
                      update.mutate({
                        id: account.id,
                        body: { is_active: !account.is_active },
                      })
                    }
                  >
                    {account.is_active
                      ? t('staffDeactivate')
                      : t('staffActivate')}
                  </Button>
                  <Button
                    size="sm"
                    variant="danger"
                    onClick={() => remove.mutate(account.id)}
                  >
                    {t('staffDelete')}
                  </Button>
                </div>
              </li>
            ))}
          </ul>
          <div className="hidden min-h-0 flex-1 overflow-auto md:block">
          <table className="w-full border-collapse text-sm">
            <thead className="sticky top-0 z-10 bg-surface">
              <tr className="border-b border-hairline">
                <th className="px-5 py-3 text-left text-[12px] font-medium text-ink-3">
                  {t('staffNameHint')}
                </th>
                <th className="px-5 py-3 text-left text-[12px] font-medium text-ink-3">
                  {t('staffEmailHint')}
                </th>
                <th className="px-5 py-3 text-left text-[12px] font-medium text-ink-3">
                  {t('fieldRole')}
                </th>
                <th className="px-5 py-3 text-left text-[12px] font-medium text-ink-3">
                  {t('colDepartment')}
                </th>
                <th className="px-5 py-3 text-right text-[12px] font-medium text-ink-3" />
              </tr>
            </thead>
            <tbody>
              {data.map((account) => (
                <tr
                  key={account.id}
                  className="border-b border-hairline/60 hover:bg-raised"
                >
                  <td className="px-4 py-3">
                    <span className="font-semibold text-ink">
                      {account.full_name}
                    </span>
                    {!account.is_active ? (
                      <span className="ml-2 text-[12px] font-medium text-accent">
                        {t('staffInactive')}
                      </span>
                    ) : null}
                  </td>
                  <td className="px-4 py-3 font-mono text-[12px] text-ink-3">
                    {account.email}
                  </td>
                  <td className="px-4 py-3 text-ink-2">
                    {roleLabel(t, account.role)}
                  </td>
                  <td className="px-4 py-3 text-ink-2">
                    {account.department
                      ? departmentLabel(t, account.department)
                      : '—'}
                  </td>
                  <td className="px-4 py-3 text-right whitespace-nowrap">
                    <Button
                      variant="ghost"
                      onClick={() =>
                        update.mutate({
                          id: account.id,
                          body: { is_active: !account.is_active },
                        })
                      }
                    >
                      {account.is_active
                        ? t('staffDeactivate')
                        : t('staffActivate')}
                    </Button>
                    <Button
                      variant="danger"
                      className="ml-2"
                      onClick={() => remove.mutate(account.id)}
                    >
                      {t('staffDelete')}
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          </div>
          </>
        )}
      </Panel>

      <CreateUserDialog
        open={isCreating}
        onOpenChange={setIsCreating}
      />
    </div>
  )
}

function CreateUserDialog({
  open,
  onOpenChange,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
}) {
  const { t } = useTranslation()
  const create = useCreateUser()

  const [email, setEmail] = useState('')
  const [fullName, setFullName] = useState('')
  const [password, setPassword] = useState('')
  const [role, setRole] = useState<UserRole>('driver')
  const [department, setDepartment] = useState<Department>('mechanical')
  const [error, setError] = useState<string | null>(null)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setError(null)
    try {
      await create.mutateAsync({
        email: email.trim(),
        password,
        full_name: fullName.trim() || undefined,
        role,
        // Only a service worker carries a department; the API rejects one on
        // any other role.
        department: role === 'service' ? department : null,
      } satisfies Parameters<typeof create.mutateAsync>[0])
      onOpenChange(false)
      setEmail('')
      setFullName('')
      setPassword('')
    } catch (caught) {
      const apiError =
        caught instanceof ApiError
          ? caught
          : toApiError(caught, t('staffGenericError'))
      setError(apiError.message)
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 z-40 bg-ink/25 backdrop-blur-sm" />
        {/* Opaque: a dialog is a surface in front of the page, not a tint
            over it. */}
        <Dialog.Content className="fixed top-1/2 left-1/2 z-40 max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-xl bg-surface p-5 shadow-[var(--shadow-raised)] sm:p-7">
          <Dialog.Title className="text-[19px] font-semibold tracking-tight text-ink">
            {t('staffCreateTitle')}
          </Dialog.Title>

          <form onSubmit={onSubmit} className="mt-5 space-y-4">
            {/* Labels name the field; the hint strings show the shape of the
                answer inside it. */}
            <Field
              label={t('fieldFullName')}
              placeholder={t('staffNameHint')}
              value={fullName}
              onChange={(event) => setFullName(event.target.value)}
            />
            <Field
              label={t('fieldEmail')}
              placeholder={t('staffEmailHint')}
              type="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
            <PasswordField
              label={t('fieldPassword')}
              placeholder={t('staffPasswordHint')}
              required
              minLength={8}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />

            <Select
              label={t('fieldRole')}
              value={role}
              onChange={(event) => setRole(event.target.value as UserRole)}
            >
              {USER_ROLES.map((value) => (
                <option key={value} value={value}>
                  {roleLabel(t, value)}
                </option>
              ))}
            </Select>

            {role === 'service' ? (
              <Select
                label={t('colDepartment')}
                value={department}
                onChange={(event) =>
                  setDepartment(event.target.value as Department)
                }
              >
                {WORKER_DEPARTMENTS.map((value) => (
                  <option key={value} value={value}>
                    {departmentLabel(t, value)}
                  </option>
                ))}
              </Select>
            ) : null}

            {error ? <ErrorState message={error} /> : null}

            <div className="flex justify-end gap-2 pt-2">
              <Dialog.Close asChild>
                <Button variant="ghost">{t('actionCancel')}</Button>
              </Dialog.Close>
              <Button type="submit" isLoading={create.isPending}>
                {t('staffCreateButton')}
              </Button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}

export type { User }
