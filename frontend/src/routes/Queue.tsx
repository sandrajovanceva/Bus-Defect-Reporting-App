import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { useAuth } from '../auth/AuthContext'
import { DefectTable } from '../components/DefectTable'
import { Button, ErrorState, LoadingState, Panel } from '../components/ui'
import { useClaimDefect, useDefects } from '../hooks/queries'
import { departmentLabel, isClaimable } from '../lib/domain'

type Tab = 'queue' | 'mine'

/**
 * The service worker's bench: what is waiting for their department, and what
 * they have picked up. The backend already scopes the list by department, so
 * this only splits it in two.
 */
export function Queue() {
  const { t } = useTranslation()
  const { user } = useAuth()
  const [tab, setTab] = useState<Tab>('queue')

  const { data, isPending, error } = useDefects()
  const claim = useClaimDefect()

  const { queue, mine } = useMemo(() => {
    const all = data ?? []
    return {
      queue: all.filter(isClaimable),
      mine: all.filter((d) => d.assigned_to_id === user?.id),
    }
  }, [data, user?.id])

  if (!user?.department) {
    return (
      <div className="p-4 sm:p-7">
        <Panel className="p-10 text-center text-[15px] text-ink-2">
          {t('serviceNoDepartment')}
        </Panel>
      </div>
    )
  }

  const rows = tab === 'queue' ? queue : mine

  return (
    <div className="p-4 sm:p-7">
      <div className="mb-6 flex flex-wrap items-center gap-4">
        <p className="text-[14px] text-ink-2">
          {t('labelDepartment')}:{' '}
          <span className="font-medium text-ink">
            {departmentLabel(t, user.department)}
          </span>
        </p>
        <div className="ml-auto flex gap-1 rounded-md bg-black/[0.05] p-1">
          <TabButton
            isActive={tab === 'queue'}
            onClick={() => setTab('queue')}
            label={t('serviceTabQueue')}
            count={queue.length}
          />
          <TabButton
            isActive={tab === 'mine'}
            onClick={() => setTab('mine')}
            label={t('serviceTabMine')}
            count={mine.length}
          />
        </div>
      </div>

      {claim.error ? (
        <div className="mb-4">
          <ErrorState message={t('staffGenericError')} />
        </div>
      ) : null}

      <Panel className="overflow-hidden">
        {isPending ? (
          <LoadingState />
        ) : error ? (
          <div className="p-4">
            <ErrorState message={error.message} />
          </div>
        ) : (
          <DefectTable
            defects={rows}
            showAssignee={tab === 'mine'}
            emptyTitle={
              tab === 'queue' ? t('serviceQueueEmpty') : t('serviceMineEmpty')
            }
            renderAction={
              tab === 'queue'
                ? (defect) => (
                    <Button
                      variant="secondary"
                      size="sm"
                      isLoading={
                        claim.isPending && claim.variables === defect.id
                      }
                      onClick={() => claim.mutate(defect.id)}
                    >
                      {t('serviceClaim')}
                    </Button>
                  )
                : undefined
            }
          />
        )}
      </Panel>
    </div>
  )
}

function TabButton({
  isActive,
  onClick,
  label,
  count,
}: {
  isActive: boolean
  onClick: () => void
  label: string
  count: number
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={isActive}
      className={
        'rounded-sm px-4 py-1.5 text-[14px] font-medium transition-all ' +
        (isActive
          ? 'bg-surface text-ink shadow-sm'
          : 'text-ink-2 hover:text-ink')
      }
    >
      {label} {count}
    </button>
  )
}
