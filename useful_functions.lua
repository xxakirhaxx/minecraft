function getPeripheral (name)
	for i = 1, #peripheral.getNames() do
		if peripheral.getType(peripheral.getNames()[i]) == name then
			return peripheral.getNames()[i]
		end
	end
end

function dns ()

	rednet.open(getPeripheral("modem"))
	local id, msg, p = rednet.receive()
	rednet.send(tonumber(id), tostring(os.getComputerID()), tostring(p))
	rednet.open(getPeripheral("modem"))
	
end

local d = false

function dbug (s)

	if d then print(s) end
	
end

function getUniqueHostName ()

	local i = 1
	
	repeat
		local h = 1
		hostName = "host"..tostring(i)
		i = i+1
		
		rednet.open(getPeripheral("modem"))
		h = rednet.lookup(tostring(hostName))
		rednet.close(getPeripheral("modem"))
		
	until h == nil

	return tostring(hostName)
end

function startHost ()

	local hostName = getUniqueHostName()
	
	rednet.open(getPeripheral("modem"))
	rednet.host(hostName, hostName)
	rednet.close(getPeripheral("modem"))
	
	return tostring(hostName)
end

function endHost (hostName)
	rednet.open(getPeripheral("modem"))
	rednet.unhost(hostName,hostName)
	rednet.close(getPeripheral("modem"))
end

function send (id, msg, protocol,...)

	local modem = getPeripheral("modem")
	local lookup = nil
	local sProt = nil
	local rProt = nil
	
	if select(1,...) ~= nil then lookup = select(1,...) end
	if select(2,...) ~= nil then sProt = select(2,...) end
	if select(3,...) ~= nil then rProt = select(3,...) end
	
	rednet.open(modem)
	if lookup ~= nil then id = tonumber(rednet.lookup(lookup, lookup)) end
	local rid = tonumber(os.getComputerID())
	
	rednet.send(tonumber(id), {id = tonumber(rid), sProt = tostring(sProt), rProt = tostring(rProt), msg = msg}, tostring(protocol))
	rednet.close(modem)

end

function receive (protocol)

	local modem = getPeripheral("modem")
	local id = 0
	local msg = {}
	local p = ""
	
	repeat
		rednet.open(modem)
		id, msg, p = rednet.receive()
		rednet.close(modem)
		
		if p == "dns" then
			rednet.open(modem)
			rednet.send(tonumber(id), tostring(os.getComputerID()), tostring(p))
			rednet.close(modem)		
		end
		
	until p == protocol
	
	return msg
end

local args = {...}

function getPeripheral (name)
	for i = 1, #peripheral.getNames() do
		if peripheral.getType(peripheral.getNames()[i]) == name then
			return peripheral.getNames()[i]
		end
	end
end

local d = true

function dbug (s)

	if d then print(s) end
	
end

function send (id, msg, protocol,...)

	local modem = getPeripheral("modem")
	
	local frequency = 0
	
	if select(1,...) ~= nil then frequency = select(1,...) end

	rednet.open(modem)
	rednet.send(tonumber(id), {frequency = tonumber(frequency), msg = msg}, tostring(protocol))
	rednet.close(modem)

end

function receive (protocol)

	local modem = getPeripheral("modem")
	local id = 0
	local msg = {}
	local p = ""
	
	rednet.open(modem)
	id, msg, p = rednet.receive(protocol)
	rednet.close(modem)
	
	return id, msg
end

local chest = peripheral.wrap(getPeripheral("ender_chest"))
local modem = getPeripheral("modem")
local turtleGetItemProt = "turtleGetItem"
local getItemId = nil
local frequency = 0

function emptyChest ()

	turtle.select(1)
	
	chest.setFrequency(frequency)
	
	while turtle.suckDown() do
		chest.setFrequency(0)
		turtle.select(1)
		turtle.dropDown()
		chest.setFrequency(frequency)
	end
	
	chest.setFrequency(frequency)
	
	turtle.select(1)
end

function getItem (itemName, slot, amount)
	
	if getItemId == nil then return end
	
	local id = tonumber(getItemId)
	local cmd = "getItem"
	local request = {cmd = cmd, itemName = tostring(itemName), amount = tonumber(amount)}
	
	dbug("Requesting item from id: "..tostring(id).." cmd: "..tostring(cmd).." itemName: "..tostring(itemName).." amount: "..tostring(amount))
	
	repeat
		send(id, request, turtleGetItemProt)
		id, msg = receive(turtleGetItemProt)
	until msg.msg.success == true
	
	dbug("Received "..tostring(amount).." "..tostring(itemName))
	
	turtle.select(tonumber(slot))
	turtle.suckDown(tonumber(amount))
	
end

function clearInv ()

	chest.setFrequency(0)
	
	turtle.select(1)
	
	for i = 1, 16 do
		turtle.select(i)
		turtle.dropDown()
	end
	
	turtle.select(1)
	turtle.equipRight()
	turtle.dropDown()
	turtle.select(1)
	
	chest.setFrequency(frequency)
	
end

function refuel ()

	chest.setFrequency(frequency)
	
	while turtle.getFuelLevel() < 5000 do
		dbug("Refueling, currnet fuel levels: "..tostring(turtle.getFuelLevel()))
		turtle.select(1)
		getItem("Lava Bucket", 1, 1)
		turtle.refuel()
		chest.setFrequency(0)
		turtle.dropDown()
		chest.setFrequency(frequency)
	end
	
	chest.setFrequency(frequency)
			
end

function openFrequency ()

	local modem = getPeripheral("modem")
	local open = {cmd = "openFrequency"}
	local command_id = nil
	local id = 0
	local msg = {}
	
	repeat
		rednet.open(modem)
		command_id = rednet.lookup(tostring(turtleGetItemProt), tostring(turtleGetItemProt))
		rednet.close(modem)
	until command_id ~= nil
	
	dbug("Sending to id: "..tostring(command_id).." msg: "..tostring(open.cmd).." protocol: "..tostring(turtleGetItemProt))
	
	send(command_id, open, turtleGetItemProt)
	
	dbug("Waiting for response")
	
	repeat
		id, msg = receive(turtleGetItemProt)
	until msg.msg.success
	
	dbug("Response received from id: "..tostring(id).." frequency: "..tostring(msg.frequency))
	
	getItemId = tonumber(msg.frequency)
	frequency = tonumber(msg.frequency)
	
end

function closeFrequency ()

	local modem = getPeripheral("modem")
	local close = {cmd = "closeFrequency"}
	local command_id = nil
	local id = 0
	local msg = {}
	
	repeat
		rednet.open(modem)
		command_id = rednet.lookup(tostring(turtleGetItemProt), tostring(turtleGetItemProt))
		rednet.close(modem)
	until command_id ~= nil
	
	dbug("Sending to id: "..tostring(command_id).." msg: "..tostring(close.cmd).." protocol: "..tostring(turtlegetItemProt))
	
	send(command_id, close, turtleGetItemProt, frequency)
	
	dbug("Waiting for response")
	
	repeat
		id, msg = receive(turtleGetItemProt)
	until msg.msg.success
	
	dbug("Response received from id: "..tostring(id).." success: "..tostring(msg.msg.success))
	
end

function equipPickAxe ()

	turtle.select(1)
	turtle.equipRight()
	chest.setFrequency(0)
	turtle.dropDown()
	chest.setFrequency(frequency)
	getItem("Diamond Pickaxe", 1, 1)
	turtle.equipRight()
	
end