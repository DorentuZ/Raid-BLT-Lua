
BLTNotificationsGui = BLTNotificationsGui or class( MenuGuiComponentGeneric )

local padding = 10

-- Copied from NewHeistsGui
local SPOT_W = 32
local SPOT_H = 8
local BAR_W = 32
local BAR_H = 6
local BAR_X = (SPOT_W - BAR_W) / 2
local BAR_Y = 0
local TIME_PER_PAGE = 6
local CHANGE_TIME = 0.5

function BLTNotificationsGui:init( ws, fullscreen_ws, node )

	self._ws = ws
	self._fullscreen_ws = fullscreen_ws
	self._panel = self._ws:panel():panel({})
	self._init_layer = self._ws:panel():layer()

	self._data = node:parameters().menu_component_data or {}
	self._buttons = {}
	self._next_time = Application:time() + TIME_PER_PAGE

	self._current = 0
	self._notifications = {}
	self._notifications_count = 0
	self._uid = 1000

	self:_setup()

end

function BLTNotificationsGui:close()
	self._ws:panel():remove( self._panel )
end

function BLTNotificationsGui:_setup()

	local font = tweak_data.menu.pd2_small_font
	local font_size = tweak_data.menu.pd2_small_font_size
	local max_left_len = 0
	local max_right_len = 0
	local extra_w = font_size * 4
	local icon_size = 16

	self._enabled = true

	-- Get player profile panel
	local profile_panel = managers.menu_component._player_profile_gui._panel

	-- Create panels
	self._panel = self._ws:panel():panel({
		w = profile_panel:w(),
		h = 128
	})
	self._panel:set_left( profile_panel:left() )
	self._panel:set_bottom( profile_panel:top() )
	-- BoxGuiObject:new( self._panel:panel({ layer = 100 }), { sides = { 1, 1, 1, 1 } } )

	self._content_panel = self._panel:panel({
		h = self._panel:h() * 0.8,
	})

	self._buttons_panel = self._panel:panel({
		h = self._panel:h() * 0.2,
	})
	self._buttons_panel:set_top( self._content_panel:h() )

	-- Blur background
	local bg_rect = self._content_panel:rect({
		name = "background",
		color = Color.black,
		alpha = 0.4,
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	local blur = self._content_panel:bitmap({
		texture = "guis/textures/test_blur_df",
		w = self._content_panel:w(),
		h = self._content_panel:h(),
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		halign = "scale",
		valign = "scale"
	})

	-- Outline
	BoxGuiObject:new( self._content_panel, { sides = { 1, 1, 1, 1 } } )
	self._content_outline = BoxGuiObject:new( self._content_panel, { sides = { 2, 2, 2, 2 } } )

	-- Setup notification buttons
	self._bar = self._buttons_panel:bitmap({
		texture = "guis/textures/pd2/shared_lines",
		halign = "grow",
		valign = "grow",
		wrap_mode = "wrap",
		x = BAR_X,
		y = BAR_Y,
		w = BAR_W,
		h = BAR_H
	})
	self:set_bar_width( BAR_W, true )
	self._bar:set_visible( false )

	local icon, rect = tweak_data.hud_icons:get_icon_data("crime_spree_shield_phalanx")
	self:add_notification( {
		title = "Title A",
		text = "Notification A body",
		icon = icon,
		icon_texture_rect = rect,
		color = Color.red,
	} )

	local icon, rect = tweak_data.hud_icons:get_icon_data("crime_spree_taser_overcharge")
	self:add_notification( {
		title = "Title B",
		text = "Notification B body",
		icon = icon,
		icon_texture_rect = rect,
		color = Color.blue,
		priority = 1000,
	} )

	local icon, rect = tweak_data.hud_icons:get_icon_data("crime_spree_pager")
	self:add_notification( {
		title = "Title C",
		text = "Notification C body",
		icon = icon,
		icon_texture_rect = rect,
		color = Color.green,
		priority = 10,
	} )

end

function BLTNotificationsGui:close()
	if alive(self._panel) then
		self._ws:panel():remove( self._panel )
	end
end

function BLTNotificationsGui:_rec_round_object(object)
	local x, y, w, h = object:shape()
	object:set_shape(math.round(x), math.round(y), math.round(w), math.round(h))
	if object.children then
		for i, d in ipairs(object:children()) do
			self:_rec_round_object(d)
		end
	end
end

function BLTNotificationsGui:_make_fine_text(text)
	local x, y, w, h = text:text_rect()
	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end

--------------------------------------------------------------------------------

function BLTNotificationsGui:_get_uid()
	local id = self._uid
	self._uid = self._uid + 1
	return id
end

function BLTNotificationsGui:_get_notification( uid )
	local idx
	for i, data in ipairs( self._notifications ) do
		if data.id == uid then
			idx = i
			break
		end
	end
	return self._notifications[idx], idx
end

function BLTNotificationsGui:add_notification( parameters )

	-- Create notification panel
	local new_notif = self._content_panel:panel({
	})

	local icon_size = new_notif:h() - padding * 2
	local icon
	if parameters.icon then
		icon = new_notif:bitmap({
			texture = parameters.icon,
			texture_rect = parameters.icon_texture_rect,
			color = parameters.color or Color.white,
			alpha = parameters.alpha or 1,
			x = padding,
			y = padding,
			w = icon_size,
			h = icon_size,
		})
	end

	local _x = (icon and icon:right() or 0) + padding

	local title = new_notif:text({
		text = parameters.title or "No Title",
		font = tweak_data.menu.pd2_large_font,
		font_size = tweak_data.menu.pd2_large_font_size * 0.5,
		x = _x,
		y = padding,
	})
	self:_make_fine_text( title )

	local text = new_notif:text({
		text = parameters.text or "No Text",
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		x = _x,
		w = new_notif:w() - _x,
		y = title:bottom(),
		h = new_notif:h() - title:bottom(),
		color = tweak_data.screen_colors.text,
		alpha = 0.8,
		wrap = true,
		word_wrap = true,
	})

	-- Create notification data
	local data = {
		id = self:_get_uid(),
		priority = parameters.priority or 0,
		parameters = parameters,
		panel = new_notif,
		title = title,
		text = text,
		icon = icon,
	}

	-- Update notifications data
	table.insert( self._notifications, data )
	table.sort( self._notifications, function(a, b)
		return a.priority > b.priority
	end )
	self._notifications_count = table.size( self._notifications )

	-- Check notification visibility
	for i, notif in ipairs( self._notifications ) do
		notif.panel:set_visible( i == 1 )
	end
	self._current = 1

	self:_update_bars()

	return data.id

end

function BLTNotificationsGui:remove_notification( uid )
	local _, idx = self:_get_notification( uid )
	if idx then
		table.remove( self._notifications, idx )
		self._notifications_count = table.size( self._notifications )
		self:_update_bars()
	end
end

function BLTNotificationsGui:update_notification( uid, parameters )
	local notification, idx = self:_get_notification( uid )
end

function BLTNotificationsGui:_update_bars()

	-- Remove old buttons
	for i, btn in ipairs( self._buttons ) do
		self._buttons_panel:remove( btn )
	end
	self._buttons_panel:remove( self._bar )

	self._buttons = {}

	-- Add new notifications
	for i = 1, self._notifications_count do

		local page_button = self._buttons_panel:bitmap({
			name = tostring(i),
			texture = "guis/textures/pd2/ad_spot",
		})
		page_button:set_center_x( ( i / ( self._notifications_count + 1 ) ) * self._buttons_panel:w() / 2 + self._buttons_panel:w() / 4 )
		page_button:set_center_y( (self._buttons_panel:h() - page_button:h()) / 2 )
		table.insert( self._buttons, page_button )

	end

	-- Add the time bar
	self._bar = self._buttons_panel:bitmap({
		texture = "guis/textures/pd2/shared_lines",
		halign = "grow",
		valign = "grow",
		wrap_mode = "wrap",
		x = BAR_X,
		y = BAR_Y,
		w = BAR_W,
		h = BAR_H
	})
	self:set_bar_width( BAR_W, true )
	if #self._buttons > 0 then
		self._bar:set_top( self._buttons[ 1 ]:top() + BAR_Y )
		self._bar:set_left( self._buttons[ 1 ]:left() + BAR_X )
	else
		self._bar:set_visible( false )
	end

end

--------------------------------------------------------------------------------

function BLTNotificationsGui:set_bar_width( w, random )
	NewHeistsGui.set_bar_width( self, w, random )
end

function BLTNotificationsGui:_move_to_notification( destination )
	
	-- Animation
	local swipe_func = function( o, other_object, duration )

		if not alive( o ) then return end
		if not alive( other_object ) then return end

		animating = true
		duration = duration or CHANGE_TIME
		local speed = o:w() / duration

		o:set_visible( true )
		other_object:set_visible( true )
		
		while alive( o ) and alive( other_object ) and o:right() >= 0 do
			local dt = coroutine.yield()
			o:move( -dt * speed, 0 )
			other_object:set_x( o:right() )
		end

		if alive(o) then
			o:set_x( 0 )
			o:set_visible( false )
		end
		if alive(other_object) then
			other_object:set_x( 0 )
			other_object:set_visible( true )
		end

		animating = false
		self._current = destination

	end

	-- Stop all animations
	for _, notification in ipairs( self._notifications ) do
		if alive(notification.panel) then
			notification.panel:stop()
			notification.panel:set_x( 0 )
			notification.panel:set_visible( false )
		end
	end

	-- Start swap animation for next notification
	local a = self._notifications[ self._current ]
	local b = self._notifications[ destination ]
	a.panel:animate( swipe_func, b.panel, CHANGE_TIME )

	-- Update bar
	self._bar:set_top( self._buttons[ destination ]:top() + BAR_Y )
	self._bar:set_left( self._buttons[ destination ]:left() + BAR_X )

end

function BLTNotificationsGui:_move_notifications( dir )
	self._queued = self._current + dir
	while self._queued > self._notifications_count do
		self._queued = self._queued - self._notifications_count
	end
	while self._queued < 1 do
		self._queued = self._queued + 1
	end
end

function BLTNotificationsGui:_next_notification()
	self:_move_notifications( 1 )
end

local animating
function BLTNotificationsGui:update( t, dt )

	if self._notifications_count <= 1 then
		return
	end

	self._next_time = self._next_time or t + TIME_PER_PAGE

	if self._block_change then
		self._next_time = t + TIME_PER_PAGE
	else
		if t >= self._next_time then
			self:_next_notification()
			self._next_time = t + TIME_PER_PAGE
		end

		self:set_bar_width( BAR_W *  ( 1 - (self._next_time - t) / TIME_PER_PAGE ) )
	end

	if not animating and self._queued then
		self:_move_to_notification( self._queued )
		self._queued = nil
	end

end

--------------------------------------------------------------------------------

function BLTNotificationsGui:mouse_moved( o, x, y )

	if not self._enabled then
		return
	end

	if alive(self._content_panel) and self._content_panel:inside(x, y) then
		self._content_outline:set_visible(true)
		return true, "link"
	else
		self._content_outline:set_visible(false)
	end

	for i, button in ipairs( self._buttons ) do
		if button:inside( x, y ) then
			return true, "link"
		end
	end

end

function BLTNotificationsGui:mouse_pressed( button, x, y )

	if not self._enabled or button ~= Idstring( "0" ) then
		return
	end

	if alive(self._content_panel) and self._content_panel:inside(x, y) then
		managers.menu:open_node("blt_mods")
		return true
	end

	for i, button in ipairs( self._buttons ) do
		if button:inside( x, y ) then
			local i = tonumber(button:name())
			if self._current ~= i then
				self:_move_to_notification( i )
				self._next_time = Application:time() + TIME_PER_PAGE
			end
			return true
		end
	end

end

--------------------------------------------------------------------------------
-- Patch MenuComponentManager to create the BLT Notifications component

Hooks:Add("MenuComponentManagerInitialize", "BLTNotificationsGui.MenuComponentManagerInitialize", function(menu)
	menu._active_components["blt_notifications"] = { create = callback(menu, menu, "create_blt_notifications_gui"), close = callback(menu, menu, "close_blt_notifications_gui") }
end)

function MenuComponentManager:blt_notifications()
	return self._blt_notifications
end

function MenuComponentManager:create_blt_notifications_gui( node )
	if not node then
		return
	end
	self._blt_notifications = self._blt_notifications or BLTNotificationsGui:new( self._ws, self._fullscreen_ws, node )
	self:register_component( "blt_notifications", self._blt_notifications )
end

function MenuComponentManager:close_blt_notifications_gui()
	if self._blt_notifications then
		self._blt_notifications:close()
		self._blt_notifications = nil
		self:unregister_component( "blt_notifications" )
	end
end

--------------------------------------------------------------------------------
-- Patch main menu to add notifications menu component

Hooks:Add("CoreMenuData.LoadDataMenu", "BLTNotificationsGui.CoreMenuData.LoadDataMenu", function( menu )

	for _, node in ipairs( menu ) do
		if node.name == "main" then
			if node.menu_components then
				node.menu_components = node.menu_components .. " blt_notifications"
			elseif _G.CommunityChallengesGui then
				node.menu_components = "player_profile menuscene_info new_heists game_installing debug_quicklaunch community_challenges blt_notifications"
			else
				node.menu_components = "player_profile menuscene_info new_heists game_installing debug_quicklaunch blt_notifications"
			end
		end
	end

end)