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
local turtleGetItemProt = "turtleGetItem"
local getItemId = nil
local frequency = 0

function selectItem (name)

	for i = 1, 16 do
		turtle.select(i)
		if turtle.getItemDetail() ~= nil then 
			if turtle.getItemDetail().name == name then return end
		end
	end
	
	turtle.select(1)
end

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

function getItem (itemName, amount)
	
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
	
	turtle.suckDown(tonumber(amount))
	
end

function clearInv ()

	chest.setFrequency(0)
	
	turtle.select(1)
	
	for i = 1, 16 do
		turtle.select(i)
		turtle.dropDown()
	end
	
	chest.setFrequency(frequency)
	
end

function refuel (num)

	chest.setFrequency(frequency)
	
	while turtle.getFuelLevel() < num + 1000 do
		dbug("Refueling, currnet fuel levels: "..tostring(turtle.getFuelLevel()))
		getItem("Lava Bucket", 1)
		selectItem("minecraft:lava_bucket")
		turtle.refuel()
		chest.setFrequency(0)
		turtle.dropDown()
		chest.setFrequency(frequency)
	end
	
	turtle.select(1)
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
	getItem("Diamond Pickaxe", 1)
	turtle.equipRight()
	
end

function dig (s) 

	if type(s) ~= "string" then return end
	
	if s == "up" then
		while turtle.detectUp() do
			turtle.digUp()
		end
	elseif s == "down" then
		while turtle.detectDown() do
			turtle.digDown()
		end
	elseif s == "forward" then
		while turtle.detect() do
			turtle.dig()
		end
	end
	
end

function init ()
	
	openFrequency()
	
	turtle.select(1)
	
	clearInv()
	
	emptyChest()
	
	refuel(0)
	
	equipPickAxe()
	
	turtle.digDown()
	
	turtle.select(1)
	
end

function shutdown ()

	turtle.digDown()
	
	selectItem("EnderStorage:enderChest")
	
	turtle.placeDown()
	
	emptyChest()
	
	clearInv()
	
	closeFrequency()
	
	turtle.digDown()
	
end


function build ()
	

end

function main ()
	
	local length = tonumber(args[1]) - 1
	local width = tonumber(args[2]) - 1
	local height = tonumber(args[3]) - 1
	
	init()
	
	build()
	
	shutdown()
	
end

main()