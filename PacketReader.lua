local packetReader = {} do
    local types = {
        ["Table"]    = 30;
        ["Instance"] = 28;
        ["Double"]   = 12;
        ["Boolean"]  = 9;
        ["String"]   = 2;
        ["EMTInst"]  = 0;
    }
    local packetFunctions = {} do
		packetFunctions.__index = packetFunctions

        function packetFunctions:nextByte()
            local value = self.bytes[self.pos]

            self.pos = self.pos + 1

            return value
        end

        function packetFunctions:nextChar()
            return string.char(self:nextByte())
        end

        function packetFunctions:nextUInt16BE()
            local tbl = {} do
                for i = 1, 2 do
                    table.insert(tbl, self:nextByte())
                end
            end

            return bit32.bor( 
                bit32.lshift(tbl[1], 8),
                tbl[2]
            )
        end

        function packetFunctions:nextUInt16LE()
            local tbl = {} do
                for i = 1, 2 do
                    table.insert(tbl, self:nextByte())
                end
            end

            return bit32.bor(
                bit32.lshift(tbl[2], 8),
                tbl[1]
            )
        end

        function packetFunctions:nextUInt32BE()
            local tbl = {} do
                for i = 1, 4 do
                    table.insert(tbl, self:nextByte())
                end
            end

            return bit32.bor(
                bit32.lshift(tbl[1], 24),
                bit32.bor(
                    bit32.lshift(tbl[2], 16),
                    bit32.bor(
                        bit32.lshift(tbl[3], 8),    
                        tbl[4]
                    )
                )
            )
        end
            
        function packetFunctions:nextUInt32LE()
            local tbl = {} do
                for i = 1, 4 do
                    table.insert(tbl, self:nextByte())
                end
            end

            return bit32.bor(
                bit32.lshift(tbl[4], 24),     
                bit32.bor(
                    bit32.lshift(tbl[3], 16),
                    bit32.bor(
                        bit32.lshift(tbl[2], 8),
                        tbl[1]
                    )
                )
            )
        end

        function packetFunctions:nextUInt64LE()
            local tbl = {} do
                for i = 1, 8 do
                    table.insert(tbl, self:nextByte())
                end
            end

            return (
                bit32.bor(
                    bit32.lshift(tbl[8], 56),
                    bit32.bor(
                        bit32.lshift(tbl[7], 48),
                        bit32.bor(
                            bit32.lshift(tbl[6], 40),
                            bit32.bor(
                                bit32.lshift(tbl[5], 32),
                                bit32.bor(
                                    bit32.lshift(tbl[4], 24), 
                                    bit32.bor(
                                        bit32.lshift(tbl[3], 16),
                                        bit32.bor(
                                            bit32.lshift(tbl[2], 8),
                                            tbl[1]
                                        )
                                    )
                                )
                            )
                        )
                    )
                )   
            )
        end

        function packetFunctions:nextVarInt64()
            local result, b, cur_byte = 0, 0, nil

            repeat cur_byte = self:nextByte()
                local band_byte = bit32.band(cur_byte, 127)

                result = bit32.bor(
                    result, 
                    bit32.lshift(band_byte, b)
                )
                
                b = b + 7
            until (not bit32.btest(cur_byte, 128))

            return result
        end

        function packetFunctions:nextString()
            local result, len = "", self:nextVarInt64()

            for _ = 1, len do
                result = result .. self:nextChar()
            end

            return result
        end

        function packetFunctions:nextFloat()
            local bytes = {} do
                for i = 1, 4 do
                    table.insert(bytes, self:nextByte())
                end
            end

            local str = "" do
                for i = 1, 4 do
                    str = str .. string.char(bytes[4 - (i - 1)])
                end
            end

            return string.unpack("<f", str)
        end

        function packetFunctions:nextDouble()
            local bytes = {} do
                for i = 1, 8 do
                    table.insert(bytes, self:nextByte())
                end
            end

            local str = "" do
                for i = 1, 8 do
                    str = str .. string.char(bytes[8 - (i - 1)])
                end
            end

            return string.unpack("<d", str)
        end

        function packetFunctions:nextObject()
            local objectType = self:nextByte()

            if objectType == types["Instance"] then
                return self:nextInstance()
            elseif objectType == types["Table"] then
                local tbl = {} do
                    for i = 1, self:nextVarInt64() do
                        table.insert(tbl, self:nextObject())
                    end
                end

                return tbl
            elseif objectType == types["Double"] then
                return self:nextDouble()
            elseif objectType == types["Boolean"] then
                return self:nextByte() == 1
            elseif objectType == types["String"] then
                return self:nextString()
            elseif objectType == types["EMTInst"] then
                return {
                    peerId = 0;
                    id     = 0;
                    bytes  = {0}
                }
            end
        end

        function packetFunctions:nextInstance()
            local instanceTbl, startPos, peerId = {}, self.pos, self:nextVarInt64()

            if peerId == 0 then
                instanceTbl.peerId  = 0;
                instanceTbl.id      = 0;
                instanceTbl.bytes   = {} do
                    for i = startPos, (self.pos - 1) do
                        table.insert(instanceTbl.bytes, self.bytes[i])
                    end
                end
                return instanceTbl
            end

            instanceTbl.peerId  = peerId
            instanceTbl.id      = self:nextUInt32LE()
            instanceTbl.bytes   = {} do
                for i = startPos, (self.pos - 1) do
                    table.insert(instanceTbl.bytes, self.bytes[i])
                end
            end

            return instanceTbl
        end
    end

    function packetReader:new(bytes, pos)
        bytes = bytes or {}
        pos   = pos   or 1

        return setmetatable({
            bytes = bytes;
            pos   = pos;
        }, packetFunctions)
    end
end

return packetReader
