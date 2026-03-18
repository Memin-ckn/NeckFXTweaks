local NECK_INI_PATH = ac.getFolder(ac.FolderID.Root) .. '/extension/config/neck.ini'

local state = {
  ini = nil,
  loaded = false,
  status = 'Starting...',
  activeTab = 'basic',
  sections = {
    basic_direction = true,
    basic_look = true,
    advanced_direction = false,
    advanced_pan = false,
    advanced_effects = false
  }
}

local function log(msg)
  ac.log('[NeckFXTweaks] ' .. tostring(msg))
end

local function trim(s)
  return (tostring(s):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function escapePattern(s)
  return (tostring(s):gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1'))
end

local function readWholeFile(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local c = f:read('*all')
  f:close()
  return c
end

local function writeWholeFile(path, content)
  local f = io.open(path, 'w')
  if not f then return false end
  f:write(content)
  f:close()
  return true
end

local function splitLines(text)
  local lines = {}
  if not text then return lines end
  text = text:gsub('\r\n', '\n')
  for line in (text .. '\n'):gmatch('(.-)\n') do
    table.insert(lines, line)
  end
  return lines
end

local function patchIniValuePreserveComment(sectionName, key, newValue)
  local content = readWholeFile(NECK_INI_PATH)
  if not content then
    state.status = 'Failed to read neck.ini'
    log(state.status)
    return false
  end

  local lines = splitLines(content)
  local inSection = false
  local replaced = false
  local keyPattern = '^%s*' .. escapePattern(key) .. '%s*='

  for i = 1, #lines do
    local line = lines[i]
    local section = line:match('^%s*%[([^%]]+)%]%s*$')
    if section then
      inSection = trim(section) == sectionName
    elseif inSection and line:match(keyPattern) then
      local prefix, suffix = line:match('^(%s*' .. escapePattern(key) .. '%s*=%s*)[^;]*(.*)$')
      if prefix then
        lines[i] = prefix .. tostring(newValue) .. suffix
      else
        lines[i] = string.format('%s=%s', key, tostring(newValue))
      end
      replaced = true
      break
    end
  end

  if not replaced then
    inSection = false
    for i = 1, #lines do
      local line = lines[i]
      local section = line:match('^%s*%[([^%]]+)%]%s*$')
      if section then
        if inSection then
          table.insert(lines, i, string.format('%s=%s', key, tostring(newValue)))
          replaced = true
          break
        end
        inSection = trim(section) == sectionName
      end
    end

    if not replaced and inSection then
      table.insert(lines, string.format('%s=%s', key, tostring(newValue)))
      replaced = true
    end
  end

  if not replaced then
    table.insert(lines, string.format('[%s]', sectionName))
    table.insert(lines, string.format('%s=%s', key, tostring(newValue)))
  end

  local ok = writeWholeFile(NECK_INI_PATH, table.concat(lines, '\n'))
  if not ok then
    state.status = 'Failed to write neck.ini'
    log(state.status)
    return false
  end

  state.status = string.format('Saved: [%s] %s = %s', sectionName, key, tostring(newValue))
  log(state.status)
  return true
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

local function reloadIni()
  loadIni()
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

local function getString(section, key, fallback)
  if not ensureIni() then return fallback end
  local v = state.ini:get(section, key, fallback)
  if v == nil then return fallback end
  return tostring(v)
end

local function getPair(section, key, defaultA, defaultB)
  local raw = getString(section, key, string.format('%s, %s', tostring(defaultA), tostring(defaultB)))
  local a, b = raw:match('^%s*([^,]+)%s*,%s*([^,]+)%s*$')
  local na = tonumber(a or '')
  local nb = tonumber(b or '')
  if na == nil then na = defaultA end
  if nb == nil then nb = defaultB end
  return na, nb
end

local function setValue(section, key, value)
  if patchIniValuePreserveComment(section, key, value) then
    reloadIni()
  end
end

local function setBool(section, key, value)
  setValue(section, key, value and '1' or '0')
end

local function setPair(section, key, a, b, decimals)
  local fmt = '%s, %s'
  if decimals == 0 then
    fmt = '%d, %d'
  elseif decimals == 1 then
    fmt = '%.1f, %.1f'
  elseif decimals == 2 then
    fmt = '%.2f, %.2f'
  end
  setValue(section, key, string.format(fmt, a, b))
end

local function drawCheckbox(section, key, label, fallback)
  local v = getBool(section, key, fallback)
  if ui.checkbox(label, v) then
    setBool(section, key, not v)
  end
end

local function drawSlider(section, key, label, minV, maxV, fallback, fmt, decimals)
  local v = getNumber(section, key, fallback)
  v = ui.slider(label, v, minV, maxV, fmt)
  if ui.itemEdited() then
    if decimals == 0 then
      setValue(section, key, string.format('%d', math.floor(v + 0.5)))
    elseif decimals == 1 then
      setValue(section, key, string.format('%.1f', v))
    elseif decimals == 2 then
      setValue(section, key, string.format('%.2f', v))
    else
      setValue(section, key, tostring(v))
    end
  end
end

local function drawPairSliders(section, key, labelA, labelB, minV, maxV, defaultA, defaultB, fmt, decimals)
  local a, b = getPair(section, key, defaultA, defaultB)

  a = ui.slider(labelA, a, minV, maxV, fmt)
  local aEdited = ui.itemEdited()

  b = ui.slider(labelB, b, minV, maxV, fmt)
  local bEdited = ui.itemEdited()

  if aEdited or bEdited then
    if decimals == 0 then
      setPair(section, key, math.floor(a + 0.5), math.floor(b + 0.5), 0)
    elseif decimals == 1 then
      setPair(section, key, a, b, 1)
    else
      setPair(section, key, a, b, 2)
    end
  end
end

local function drawStickSelector(current)
  ui.text('Xbox stick:')
  if ui.radioButton('Disabled##stick', current == -1) then
    setValue('LOOK', 'XBOX_STICK', '-1')
    return -1
  end
  if ui.radioButton('Left##stick', current == 0) then
    setValue('LOOK', 'XBOX_STICK', '0')
    return 0
  end
  if ui.radioButton('Right##stick', current == 1) then
    setValue('LOOK', 'XBOX_STICK', '1')
    return 1
  end
  return current
end

local function drawTabButton(id, label)
  if ui.button(label) then
    state.activeTab = id
  end
end

local function drawSectionToggle(id, title)
  local opened = state.sections[id]
  local prefix = opened and '🔽 ' or '▶️ '
  if ui.button(prefix .. title) then
    state.sections[id] = not opened
  end
  return state.sections[id]
end

local function drawBasicTab()
  if drawSectionToggle('basic_direction', 'Direction alignment') then
    drawSlider('ALIGNMENT_BASE', 'ALIGN_WITH_STEERING', 'Steering following', 0.0, 2.5, 0.25, '%.2f', 2)
    drawSlider('ALIGNMENT_BASE', 'ALIGN_WITH_VELOCITY', 'Track following', 0.0, 2.5, 0.25, '%.2f', 2)
    drawSlider('ALIGNMENT_BASE', 'TILT', 'Base head tilt', -10.0, 10.0, 0.0, '%.1f°', 1)
    drawSlider('ALIGNMENT_BASE', 'YAW', 'Base head yaw', -10.0, 10.0, 0.0, '%.1f°', 1)
    ui.separator()
  end

  if drawSectionToggle('basic_look', 'Look around') then
    local xboxStick = getNumber('LOOK', 'XBOX_STICK', 1)
    drawStickSelector(xboxStick)
    drawSlider('LOOK', 'XBOX_STICK_DEADZONE', 'Xbox stick deadzone', 0.01, 0.99, 0.03, '%.2f', 2)
    drawSlider('LOOK', 'XBOX_STICK_EXPONENT', 'Xbox stick exponent', 0.2, 5.0, 1.8, '%.2f', 2)
    drawSlider('LOOK', 'FILTER_SPEED', 'Glance filtering speed', 1.0, 30.0, 10.0, '%.0f', 0)
    drawSlider('LOOK', 'TOP_SPEED', 'Top glance speed', 100.0, 800.0, 400.0, '%.0f deg/s', 0)
    ui.separator()
  end
end

local function drawAdvancedTab()
  if drawSectionToggle('advanced_direction', 'Direction alignment') then
    drawSlider('ALIGNMENT_BASE', 'ALIGN_WITH_STEERING', 'Steering following', 0.0, 2.5, 0.25, '%.2f', 2)
    drawSlider('ALIGNMENT_BASE', 'ALIGN_WITH_STEERING_FILTER_SPEED', 'Steering following filter', 0.0, 15.0, 6.0, '%.1f', 1)
    drawSlider('ALIGNMENT_BASE', 'ALIGN_WITH_VELOCITY', 'Track following', 0.0, 2.5, 0.25, '%.2f', 2)
    drawSlider('ALIGNMENT_BASE', 'ALIGN_WITH_VELOCITY_FULL_SPEED', 'Track following full speed', 0.0, 80.0, 40.0, '%.0f km/h', 0)
    drawSlider('ALIGNMENT_BASE', 'ALIGN_WITH_VELOCITY_FILTER_SPEED', 'Track following filter', 0.0, 15.0, 5.0, '%.1f', 1)
    drawSlider('ALIGNMENT_BASE', 'VERTICAL_AXIS_SPEED', 'Vertical axis speed', 0.0, 15.0, 5.0, '%.1f', 1)
    drawSlider('ALIGNMENT_BASE', 'TILT', 'Base head tilt', -10.0, 10.0, 0.0, '%.1f°', 1)
    drawSlider('ALIGNMENT_BASE', 'YAW', 'Base head yaw', -10.0, 10.0, 0.0, '%.1f°', 1)
    drawSlider('ALIGNMENT_BASE', 'HORIZON_LOCK', 'Horizon lock', 0.0, 1.0, 0.3, '%.2f', 2)
    drawCheckbox('ALIGNMENT_BASE', 'HORIZON_LOCK_TRACK', 'Lock horizon to track surface', false)
    drawSlider('ALIGNMENT_BASE', 'G_TILT_X', 'Tilt with X G-force', 0.0, 2.0, 0.2, '%.2f', 2)
    drawSlider('ALIGNMENT_BASE', 'G_TILT_Z', 'Tilt with Z G-force', 0.0, 2.0, 1.0, '%.2f', 2)
    ui.separator()
  end

  if drawSectionToggle('advanced_pan', 'Look and pan') then
    local xboxStick = getNumber('LOOK', 'XBOX_STICK', 1)
    drawStickSelector(xboxStick)
    drawSlider('LOOK', 'FILTER_SPEED', 'Glance filtering speed', 1.0, 30.0, 10.0, '%.0f', 0)
    drawSlider('LOOK', 'TOP_SPEED', 'Top glance speed', 100.0, 800.0, 400.0, '%.0f deg/s', 0)
    drawSlider('LOOK', 'FILTER_MANUAL_SPEED', 'Free look filtering speed', 1.0, 30.0, 20.0, '%.0f', 0)
    drawPairSliders('LOOK', 'MOUSE_SENSITIVITY', 'Mouse sensitivity X', 'Mouse sensitivity Y', 1.0, 1000.0, 400.0, 200.0, '%.0f', 0)
    drawSlider('LOOK', 'XBOX_STICK_DEADZONE', 'Xbox stick deadzone', 0.01, 0.99, 0.03, '%.2f', 2)
    drawSlider('LOOK', 'XBOX_STICK_EXPONENT', 'Xbox stick exponent', 0.2, 5.0, 1.8, '%.2f', 2)
    drawCheckbox('LOOK', 'ORIGINAL_LOOK_BACK', 'Hide car when looking back')
    drawSlider('LOOK', 'LOOK_BACK_ANGLE', 'Angle for looking back', 60.0, 150.0, 130.0, '%.0f°', 0)
    drawCheckbox('LOOK', 'LOOK_WITH_RHM', 'Look and pan with Track IR connected')

    ui.separator()

    drawSlider('PAN', 'FILTER_SPEED', 'Pan filtering speed', 1.0, 30.0, 6.0, '%.0f', 0)
    drawSlider('PAN', 'TOP_SPEED', 'Pan top speed', 1.0, 200.0, 20.0, '%.0f deg/s', 0)
    drawSlider('PAN', 'FILTER_MANUAL_SPEED', 'Free movement filtering speed', 1.0, 30.0, 2.0, '%.0f', 0)
    drawPairSliders('PAN', 'MOUSE_SENSITIVITY', 'Pan mouse sensitivity X', 'Pan mouse sensitivity Y', 0.0, 20.0, 1.0, 1.0, '%.1f', 1)
    ui.separator()
  end

  if drawSectionToggle('advanced_effects', 'Effects and helmet') then
    drawCheckbox('EFFECTS_BASE', 'LENS_FLARE', 'Lens flare')
    drawCheckbox('HELMET', 'SHOW', 'Show driver helmet')
    drawCheckbox('HELMET', 'BLUR', 'Blur helmet')
    ui.separator()
  end
end

function script.windowMain(dt)
  ui.pushFont(ui.Font.Small)
  ui.pushItemWidth(ui.availableSpaceX() - ui.availableSpaceX()/4)

  if not state.loaded then
    loadIni()
  end

  ui.text('Neck FX Tweaks')
  ui.separator()
  ui.textWrapped('If Neck FX is not enabled, these settings will not do anything.')
  ui.textWrapped(state.status)

  if not state.loaded then
    if ui.button('Retry loading') then
      loadIni()
    end
    ui.popItemWidth()
    ui.popFont()
    return
  end

  ui.separator()

  drawTabButton('basic', 'Basic')
  ui.sameLine()
  drawTabButton('advanced', 'Advanced')
  ui.separator()

  if state.activeTab == 'basic' then
    drawBasicTab()
  else
    drawAdvancedTab()
  end

  if ui.button('Reload from file') then
    loadIni()
  end

  ui.popItemWidth()
  ui.popFont()
end