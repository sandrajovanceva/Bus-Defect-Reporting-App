import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'

import en from './en.json'
import mk from './mk.json'

const STORAGE_KEY = 'jsp.lang'

export const LANGUAGES = [
  { code: 'mk', labelKey: 'languageMacedonian' },
  { code: 'en', labelKey: 'languageEnglish' },
] as const

export type LanguageCode = (typeof LANGUAGES)[number]['code']

function initialLanguage(): LanguageCode {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored === 'mk' || stored === 'en') return stored
  // Macedonian is the working language at the depot; English is the fallback.
  return navigator.language.startsWith('en') ? 'en' : 'mk'
}

void i18n.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    mk: { translation: mk },
  },
  lng: initialLanguage(),
  fallbackLng: 'mk',
  interpolation: { escapeValue: false },
})

export function setLanguage(code: LanguageCode) {
  localStorage.setItem(STORAGE_KEY, code)
  document.documentElement.lang = code
  void i18n.changeLanguage(code)
}

document.documentElement.lang = i18n.language

export default i18n
