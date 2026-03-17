local cfg = {
  enabled = true,
  xboxStick = 1,          -- -1 disabled, 0 left, 1 right
  deadzone = 0.03,
  exponent = 1.8,
  filterSpeed = 10,
  topSpeed = 400
}

local stickLabels = {
  [-1] = 'Disabled',
  [0] = 'Left Stick',
  [1] = 'Right Stick'
}

function script.windowMain(dt)
  ui.text('Neck FX Tweaks')
  ui.separator()

  local changed

  changed, cfg.enabled = ui.checkbox('Enable Neck FX', cfg.enabled)

  ui.text('Look stick')
  if ui.button('Disabled') then cfg.xboxStick = -1 end
  ui.sameLine()
  if ui.button('Left') then cfg.xboxStick = 0 end
  ui.sameLine()
  if ui.button('Right') then cfg.xboxStick = 1 end
  ui.text('Current: ' .. stickLabels[cfg.xboxStick])

  changed, cfg.deadzone = ui.slider('Deadzone', cfg.deadzone, 0.01, 0.99, '%.2f')
  changed, cfg.exponent = ui.slider('Exponent', cfg.exponent, 0.2, 5.0, '%.2f')
  changed, cfg.filterSpeed = ui.slider('Filter Speed', cfg.filterSpeed, 1, 30, '%.0f')
  changed, cfg.topSpeed = ui.slider('Top Speed', cfg.topSpeed, 100, 800, '%.0f')

  ui.separator()
  ui.text('Preview')
  ui.text(string.format('Enabled: %s', tostring(cfg.enabled)))
  ui.text(string.format('Stick: %s', stickLabels[cfg.xboxStick]))
  ui.text(string.format('Deadzone: %.2f', cfg.deadzone))
  ui.text(string.format('Exponent: %.2f', cfg.exponent))
  ui.text(string.format('Filter: %.0f', cfg.filterSpeed))
  ui.text(string.format('Top speed: %.0f', cfg.topSpeed))
end