local packetWriter = {} do
    local packetFunctions = {} do
		packetFunctions.__index = packetFunctions
        function packetFunctions:writeByte(val)
            table.insert(self.bytes, val);
        end

        function packetFunctions:writeChar(val)
            table.insert(self.bytes, string.byte(val));
        end

        function packetFunctions:writeBytes(val)
            for i = 1, #val do
                table.insert(self.bytes, val[i]);
            end
        end

        function packetFunctions:writeString(str)
            self:writeVarInt64(string.len(str));
            for i = 1, string.len(str) do
                self:writeChar(str:sub(i, i));
            end
        end

        function packetFunctions:writeUInt16LE(val)
            self:writeBytes({
                bit32.band(val, 255),
                bit32.band(bit32.rshift(val, 8), 255)
            });
        end

        function packetFunctions:writeUInt16BE(val)
            self:writeBytes({
                bit32.band(bit32.rshift(val, 8), 255),
                bit32.band(val, 255)
            });
        end

        function packetFunctions:writeUInt32LE(val)
            self:writeBytes({
                bit32.band(val, 255),
                bit32.band(bit32.rshift(val, 8), 255),
                bit32.band(bit32.rshift(val, 16), 255),
                bit32.band(bit32.rshift(val, 24), 255)
            });
        end

        function packetFunctions:writeUInt32BE(val)
            self:writeBytes({
                bit32.band(bit32.rshift(val, 24), 255),
                bit32.band(bit32.rshift(val, 16), 255),
                bit32.band(bit32.rshift(val, 8), 255),
                bit32.band(val, 255)
            });
        end

        function packetFunctions:writeUInt64LE(val)
            self:writeBytes({
                bit32.band(val, 255),
                bit32.band(bit32.rshift(val, 8), 255),
                bit32.band(bit32.rshift(val, 16), 255),
                bit32.band(bit32.rshift(val, 24), 255),
                bit32.band(bit32.rshift(val, 32), 255),
                bit32.band(bit32.rshift(val, 40), 255),
                bit32.band(bit32.rshift(val, 48), 255),
                bit32.band(bit32.rshift(val, 56), 255)
            });
        end

        function packetFunctions:writeUInt64BE(val)
            self:writeBytes({
                bit32.band(bit32.rshift(val, 56), 255),
                bit32.band(bit32.rshift(val, 48), 255),
                bit32.band(bit32.rshift(val, 40), 255),
                bit32.band(bit32.rshift(val, 32), 255),
                bit32.band(bit32.rshift(val, 24), 255),
                bit32.band(bit32.rshift(val, 16), 255),
                bit32.band(bit32.rshift(val, 8), 255),
                bit32.band(val, 255)
            });
        end

        function packetFunctions:writeVarInt64(val)
            local value = val;
            repeat
                local v = bit32.band(value, 127);
                value = bit32.rshift(value, 7);
                if not (value <= 0) then
                    v = bit32.bor(v, 128)
                end
                self:writeByte(v);
            until (value <= 0)
        end

        function packetFunctions:writeFloatLE(val)
            local bytes = {}
            local str = string.pack("<f", val);
            for i = 1, 4 do
                table.insert(bytes, str:byte(i, i));
            end
            for i = 1, 4, -1 do
                self:writeByte(bytes[i]);
            end
        end

        function packetFunctions:writeFloatBE(val)
            local bytes = {}
            local str = string.pack("<f", val);
            for i = 1, 4 do
                table.insert(bytes, str:byte(i, i));
            end
            for i = 4, 1, -1 do
                self:writeByte(bytes[i]);
            end
        end

        function packetFunctions:writeDoubleBE(val)
            local bytes = {}
            local str = string.pack("<d", val);
            for i = 1, 8 do
                table.insert(bytes, str:byte(i, i));
            end
            for i = 8, 1, -1 do
                self:writeByte(bytes[i]);
            end
        end
    end

    function packetWriter:new(bytes)
        local bytes = bytes or {}
        return setmetatable({
            bytes = bytes
        }, packetFunctions)
    end

    packetWriter.packetFunctions = packetFunctions
end

return packetWriter
