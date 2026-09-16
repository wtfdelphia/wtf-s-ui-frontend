<template>
  <v-dialog transition="dialog-bottom-transition" width="560">
    <v-card class="rounded-lg" :loading="loading">
      <v-card-title>{{ $t('actions.' + (form.id ? 'edit' : 'add')) + ' ' + $t('objects.server') }}</v-card-title>
      <v-divider></v-divider>
      <v-card-text>
        <v-container style="padding: 0;">
          <v-row>
            <v-col cols="12">
              <v-text-field
                :label="$t('server.name')"
                v-model="form.name"
                hide-details>
              </v-text-field>
            </v-col>
            <v-col cols="12">
              <v-text-field
                :label="$t('server.url')"
                :hint="$t('server.urlHint')"
                persistent-hint
                v-model="form.url"
                placeholder="http://1.2.3.4:2095/path/">
              </v-text-field>
            </v-col>
            <v-col cols="12">
              <v-text-field
                :label="$t('server.token')"
                :hint="$t('server.tokenHint')"
                persistent-hint
                :type="showPass ? 'text' : 'password'"
                :append-inner-icon="showPass ? 'mdi-eye-off' : 'mdi-eye'"
                @click:append-inner="showPass = !showPass"
                v-model="form.token">
              </v-text-field>
            </v-col>
            <v-col cols="12">
              <v-text-field
                :label="$t('server.remark')"
                v-model="form.remark"
                hide-details>
              </v-text-field>
            </v-col>
          </v-row>
        </v-container>
      </v-card-text>
      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn color="primary" variant="outlined" @click="closeModal">{{ $t('actions.close') }}</v-btn>
        <v-btn color="primary" variant="tonal" :loading="loading" @click="save">{{ $t('actions.save') }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script lang="ts">
import Data from '@/store/modules/data'
import { i18n } from '@/locales'
import { push } from 'notivue'

export default {
  props: ['visible', 'server'],
  emits: ['close'],
  data() {
    return {
      loading: false,
      showPass: false,
      form: { id: 0, name: '', url: '', token: '', remark: '' },
    }
  },
  watch: {
    visible(v: boolean) {
      if (v) {
        const s = this.$props.server
        this.form = s
          ? { id: s.id, name: s.name, url: s.url, token: s.token ?? '', remark: s.remark }
          : { id: 0, name: '', url: '', token: '', remark: '' }
        this.showPass = false
        this.loading = false
      }
    },
  },
  methods: {
    closeModal() {
      this.$emit('close')
    },
    normalizeUrl(u: string): string {
      u = (u || '').trim()
      if (u && !/^https?:\/\//i.test(u)) u = 'http://' + u
      return u
    },
    async save() {
      const name = (this.form.name || '').trim()
      const url = this.normalizeUrl(this.form.url)
      if (!name || !url) {
        push.error({ message: i18n.global.t('error.invalidData') + ': ' + i18n.global.t('server.url') })
        return
      }
      this.loading = true
      const payload: any = {
        name,
        url,
        token: (this.form.token || '').trim(),
        remark: (this.form.remark || '').trim(),
      }
      if (this.form.id) payload.id = this.form.id
      const success = await Data().save('servers', this.form.id ? 'edit' : 'new', payload)
      this.loading = false
      if (success) this.closeModal()
    },
  },
}
</script>
