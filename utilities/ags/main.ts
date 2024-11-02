import { TopBar } from 'modules/bar'
import { Dock } from './modules/dock'

App.config({
  style: "./style.css",
  windows: [
    // TopBar(0),
    Dock()
  ],
})
