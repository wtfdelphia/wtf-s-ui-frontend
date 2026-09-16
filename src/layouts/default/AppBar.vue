<template>
  <v-app-bar :elevation="5">
    <v-icon v-if="isMobile" icon="mdi-menu" @click="$emit('toggleDrawer')" />
    <span v-else style="width: 24px"></span>
    <v-app-bar-title :text="$t(<string>route.name)" class="align-center text-center " />
    <!-- A stopped core is invisible from the panel otherwise, and the flag
         survives a reboot, so it has to be said on every page. -->
    <v-chip
      v-if="maintenance"
      v-tooltip="$t('setting.maintenanceOnHint')"
      color="warning"
      variant="flat"
      density="comfortable"
      prepend-icon="mdi-wrench"
      class="mr-2"
    >
      {{ $t('setting.maintenance') }}
    </v-chip>
    <v-menu v-if="servers.length > 0 || currentServer">
      <template v-slot:activator="{ props }">
        <v-btn v-bind="props" variant="tonal" size="small" class="me-1"
          :color="currentServer ? 'warning' : 'primary'"
          prepend-icon="mdi-server-network">
          {{ currentServerName || $t('server.local') }}
        </v-btn>
      </template>
      <v-list density="compact" nav>
        <v-list-item @click="selectServer('')" :active="currentServer === ''">
          <template v-slot:prepend><v-icon icon="mdi-home"></v-icon></template>
          <v-list-item-title>{{ $t('server.local') }}</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>
        <v-list-item v-for="s in servers" :key="s.id" @click="selectServer(String(s.id))" :active="currentServer === String(s.id)">
          <template v-slot:prepend><v-icon icon="mdi-server"></v-icon></template>
          <v-list-item-title>{{ s.name }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-menu>
    <v-menu>
      <template v-slot:activator="{ props }">
        <v-btn icon v-bind="props">
          <v-icon>mdi-translate</v-icon>
        </v-btn>
      </template>
      <v-list>
        <v-list-item
          v-for="lang in languages"
          :key="lang.value"
          @click="changeLocale(lang.value)"
          :active="isActiveLocale(lang.value)"
        >
          <v-list-item-title>{{ lang.title }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-menu>
    <v-menu>
      <template v-slot:activator="{ props }">
        <v-btn icon v-bind="props">
          <v-icon>mdi-palette</v-icon>
        </v-btn>
      </template>
      <v-list density="compact">
        <v-list-item
          v-for="sk in skins"
          :key="sk.id"
          @click="changeSkin(sk.id)"
          :active="currentSkin === sk.id"
        >
          <template v-slot:prepend>
            <span class="skin-swatch" :style="{ backgroundImage: sk.swatch }"></span>
          </template>
          <v-list-item-title>{{ $t(`skin.${sk.id}`) }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-menu>
    <v-btn
      v-tooltip="$t('donate')"
      icon
      variant="text"
      href="https://donate.alireza0.dev"
      target="_blank"
      rel="noopener"
      class="donate-btn"
    >
      <v-icon
        icon="mdi-heart"
        color="red"
        size="1.5em"
      />
    </v-btn>
  </v-app-bar>
</template>

<script lang="ts" setup>
import { useLocale, useTheme } from 'vuetify'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { computed, ref } from 'vue'
import { languages } from '@/locales'
import Data from '@/store/modules/data'
import { SKINS, savedSkin, applySkinAttr, type SkinId } from '@/plugins/skins'

defineProps<{ isMobile: boolean }>()
defineEmits<{ toggleDrawer: [] }>()

const servers = computed((): any[] => Data().servers ?? [])
const currentServer = computed((): string => Data().currentServer)
const currentServerName = computed((): string => {
  const id = Data().currentServer
  if (!id) return ''
  const s = (Data().servers || []).find((x: any) => String(x.id) === id)
  return s?.name ?? id
})
const selectServer = (id: string) => Data().setCurrentServer(id)

const route = useRoute()
const { locale: i18nLocale } = useI18n()
const vuetifyLocale = useLocale()
const theme = useTheme()

const changeLocale = (l: string) => {
  i18nLocale.value = l
  vuetifyLocale.current.value = l
  localStorage.setItem('locale', l)
  window.location.reload()
}
const isActiveLocale = (l: string) => i18nLocale.value === l

const maintenance = computed((): boolean => Data().maintenance)

// Gradient skins replace the old light/dark/system toggle: each skin carries
// its own base theme, so picking one sets both the gradient and the contrast.
const skins = SKINS
const currentSkin = ref<SkinId>(savedSkin().id)
const changeSkin = (id: SkinId) => {
  const sk = SKINS.find((s) => s.id === id)!
  theme.change(sk.base)
  applySkinAttr(id)
  localStorage.setItem('skin', id)
  currentSkin.value = id
}
</script>

<style scoped>
.skin-swatch {
  display: inline-block;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  margin-inline-end: 10px;
  border: 1px solid rgba(128, 128, 128, 0.45);
}
</style>
