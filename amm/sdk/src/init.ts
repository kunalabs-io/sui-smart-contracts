import { structClassLoader } from 'framework/loader'
import * as framework from 'framework/init'
import * as amm from './amm/init'

let initialized = false

export function initLoaderIfNeeded() {
  if (initialized) {
    return
  }
  initialized = true

  framework.registerClasses(structClassLoader)
  amm.registerClasses(structClassLoader)
}
