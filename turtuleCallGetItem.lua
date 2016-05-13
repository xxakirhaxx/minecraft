function getPeripheral (name)
	for i = 1, #peripheral.getNames() do
		if peripheral.getType(peripheral.getNames()[i]) == name then
			return peripheral.getNames()[i]
		end
	end
end

local chest = peripheral.wrap(getPeripheral("ender_chest"))
local modem = getPeripheral("modem")
local getItemId = 0
local args = {}

function getId ()

	local id = 0
	local getItemId = 0
	
	rednet.open(modem)
	rednet.broadcast("getItemId")
	rednet.close(modem)
	
	while id ~= getItemId or (id == 0 and getItemId = 0) do
		rednet.open(modem)
		id, getItemId = rednet.receive()
		rednet.close(modem)
	end
	
	return getItemId
end

function init ()

	getItemId = getId()
	
end

function shutdown ()

end

function main ()
	
	if #args < 2 then return end
	
	if type(args[1]) ~= "string" then return end
	
	if #args >= 2 then
		if type(args[2]) ~= "number" then return end
	end
	
	if #args >= 3 then return
		if type(args[3]) ~= "number" then return end
	end
	
	if #args > 3 then
		return 
	end
	
	init()
	
	local id = 0
	local msg = {}
	local bool = false
	local openConnection = {cmd = "openConnection"}
	local frequency = 0
	local amount = 0
	local itemName = args[1]
	local slot = args[2]
	
	if args[3] == nil then
		amount = 1
	else
		amount = args[3]
	end
	
	if turtle.getItemCount(slot) > 0 then return end
	
	local request = {cmd = "getItem" itemName = itemName, amount = amount}
	local closeConnection = {cmd = "closeConnection"}
	
	rednet.open(modem)
	rednet.send(getItemId, openConnection)
	rednet.close(modem)
	
	while frequency == 0 or id ~= getItemId do
		rednet.open(modem)
		id, frequency = rednet.receive()
		rednet.close(modem)
	end
	
	chest.setFrequency(frequency)
	
	rednet.open(modem)
	rednet.send(getItemId, request)
	rednet.close(modem)
	
	while true do
		rednet.open(modem)
		id, msg = rednet.receive()
		rednet.close(modem)
		if type(msg) == "table" and id == getItemId then
			if msg.sent ~= nil then
				if msg.sent then
					break
				end
			end
		end
	end
	
	turtle.select(slot)
	turtle.suckDown(amount)
	
	rednet.open(modem)
	rednet.send(getItemId, closeConnection)
	rednet.close(modem)
	
	
	shutdown()
end