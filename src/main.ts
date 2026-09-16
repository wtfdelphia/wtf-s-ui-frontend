/**
 * main.ts
 *
 * Bootstraps Vuetify and other plugins then mounts the App`
 */

// Composables
import { createApp, ref } from 'vue'

// Components
import App from './App.vue'

// Use router
import router from './router'

// Store
import store from './store'

// Plugins
import { registerPlugins } from '@/plugins'

// Gradient skins
import '@/styles/skins.css'
import { savedSkin, applySkinAttr } from '@/plugins/skins'

// Locale
import { i18n } from '@/locales'
import Vue3PersianDatetimePicker from 'vue3-persian-datetime-picker'

// Notivue
import { createNotivue } from 'notivue'
import 'notivue/notification.css'
import 'notivue/animations.css'
const notivue = createNotivue({
  position: 'bottom-center',
  limit: 4,
  enqueue: false,
  avoidDuplicates: true,
  notifications: {
    global: {
      duration: 3000
    }
  },
})

const loading = ref(false)

// Paint the saved gradient skin onto <html> before the app mounts.
applySkinAttr(savedSkin().id)

const app = createApp(App)
app.provide('loading', loading)

registerPlugins(app)

app
  .use(router)
  .use(store)
  .use(i18n)
  .use(notivue)
  .component('DatePicker', Vue3PersianDatetimePicker)
  .mount('#app')
