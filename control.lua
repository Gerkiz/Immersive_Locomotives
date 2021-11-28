require 'utils.data_stages'
_LIFECYCLE = _STAGE.control -- Control stage
_DEBUG = false
_DUMP_ENV = false

local Event = require 'utils.event'
local Functions = require 'functions'
local ICW = require 'table'
local Public = {}

Public.reset = ICW.reset
Public.get_table = ICW.get

local function on_player_mined_entity(event)
    local entity = event.entity
    if not entity and not entity.valid then
        return
    end
    Functions.kill_wagon(entity)
end

local function on_robot_mined_entity(event)
    local entity = event.entity
    if not entity and not entity.valid then
        return
    end
    Functions.kill_wagon(entity)
end

local function on_built_entity(event)
    local created_entity = event.created_entity
    Functions.create_wagon(created_entity)
end

local function on_robot_built_entity(event)
    local created_entity = event.created_entity
    Functions.create_wagon(created_entity)
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity and not entity.valid then
        return
    end
    local wagon_types = ICW.get('wagon_types')

    if not wagon_types[entity.type] then
        return
    end
    local icw = ICW.get()
    Functions.kill_wagon(icw, entity)
end

local function on_player_driving_changed_state(event)
    local icw = ICW.get()
    local player = game.players[event.player_index]
    Functions.use_cargo_wagon_door_with_entity(icw, player, event.entity)
end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    Functions.kill_minimap(player)
    Functions.kill_button(player)
end

local function on_gui_closed(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if not entity.unit_number then
        return
    end
    local icw = ICW.get()
    if not icw.wagons[entity.unit_number] then
        return
    end
    Functions.kill_minimap(game.players[event.player_index])
end

local function on_gui_opened(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if not entity.unit_number then
        return
    end
    local icw = ICW.get()
    local wagon = icw.wagons[entity.unit_number]
    if not wagon then
        return
    end

    Functions.draw_minimap(
        icw,
        game.players[event.player_index],
        wagon.surface,
        {
            wagon.area.left_top.x + (wagon.area.right_bottom.x - wagon.area.left_top.x) * 0.5,
            wagon.area.left_top.y + (wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5
        }
    )
end

local function on_player_died(event)
    Functions.kill_minimap(game.players[event.player_index])
end

local function on_train_created()
    local icw = ICW.get()
    Functions.request_reconstruction(icw)
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.players[event.player_index]

    local name = element.name

    if name == 'icw_discard_button_name' then
        if player.gui.left.icw_main_frame then
            player.gui.left.icw_main_frame.destroy()
        end
    end
    if name == 'icw_minimap_button' then
        Functions.toggle_button(player)
    end
    local icw = ICW.get()

    Functions.toggle_minimap(icw, event)
end

local function on_tick()
    local tick = game.tick
    if tick % 10 == 0 then
        Functions.item_transfer()
    end
    if tick % 140 == 0 then
        Functions.update_minimap()
    end
end

local function on_init()
    Public.reset()
end

local function on_gui_switch_state_changed(event)
    local element = event.element
    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end

    if not element.valid then
        return
    end

    if element.name == 'icw_auto_switch' then
        local icw = ICW.get()
        Functions.toggle_auto(icw, player)
    end
end

local function on_player_joined_game(event)
    local players = ICW.get('players')
    local player_data = players[event.player_index]
    if not player_data then
        return
    end

    local surface = game.surfaces[player_data.surface]
    if surface and surface.valid then
        return
    end

    local fallback_surface = game.surfaces[player_data.fallback_surface]
    if not fallback_surface or not fallback_surface.valid then
        return
    end

    local player = game.players[event.player_index]
    local p = fallback_surface.find_non_colliding_position('character', player_data.fallback_position, 32, 0.5)
    if p then
        player.teleport(p, fallback_surface)
    else
        player.teleport(player.force.get_spawn_position(fallback_surface), fallback_surface)
    end
end

local function on_player_left_game(event)
    Functions.kill_minimap(game.players[event.player_index])
end

function Public.register_wagon(wagon_entity)
    local icw = ICW.get()
    return Functions.create_wagon(icw, wagon_entity)
end

Event.on_init(on_init)
Event.on_nth_tick(5, on_tick)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_train_created, on_train_created)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)

return Public
