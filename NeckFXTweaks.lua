local state = {
  status = 'Loaded'
}

function script.windowMain(dt)
  ui.text('Neck FX Tweaks')
  ui.separator()
  ui.text('App is running.')
  ui.text('Status: ' .. state.status)
end