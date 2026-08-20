import {
  useMutation,
  useQuery,
  useQueryClient,
} from '@tanstack/react-query'

import * as api from '../api/endpoints'
import type {
  BusCreateBody,
  BusUpdateBody,
  CreateUserBody,
  DefectStatus,
  DefectType,
  UpdateUserBody,
} from '../types'

export const keys = {
  defects: ['defects'] as const,
  defect: (id: string) => ['defects', id] as const,
  users: ['users'] as const,
  buses: (includeInactive: boolean) => ['buses', includeInactive] as const,
}

export function useDefects() {
  return useQuery({ queryKey: keys.defects, queryFn: api.fetchDefects })
}

export function useDefect(id: string) {
  return useQuery({
    queryKey: keys.defect(id),
    queryFn: () => api.fetchDefect(id),
  })
}

export function useUsers(enabled = true) {
  return useQuery({
    queryKey: keys.users,
    queryFn: api.fetchUsers,
    enabled,
  })
}

/**
 * Every defect mutation invalidates the whole defect cache: a claim or a
 * status change alters the row *and* the detail view, and on this client the
 * two are often on screen together.
 */
function useDefectMutation<TArgs>(mutationFn: (args: TArgs) => Promise<unknown>) {
  const client = useQueryClient()
  return useMutation({
    mutationFn,
    onSuccess: () => {
      void client.invalidateQueries({ queryKey: keys.defects })
    },
  })
}

export function useClaimDefect() {
  return useDefectMutation((id: string) => api.claimDefect(id))
}

export function useReleaseDefect() {
  return useDefectMutation((id: string) => api.releaseDefect(id))
}

export function useUpdateStatus() {
  return useDefectMutation(
    (args: { id: string; status: DefectStatus; note?: string }) =>
      api.updateDefectStatus(args.id, args.status, args.note),
  )
}

export function useReclassify() {
  return useDefectMutation((args: { id: string; type: DefectType }) =>
    api.reclassifyDefect(args.id, args.type),
  )
}

function useUserMutation<TArgs>(mutationFn: (args: TArgs) => Promise<unknown>) {
  const client = useQueryClient()
  return useMutation({
    mutationFn,
    onSuccess: () => {
      void client.invalidateQueries({ queryKey: keys.users })
    },
  })
}

export function useCreateUser() {
  return useUserMutation((body: CreateUserBody) => api.createUser(body))
}

export function useUpdateUser() {
  return useUserMutation((args: { id: string; body: UpdateUserBody }) =>
    api.updateUser(args.id, args.body),
  )
}

export function useDeleteUser() {
  return useUserMutation((id: string) => api.deleteUser(id))
}

export function useBuses(includeInactive = false) {
  return useQuery({
    queryKey: keys.buses(includeInactive),
    queryFn: () => api.fetchBuses(includeInactive),
    // The fleet changes when a bus is bought or retired, not by the minute.
    staleTime: 5 * 60_000,
  })
}

function useBusMutation<TArgs>(mutationFn: (args: TArgs) => Promise<unknown>) {
  const client = useQueryClient()
  return useMutation({
    mutationFn,
    onSuccess: () => {
      void client.invalidateQueries({ queryKey: ['buses'] })
    },
  })
}

export function useCreateBus() {
  return useBusMutation((body: BusCreateBody) => api.createBus(body))
}

export function useUpdateBus() {
  return useBusMutation((args: { id: string; body: BusUpdateBody }) =>
    api.updateBus(args.id, args.body),
  )
}

export function useDeleteBus() {
  return useBusMutation((id: string) => api.deleteBus(id))
}
