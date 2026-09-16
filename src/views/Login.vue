<template>
  <v-app>
    <v-container class="fill-height" style="margin-top: 100px;">
      <v-row justify="center" align="center">
        <v-col cols="12" sm="8" md="4">
          <v-card>
            <v-card-title class="headline" v-text="$t('login.title')"></v-card-title>
            <v-card-text>
              <v-form @submit.prevent="login" ref="form">
                <v-text-field v-model="username" :label="$t('login.username')" :rules="usernameRules" required></v-text-field>
                <v-text-field v-model="password" :label="$t('login.password')" :rules="passwordRules" type="password" required></v-text-field>
                <v-btn :loading="loading" type="submit" color="primary" block class="mt-2" v-text="$t('actions.submit')"></v-btn>
              </v-form>
              <v-select
                density="compact"
                class="mt-2"
                hide-details
                variant="solo"
                :items="languages"
                v-model="$i18n.locale"
                @update:modelValue="changeLocale">
                <template v-slot:append>
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
                </template>
              </v-select>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-container>
  </v-app>
</template>

<script lang="ts" setup>
import { ref } from "vue"
import { useLocale, useTheme } from 'vuetify'
import { i18n, languages } from '@/locales'
import { useRouter } from 'vue-router'
import HttpUtil from '@/plugins/httputil'
import { setAuthenticated } from '@/plugins/auth'
import { SKINS, savedSkin, applySkinAttr, type SkinId } from '@/plugins/skins'


const theme = useTheme()
const locale = useLocale()

// Same gradient-skin picker as the in-panel app bar, so the login screen shows
// the chosen skin (default Aurora) and stays in sync with the rest of the UI.
const skins = SKINS
const currentSkin = ref<SkinId>(savedSkin().id)

const username = ref('')
const usernameRules = [
  (value: string) => {
    if (value?.length > 0) return true
    return i18n.global.t('login.unRules')
  },
]

const password = ref('')
const passwordRules = [
  (value: string) => {
    if (value?.length > 0) return true
    return i18n.global.t('login.pwRules')
  },
]

const loading = ref(false)
const router = useRouter()

const login = async () => {
  if (username.value == '' || password.value == '') return
  loading.value=true
  const response = await HttpUtil.post('api/login',{user: username.value, pass: password.value})
  if(response.success){
    setAuthenticated()
    setTimeout(() => {
      loading.value=false
      router.push('/')
    }, 500)
  } else {
    loading.value=false
  }
}
const changeLocale = (l: string | null) => {
  locale.current.value = l ?? 'en'
  localStorage.setItem('locale', locale.current.value)
}
const changeSkin = (id: SkinId) => {
  const sk = SKINS.find((s) => s.id === id)!
  theme.change(sk.base)
  applySkinAttr(id)
  localStorage.setItem('skin', id)
  currentSkin.value = id
}
</script>

<style>
.v-overlay .v-list-item,
.v-field__input {
  direction: ltr;
}
.skin-swatch {
  display: inline-block;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  margin-inline-end: 10px;
  border: 1px solid rgba(128, 128, 128, 0.45);
}
</style>
