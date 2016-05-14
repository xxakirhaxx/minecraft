function getPeripheral (name)
	for i = 1, #peripheral.getNames() do
		if peripheral.getType(peripheral.getNames()[i]) == name then
			return peripheral.getNames()[i]
		end
	end
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
	
	rednet.send(tonumber(id), {id = tonumber(rid), sProt = tostring(sProt), rProt = tostring(rProt)  msg = msg}, tostring(protocol))
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