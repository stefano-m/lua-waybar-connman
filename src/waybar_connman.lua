#!/usr/bin/env lua
local GLib = require("lgi").GLib
local json = require("cjson.safe")
local string = string
local arg = arg
local io = io
local SIGINT = 2
local SIGTERM = 15

local function format(service)

  local css_class = "disconnected"

  if service.State == "ready" or service.State == "online" then
    css_class = "connected"
  end

  return {
    text = service.State,
    alt =  service.Type,
    tooltip =  string.format("%s (%s - %s)%s",
                             service.Name or "<hidden>",
                             service.IPv4.Address or "<none>",
                             service.Ethernet.Interface,
                             (service.Error and " " .. service.Error or "")),
    class = css_class,
    percentage =  service.Strength or "",
  }
end

local relevant_property_names = {
  State = true,
  Type = true,
  Name = true,
  IPv4 = true,
  Ethernet = true,
  Error = true,
}

local function update(service)
  service:connect_signal(
    function(svc, prop_name)
      if relevant_property_names[prop_name] then
        local output = format(svc)
        print(json.encode(output))
      end
    end,
    "PropertyChanged"
  )
end

local function run()

  local connman = require("connman_dbus")

  local current = connman.services[1]

  local output = format(current)
  print(json.encode(output))

  update(current)

  connman:connect_signal(
    function (mgr)
      current = mgr.services[1]
      if current then
        update(current, output)
      else
        print(json.encode({
                  text = mgr.State,
                  alt = "offline",
                  tooltip = "disabled",
                  class = "disconnected",
                  percentage = "",
        }))
      end
    end,
    "ServicesChanged"
  )

  local main_loop = GLib.MainLoop()

  local function exit_on_signal()
    print(json.encode({
              text = "exited",
              alt = "quit",
              tooltip = "exited",
              class = "quit",
              percentage = "",
    }))
    main_loop:quit()
  end

  GLib.unix_signal_add(GLib.PRIORITY_HIGH, SIGINT, exit_on_signal)
  GLib.unix_signal_add(GLib.PRIORITY_HIGH, SIGTERM, exit_on_signal)

  main_loop:run()
end

if arg and arg[1] == "run" then
  io.stdout:setvbuf("no")       -- unbuffered output
  run()
end
