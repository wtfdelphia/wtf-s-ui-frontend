<template>
  <ServerEdit
    v-model="editModal.visible"
    :visible="editModal.visible"
    :server="editModal.server"
    @close="closeEdit"
  />
  <v-row justify="center" align="center">
    <v-col cols="auto">
      <v-btn color="primary" prepend-icon="mdi-server-plus" @click="showEdit(null)">{{ $t('server.add') }}</v-btn>
    </v-col>
  </v-row>
  <v-row v-if="servers.length === 0">
    <v-col cols="12" style="text-align: center; opacity: 0.6; margin-top: 30px;">{{ $t('server.empty') }}</v-col>
  </v-row>
  <v-row>
    <v-col cols="12" sm="6" md="4" lg="3" v-for="(item, index) in servers" :key="item.id">
      <v-card rounded="xl" elevation="5" min-width="200" :title="item.name"
        :color="currentServer === String(item.id) ? 'primary' : undefined">
        <v-card-subtitle style="margin-top: -15px; overflow-wrap: anywhere;">{{ item.url }}</v-card-subtitle>
        <v-card-text>
          <div style="margin-bottom: 6px;">
            <v-chip v-if="st(item).state === 'testing'" size="small" color="grey" variant="tonal">
              <v-progress-circular size="12" width="2" indeterminate class="mr-1" />{{ $t('server.testing') }}
            </v-chip>
            <v-chip v-else-if="st(item).state === 'online'" size="small" color="success" variant="tonal" prepend-icon="mdi-check-circle">
              {{ st(item).latency }} ms
            </v-chip>
            <v-chip v-else-if="st(item).state === 'offline'" size="small" color="error" variant="tonal" prepend-icon="mdi-alert-circle">
              {{ $t('server.offline') }}
            </v-chip>
          </div>
          <div v-if="currentServer === String(item.id)" style="font-weight: bold;">● {{ $t('server.managing') }}</div>
          <div v-if="item.remark" style="opacity: 0.7;">{{ item.remark }}</div>
        </v-card-text>
        <v-divider></v-divider>
        <v-card-actions style="padding: 0;">
          <v-btn icon="mdi-lan-pending" @click.stop="testServer(item)">
            <v-icon />
            <v-tooltip activator="parent" location="top" :text="$t('server.test')"></v-tooltip>
          </v-btn>
          <v-btn icon="mdi-cog" color="primary" @click.stop="manage(item)">
            <v-icon />
            <v-tooltip activator="parent" location="top" :text="$t('server.manage')"></v-tooltip>
          </v-btn>
          <v-btn icon="mdi-file-edit" @click.stop="showEdit(item)">
            <v-icon />
            <v-tooltip activator="parent" location="top" :text="$t('actions.edit')"></v-tooltip>
          </v-btn>
          <v-btn icon="mdi-file-remove" color="warning" @click.stop="delOverlay[index] = true">
            <v-icon />
            <v-tooltip activator="parent" location="top" :text="$t('actions.del')"></v-tooltip>
          </v-btn>
          <v-overlay v-model="delOverlay[index]" contained class="align-center justify-center">
            <v-card :title="$t('actions.del')" rounded="lg">
              <v-divider></v-divider>
              <v-card-text>
                {{ $t('confirm') }}
                <v-checkbox v-model="wipeNodes[index]" :label="$t('server.wipeNodes')" density="compact" hide-details color="error" class="mt-2" />
              </v-card-text>
              <v-card-actions>
                <v-btn color="error" variant="outlined" @click.stop="delServer(item, index)">{{ $t('yes') }}</v-btn>
                <v-btn color="success" variant="outlined" @click.stop="delOverlay[index] = false">{{ $t('no') }}</v-btn>
              </v-card-actions>
            </v-card>
          </v-overlay>
        </v-card-actions>
      </v-card>
    </v-col>
  </v-row>
</template>

<script lang="ts" setup>
import Data from '@/store/modules/data'
import HttpUtils from '@/plugins/httputil'
import api from '@/plugins/api'
import ServerEdit from '@/layouts/modals/ServerEdit.vue'
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const servers = computed((): any[] => Data().servers ?? [])
const currentServer = computed((): string => Data().currentServer)

const editModal = ref<{ visible: boolean, server: any }>({ visible: false, server: null })
const delOverlay = ref<boolean[]>([])
const wipeNodes = ref<boolean[]>([])

type ServerStatus = { state: 'idle' | 'testing' | 'online' | 'offline', latency?: number, error?: string }
const statusMap = ref<Record<string, ServerStatus>>({})
const st = (item: any): ServerStatus => statusMap.value[item.id] || { state: 'idle' }

// Probe a server's reachability + token through the backend (it calls the
// remote APIv2 and times the round-trip).
const testServer = async (item: any) => {
  statusMap.value = { ...statusMap.value, [item.id]: { state: 'testing' } }
  const r = await HttpUtils.get('api/testServer', { id: item.id })
  const o: any = r.obj || {}
  statusMap.value = {
    ...statusMap.value,
    [item.id]: o.online
      ? { state: 'online', latency: o.latency }
      : { state: 'offline', error: o.error },
  }
}
const testAll = () => servers.value.forEach(testServer)

// Auto-test on load and whenever the list changes (e.g. after add/edit).
watch(servers, () => testAll(), { immediate: true })

const showEdit = (server: any) => {
  editModal.value.server = server
  editModal.value.visible = true
}
const closeEdit = () => {
  editModal.value.visible = false
}

// Switch the panel to manage this server, then jump to its inbounds.
const manage = (item: any) => {
  Data().setCurrentServer(String(item.id))
  router.push('/inbounds')
}

// Delete every inbound on a remote server, talking to it directly via the proxy
// header so the local view isn't overwritten with the remote's data. Opt-in only.
const wipeRemoteNodes = async (id: string) => {
  const resp = await api.get('api/inbounds', { headers: { 'X-Remote-Server': id } })
  const inbounds: any[] = resp.data?.obj?.inbounds ?? []
  for (const ib of inbounds) {
    await api.post('api/save',
      { object: 'inbounds', action: 'del', data: JSON.stringify(ib.id) },
      { headers: { 'X-Remote-Server': id } })
  }
}

const delServer = async (item: any, index: number) => {
  if (wipeNodes.value[index]) {
    // If the server is unreachable we can't clear its nodes — drop the entry anyway.
    try { await wipeRemoteNodes(String(item.id)) } catch { /* ignore */ }
  }
  const success = await Data().save('servers', 'del', item.id)
  if (success) {
    // If we just removed the server we were managing, fall back to the local
    // panel so subsequent api/load calls aren't proxied to a gone remote.
    if (String(item.id) === Data().currentServer) Data().setCurrentServer('')
    delOverlay.value[index] = false
    wipeNodes.value[index] = false
  }
}
</script>
