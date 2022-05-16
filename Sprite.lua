local Sprite = {
	extends = "Sprite",
}

function Sprite:_process(delta)
	self:rotate(delta)
end

return Sprite
