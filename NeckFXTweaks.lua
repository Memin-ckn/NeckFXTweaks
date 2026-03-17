local NECK_INI_PATH = ac.getFolder(ac.FolderID.Root) .. '/extension/config/neck.ini'

local state = {
  ini = nil,
  loaded = false,
  status = 'Starting...'
}

local function log(msg)
  ac.log('[NeckFXTweaks] ' .. tostring(msg))
end

local function loadIni()
  state.ini = ac.INIConfig.load(NECK_INI_PATH)
  if state.ini then
    state.loaded = true
    state.status = 'Loaded: ' .. NECK_INI_PATH
    log('Loaded neck.ini: ' .. NECK_INI_PATH)
  else
    state.loaded = false
    state.status = 'Failed to load: ' .. NECK_INI_PATH
    log('Failed to load neck.ini: ' .. NECK_INI_PATH)
  end
end

local function ensureIni()
  if not state.ini then
    loadIni()
  end
  return state.ini ~= nil
end

local function getNumber(section, key, fallback)
  if not ensureIni() then return fallback end
  local v = state.ini:get(section, key, fallback)
  local n = tonumber(v)
  if n == nil then return fallback end
  return n
end

local function getBool(section, key, fallback)
  if not ensureIni() then return fallback end
  local v = tonumber(state.ini:get(section, key, fallback and 1 or 0))
  return v == 1
end

local function setValue(section, key, value)
  if not ensureIni() then return end
  state.ini:setAndSave(section, key, value)
  state.status = string.format('Saved: [%s] %s = %s', section, key, tostring(value))
  log(state.status)
end

local function drawStickSelector(current)
  ui.text('Look stick:')
  if ui.radioButton('Disabled##stick', current == -1) then
    setValue('LOOK', 'XBOX_STICK', -1)
    return -1
  end
  if ui.radioButton('Left##stick', current == 0) then
    setValue('LOOK', 'XBOX_STICK', 0)
    return 0
  end
  if ui.radioButton('Right##stick', current == 1) then
    setValue('LOOK', 'XBOX_STICK', 1)
    return 1
  end
  return current
end

function script.windowMain(dt)
  ui.pushFont(ui.Font.Small)

  if not state.loaded then
    loadIni()
  end

  ui.text('Neck FX Tweaks')
  ui.separator()
  ui.textWrapped(state.status)

  if not state.loaded then
    if ui.button('Retry loading') then
      loadIni()
    end
    ui.popFont()
    return
  end

  local enabled = getBool('BASIC', 'ENABLED', true)

  ui.separator()
  ui.text('Neck FX status: ' .. (enabled and 'Enabled' or 'Disabled'))
  ui.separator()

  if not enabled then
    ui.textWrapped('First, enable Neck FX.')
    if ui.button('Reload from file') then
      loadIni()
    end
    ui.popFont()
    return
  end

  local xboxStick = getNumber('LOOK', 'XBOX_STICK', 1)
  drawStickSelector(xboxStick)

  ui.separator()

  local deadzone = getNumber('LOOK', 'XBOX_STICK_DEADZONE', 0.03)
  deadzone = ui.slider('Deadzone', deadzone, 0.00, 0.30, '%.2f')
  if ui.itemEdited() then
    setValue('LOOK', 'XBOX_STICK_DEADZONE', string.format('%.2f', deadzone))
  end

  local exponent = getNumber('LOOK', 'XBOX_STICK_EXPONENT', 1.80)
  exponent = ui.slider('Exponent', exponent, 0.20, 5.00, '%.2f')
  if ui.itemEdited() then
    setValue('LOOK', 'XBOX_STICK_EXPONENT', string.format('%.2f', exponent))
  end

  local filterSpeed = getNumber('LOOK', 'FILTER_SPEED', 10)
  filterSpeed = ui.slider('Filter Speed', filterSpeed, 1, 40, '%.0f')
  if ui.itemEdited() then
    setValue('LOOK', 'FILTER_SPEED', math.floor(filterSpeed + 0.5))
  end

  local topSpeed = getNumber('LOOK', 'TOP_SPEED', 400)
  topSpeed = ui.slider('Top Speed', topSpeed, 50, 1000, '%.0f')
  if ui.itemEdited() then
    setValue('LOOK', 'TOP_SPEED', math.floor(topSpeed + 0.5))
  end

  ui.separator()

  if ui.button('Reload from file') then
    loadIni()
  end

  ui.popFont()
end