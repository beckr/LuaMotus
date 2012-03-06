-- @File       : motus.lua
-- @Author     : Raphaël BECK
-- @Date       : 10/10/11
-- @Description: An implementation of the game motus

require("iuplua")  -- Doc: http://www.tecgraf.puc-rio.br/iup/
require("cdlua")   -- Doc: http://www.tecgraf.puc-rio.br/cd/
require("iupluacd")

words = {"indulgence", "student", "safety", "freshly", "calendar", "september", "open"}
word, lastWord = "", ""

function randomWord()
	repeat
		word = words[math.random(#words)]
	until word ~= lastWord
	lastWord = word
end

randomWord()

cnvas         = iup.canvas {}                     -- The canvas on which we draw
textBox       = iup.text {size="120x0", NC=#word} -- A text box for the word of the user
okButton      = iup.button {title="Ok"}           -- A button for user submit
newGameButton = iup.button {title="New game"}     -- A button for a new game
rulesButton   = iup.button {title="Show rules"}   -- A button for showing the rules
vbox          = iup.vbox {iup.hbox {newGameButton, rulesButton}, cnvas, iup.hbox {iup.label{title = "Type your guess: "}, textBox,  okButton}} -- Layouts managers
dlg           = iup.dialog{vbox; title="Motus", size="HALFxHALF", resize="NO"} -- The main window

red = cd.EncodeColor(255, 0, 0)
yel = cd.EncodeColor(250, 255, 10)
blk = cd.EncodeColor(0, 0, 0)

------------------------
-- Private values     --
_currentLine = 1
_stopGame    = false
_userWin     = false
-- End private values --
------------------------

shots       = 5            -- Number of user shots
currentLine = _currentLine -- Number of the current line on which to draw
stopGame    = _stopGame    -- Indicate Whether the game is finished
userWin     = _userWin     -- Indicate if the user has win
grid        = {}           -- The grid of data

-- Function      rulesButton:action
-- @param:       Nothing (self implicit)
-- @returns:     Nothing
-- @description: Display the rules on the click
function rulesButton:action()
	rules = "The motus game rules are easy:\n-You have "..shots.." shots to find the mysterious word.\n-Every time a letter is well placed it's colored in red"
	rules = rules.."\n-If a letter is present in the word but it's bad placed it's appears in yellow but only one time!\n  For example: if you type 2 'e' and "
	rules = rules.."the word contains a 'e', only one will be in yellow."
	rules = rules.."\nTIP: The first letter is given to you :)"
	iup.Message("Rules", rules)
end

-- Function      inString
-- @param:       A string, A char
-- @returns:     A boolean
-- @description: Whether the char is present in the string, just a helper actually
function inString(s, v)
	if #s == 0 or #v > 1 then
		return false
	end

	for i=1, #s do
		if v == string.sub(s,i,i) then
			return true
		end
	end

	return false
end

--Representation of a cell, only for indication actually not used because of Lua variable by reference system
cell = {
	letter = "",
	color  = nil,
	isWellPlace = false,
	isPresent   = false
}


-- Function      initGrid
-- @param:       Nothing
-- @returns:     Nothing
-- @description: Initialize the grid of data
function initGrid()
	grid = {cols  = #word}
	grid.lines = {}
	for i=1, shots do
		grid.lines[i] = {alreadyWellPlaced=""}
		for j=1, grid.cols do
			grid.lines[i][j] = {
			letter = "",
			color  = blk,
			isWellPlace = false,
			isPresent   = false
		}
		end

		grid.lines[i][1].letter = string.sub(word,1,1)
		grid.lines[i][1].color = red
		grid.lines[i][1].isWellPlace = true

	end
end
initGrid()

-- Function      drawGrid
-- @param:       Nothing
-- @returns:     Nothing
-- @description: Draw the grid of data
function drawGrid()
	canvas:Clear()
	canvas:SetForeground(blk)
	local w, h = cnvas.width, cnvas.height
	local colW, linH = w/(grid.cols), h/shots

	x = colW
	for i=1, grid.cols do
		canvas:Line(x, 0, x, h)
		x = x+colW
	end

	y = linH
	for i=1, shots do
		canvas:Line(0, y, w, y)
		y = y+linH
	end

	canvas:Font("Helvetica", cd.PLAIN, 32)
	canvas:TextAlignment(cd.CENTER)
	yPad = (linH / 2)
	xPad = colW / 2
	y = h - yPad
	x = xPad
	for i=1, shots do
		for j=1, grid.cols do
			local cell = grid.lines[i][j]
			if cell.letter ~= "" then
				canvas:SetForeground(cell.color)
				canvas:Text(x, y, cell.letter:upper())
			end
			x = x + colW
		end
		y = y - linH
		x = xPad
	end
end

-- Function      cnvas.map_cb
-- @param:       The parent (implicit)
-- @returns:     A number
-- @description: Called right after an element is mapped and its layout updated (This sentence (not the code) was copied from the doc)
function cnvas:map_cb() --
	canvas = cd.CreateCanvas(cd.IUP, self) -- Create the canvas
	return iup.DEFAULT
end

-- Function      cnvas.action
-- @param:       The parent (implicit)
-- @returns:     A canvas
-- @description: Called every time the canvas need to be redrawn
function cnvas:action()
--~ 	if stopGame then
--~ 		return
--~ 	end

	canvas:Activate()
	w, h, mm_w, mm_h = canvas:GetSize() -- mm_w & mm_h are in this case because I don't use it
	cnvas.width, cnvas.height  = w, h
	canvas:Clear()

	drawGrid()

	return cnvas
end

-- Function      isGameOver
-- @param:       Nothing
-- @returns:     A boolean
-- @description: Indicate whether the game is over or not and set if the user has win
function isGameOver()
	if stopGame then
		return true
	end

	if currentLine-1 == shots then -- -1 because indexes start at 1 and the first line count as a shot
		stopGame = true
	end

	return stopGame
end

-- Function      textBox:valuechanged_cb
-- @param:       Parent (implicit)
-- @returns:     Nothing
-- @description: Callback for the textBox, called right after a user type into
function textBox:valuechanged_cb()
	value = textBox.value
	if value:find("%W") then
		textBox.value = string.sub(value, 1, #value-1)
		textBox.caret = "500" -- The value of caret must be a string and can't be an expression. So with 500 it always place the caret at the end
	end
end

-- Function      okButton:action
-- @param:       Parent (implicit)
-- @returns:     Nothing
-- @description: Callback for the okButton, called right after a user click on it
function okButton:action()
	if isGameOver() then
		endMsg = userWin and "You Win!" or "You loose!"
		iup.Message("Game Over", endMsg)
		return
	end

	if #textBox.value < grid.cols then
		iup.Message("Error", "Enter at least "..#word.." characters!")
		return
	end

	local sub     = string.sub
	local tInsert = table.insert


	for i=1, grid.cols do
		local letter     = sub(value, i, i)
		local wordLetter = sub(word, i, i)

		grid.lines[currentLine][i].letter = letter
		grid.lines[currentLine][i].color = blk

		if letter == wordLetter then
			grid.lines[currentLine][i].color = red
			grid.lines[currentLine][i].isWellPlace = true
			grid.lines[currentLine].alreadyWellPlaced = grid.lines[currentLine].alreadyWellPlaced..letter
		elseif inString(word, letter) and not inString(grid.lines[currentLine].alreadyWellPlaced, letter) then
			grid.lines[currentLine][i].color = yel
			grid.lines[currentLine][i].isPresent = true
			grid.lines[currentLine].alreadyWellPlaced = grid.lines[currentLine].alreadyWellPlaced..letter
		end
		--TODO: Bug si une lettre est dans le mot elle devient jaune mais si par la suite elle a été trouvée elle est également rouge
	end

	allWellPlaced = true
	for i=1, grid.cols do
		allWellPlaced = allWellPlaced and grid.lines[currentLine][i].isWellPlace
	end

	userWin = userWin or allWellPlaced
	if userWin then
		stopGame = true
		iup.Redraw(cnvas, 0)
		iup.Message("Game Over", "You Win!")
		return
	end

	if isGameOver() then
		iup.Redraw(cnvas, 0)
		endMsg = userWin and "You Win!" or "You loose!"
		iup.Message("Game Over", endMsg)
		return
	end

	currentLine = currentLine + 1

	iup.Redraw(cnvas, 0)
end

-- Function      newGameButton:action
-- @param:       Parent (implicit)
-- @returns:     Nothing
-- @description: Callback for the  newGameButton, called right after a user click on it. Set a new game.
function newGameButton:action()
	randomWord()
	currentLine = _currentLine
	stopGame    = _stopGame
	userWin     = _userWin
	grid        = {}
	initGrid()
	textBox.value = ""
	textBox.NC = #word
	iup.Redraw(cnvas, 0)
end

dlg:show()
if (iup.MainLoopLevel()==0) then
	iup.MainLoop()
end
