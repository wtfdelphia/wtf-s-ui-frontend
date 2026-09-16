<template>
  <InboundVue 
    :id="modal.id"
    v-model="modal.visible"
    :visible="modal.visible"
    :in-tags="inTags"
    :tls-configs="tlsConfigs"
    @close="closeModal"
  />
  <Stats
    v-model="stats.visible"
    :visible="stats.visible"
    :resource="stats.resource"
    :tag="stats.tag"
    @close="closeStats"
  />
  <Sessions
    v-model="sessions.visible"
    :visible="sessions.visible"
    resource="inbound"
    :tag="sessions.tag"
    @close="closeSessions"
  />
  <QuickTemplate
    v-model="templateModal"
    :visible="templateModal"
    @close="closeTemplate"
  />
  <ExportLinks
    v-model="exportModal"
    :visible="exportModal"
    @close="exportModal = false"
  />
  <QrCode
    v-model="qrcode.visible"
    :visible="qrcode.visible"
    :id="qrcode.id"
    @close="qrcode.visible = false"
  />
  <v-dialog v-model="clearConfirm" width="380">
    <v-card class="rounded-lg" :title="$t('quickTemplate.clearAll')">
      <v-divider></v-divider>
      <v-card-text>{{ $t('quickTemplate.clearAllConfirm') }}</v-card-text>
      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn color="success" variant="outlined" @click="clearConfirm = false">{{ $t('no') }}</v-btn>
        <v-btn color="error" variant="tonal" :loading="clearLoading" @click="delAllInbounds">{{ $t('yes') }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
  <v-dialog v-model="picker.visible" width="320">
    <v-card class="rounded-lg" :title="$t('pages.clients')">
      <v-divider></v-divider>
      <v-list density="compact" nav>
        <v-list-item v-for="c in picker.clients" :key="c.id" link @click="pickClient(c.id)">
          <template v-slot:prepend><v-icon icon="mdi-qrcode"></v-icon></template>
          <v-list-item-title>{{ c.name }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-card>
  </v-dialog>
  <v-row>
    <v-col cols="12" justify="center" align="center">
      <v-btn color="primary" @click="showModal(0)">{{ $t('actions.add') }}</v-btn>
      <v-btn color="primary" variant="tonal" class="ms-2" prepend-icon="mdi-flash" @click="templateModal = true">
        {{ $t('quickTemplate.btn') }}
      </v-btn>
      <v-btn color="primary" variant="tonal" class="ms-2" prepend-icon="mdi-export-variant" @click="exportModal = true">
        {{ $t('exportLinks.btn') }}
      </v-btn>
      <v-btn v-if="inbounds.length > 0" color="error" variant="tonal" class="ms-2" prepend-icon="mdi-delete-sweep" :loading="clearLoading" @click="clearConfirm = true">
        {{ $t('quickTemplate.clearAll') }}
      </v-btn>
    </v-col>
  </v-row>
  <v-row>
    <v-col
      v-for="(item, index) in <any[]>inbounds"
      :key="item.tag"
      cols="12"
      sm="4"
      md="3"
      lg="2"
    >
      <v-card
        rounded="xl"
        elevation="5"
        min-width="200"
        :title="item.tag"
      >
        <v-card-subtitle style="margin-top: -15px;">
          <v-row>
            <v-col>{{ item.type }}</v-col>
          </v-row>
        </v-card-subtitle>
        <v-card-text>
          <v-row>
            <v-col>{{ $t('in.addr') }}</v-col>
            <v-col>
              {{ item.listen }}
            </v-col>
          </v-row>
          <v-row>
            <v-col>{{ $t('in.port') }}</v-col>
            <v-col>
              {{ item.listen_port }}
            </v-col>
          </v-row>
          <v-row>
            <v-col>{{ $t('objects.tls') }}</v-col>
            <v-col>
              {{ item.tls_id > 0 ? $t('enable') : $t('disable') }}
            </v-col>
          </v-row>
          <v-row>
            <v-col>{{ $t('pages.clients') }}</v-col>
            <v-col>
              <template v-if="item.users">
                <v-tooltip
                  v-if="item.users.length > 0"
                  activator="parent"
                  dir="ltr"
                  location="bottom"
                >
                  <span
                    v-for="u in item.users"
                    :key="u"
                  >{{ u }}<br></span>
                </v-tooltip>
                {{ item.users.length }}
              </template>
              <template v-else>
                -
              </template>
            </v-col>
          </v-row>
          <v-row>
            <v-col>{{ $t('online') }}</v-col>
            <v-col>
              <template v-if="onlines.includes(item.tag)">
                <v-chip
                  density="comfortable"
                  size="small"
                  color="success"
                  variant="flat"
                  link
                  @click="showSessions(item.tag)"
                >
                  {{ $t('online') }}
                  <v-tooltip
                    activator="parent"
                    location="top"
                    :text="$t('sessions.title')"
                  />
                </v-chip>
              </template>
              <template v-else>
                -
              </template>
            </v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions style="padding: 0;">
          <v-btn
            icon="mdi-file-edit"
            @click="showModal(item.id)"
          >
            <v-icon />
            <v-tooltip
              activator="parent"
              location="top"
              :text="$t('actions.edit')"
            />
          </v-btn>
          <v-btn
            icon="mdi-file-remove"
            style="margin-inline-start:0;"
            color="warning"
            @click="delOverlay[index] = true"
          >
            <v-icon />
            <v-tooltip
              activator="parent"
              location="top"
              :text="$t('actions.del')"
            />
          </v-btn>
          <v-overlay
            v-model="delOverlay[index]"
            contained
            class="align-center justify-center"
          >
            <v-card
              :title="$t('actions.del')"
              rounded="lg"
            >
              <v-divider />
              <v-card-text>{{ $t('confirm') }}</v-card-text>
              <v-card-actions>
                <v-btn
                  color="error"
                  variant="outlined"
                  @click="delInbound(item.id)"
                >
                  {{ $t('yes') }}
                </v-btn>
                <v-btn
                  color="success"
                  variant="outlined"
                  @click="delOverlay[index] = false"
                >
                  {{ $t('no') }}
                </v-btn>
              </v-card-actions>
            </v-card>
          </v-overlay>
          <v-btn
            icon="mdi-content-duplicate"
            :loading="cloneLoading"
            @click="clone(item.id)"
          >
            <v-icon />
            <v-tooltip
              activator="parent"
              location="top"
              :text="$t('actions.clone')"
            />
          </v-btn>
          <v-btn icon="mdi-qrcode" v-if="item.users && item.users.length > 0" @click="showInboundQr(item)">
            <v-icon />
            <v-tooltip activator="parent" location="top" :text="$t('client.links')"></v-tooltip>
          </v-btn>
          <v-btn icon="mdi-chart-line" @click="showStats(item.tag)" v-if="Data().enableTraffic">
            <v-icon />
            <v-tooltip
              activator="parent"
              location="top"
              :text="$t('stats.graphTitle')"
            />
          </v-btn>
        </v-card-actions>
      </v-card>      
    </v-col>
  </v-row>
</template>

<script lang="ts" setup>
import Data from '@/store/modules/data'
import InboundVue from '@/layouts/modals/Inbound.vue'
import QuickTemplate from '@/layouts/modals/QuickTemplate.vue'
import QrCode from '@/layouts/modals/QrCode.vue'
import ExportLinks from '@/layouts/modals/ExportLinks.vue'
import Stats from '@/layouts/modals/Stats.vue'
import Sessions from '@/layouts/modals/Sessions.vue'
import { computed, ref } from 'vue'
import { createInbound, Inbound } from '@/types/inbounds'
import { tls } from '@/types/tls'
import RandomUtil from '@/plugins/randomUtil'

const inbounds = computed((): Inbound[] => {
  return <Inbound[]> Data().inbounds
})

const tlsConfigs = computed((): tls[] => {
  return Data().tlsConfigs
})

const inTags = computed((): string[] => {
  return [...(inbounds.value?.map(i => i.tag) ?? []), ...(Data().endpoints?.filter(e => e.listen_port > 0).map(e => e.tag) ?? [])]
})

const onlines = computed(() => {
  return Data().onlines.inbound?? []
})

const modal = ref({
  visible: false,
  id: 0,
})

const templateModal = ref(false)
const closeTemplate = () => {
  templateModal.value = false
}

const exportModal = ref(false)

const clearConfirm = ref(false)
const clearLoading = ref(false)
const delAllInbounds = async () => {
  clearLoading.value = true
  const tags = inbounds.value.map(i => i.tag)
  for (const tag of tags) {
    await Data().save("inbounds", "del", tag)
  }
  clearLoading.value = false
  clearConfirm.value = false
}

const qrcode = ref({
  visible: false,
  id: 0,
})

// QR access straight from an inbound card. One client -> show its QR directly;
// several -> let the user pick which one.
const picker = ref({
  visible: false,
  clients: <any[]>[],
})
const clientsOf = (item: any): any[] => {
  return Data().clients.filter((c: any) => Array.isArray(c.inbounds) && c.inbounds.includes(item.id))
}
const showInboundQr = (item: any) => {
  const cls = clientsOf(item)
  if (cls.length === 0) return
  if (cls.length === 1) {
    qrcode.value.id = cls[0].id
    qrcode.value.visible = true
    return
  }
  picker.value.clients = cls
  picker.value.visible = true
}
const pickClient = (id: number) => {
  picker.value.visible = false
  qrcode.value.id = id
  qrcode.value.visible = true
}

let delOverlay = ref(new Array<boolean>)

const showModal = (id: number) => {
  modal.value.id = id
  modal.value.visible = true
}
const closeModal = () => {
  modal.value.visible = false
}

const delInbound = async (id: number) => {
  const index = inbounds.value.findIndex(i => i.id == id)
  const tag = inbounds.value[index].tag

  const success = await Data().save("inbounds", "del", tag)
  if (success) delOverlay.value[index] = false
}

let cloneLoading = ref(false)

const clone = async (id: number) => {
  cloneLoading.value = true
  const inboundArray = await Data().loadInbounds([id])
  const inbound = inboundArray[0]
  let newTag = inbound.type + "-" + RandomUtil.randomSeq(3)
  const newInbound = createInbound(inbound.type, { ...inbound,
    id: 0,
    tag: newTag,
    listen_port: RandomUtil.randomIntRange(10000, 60000),
  })
  await Data().save("inbounds", "new", newInbound)
  cloneLoading.value = false
}

const stats = ref({
  visible: false,
  resource: "inbound",
  tag: "",
})

const showStats = (tag: string) => {
  stats.value.tag = tag
  stats.value.visible = true
}
const closeStats = () => {
  stats.value.visible = false
}

const sessions = ref({
  visible: false,
  tag: "",
})

const showSessions = (tag: string) => {
  sessions.value.tag = tag
  sessions.value.visible = true
}
const closeSessions = () => {
  sessions.value.visible = false
}
</script>
