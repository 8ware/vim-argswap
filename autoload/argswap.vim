
" common
let g:argswap_quotes = "'|\""
let g:argswap_quotes_end = { "'": "'", '"': '"' }
" lua
let g:argswap_quotes .= "|[["
let g:argswap_quotes_end["[["] = "]]"


let s:STAY = 0
let s:COLUMN = 2

let s:LEADING_SPACES  = 0
let s:TRIMMED_TOKEN   = 1
let s:TRAILING_SPACES = 2

let s:FORWARD  = +1
let s:BACKWARD = -1


"
" TODO quoted string, escaped quotes
" Argswap(3, 8, 2)
" command Argswap call argswap#Argswap(getline("."))
" command Argswap call argswap#Argswap() range
" TODO here-documents as arguments
"
"function! argswap#Argswap(how)
"	if !a:how:0
"		a:how = [ 0, 1 ]
"	end
function! argswap#Argswap(...)
	let direction = s:FORWARD
	if a:0 > 0
		let direction = a:1
	end

	let line = getline(".")

	let [ tokens, positions, inverse ] = argswap#Tokenize(line)

	let length = len(tokens)

	" delete trailing parentheses
	let tokens[length-1] = substitute(tokens[length-1], ").*$", "", "")

	let cursor = getcurpos()
	let c = cursor[s:COLUMN]

	let pos1 = positions[c]
	let pos2 = pos1 + direction
	let pos2 = pos2 % length

	let oldtokens = deepcopy(tokens)

	let token1 = argswap#SplitToken(tokens[pos1])
	let token2 = argswap#SplitToken(tokens[pos2])
	
	let tokens[pos1] = substitute(tokens[pos1], token1[s:TRIMMED_TOKEN], token2[s:TRIMMED_TOKEN], "")
	let tokens[pos2] = substitute(tokens[pos2], token2[s:TRIMMED_TOKEN], token1[s:TRIMMED_TOKEN], "")

	let offset = s:STAY
	if direction != 0
		let start = inverse[direction > 0 ? pos1 : pos2][0]
		let offset = argswap#CalcCursor(direction, token1, token2, start, positions, line, c)
	end

	" TODO use \V to match exact string
	"      (turn off special meanings as done with \Q in perl)
	exec 's/\V' . join(oldtokens, ",") . '/' . join(tokens, ",")
	call cursor(s:STAY, offset)
endfunction

function! argswap#Tokenize(string)
	let quoted = ""
	let token = ""
	let tokens = []
	let positions = {}
	let inverse = {}
	for idx in range(strlen(a:string))
		let char = a:string[idx]
		if strlen(quoted)
			if char == '\'
				let token .= char
				let idx += 1
			elseif char == quoted
"			elseif char == g:argswap_quotes_end[quoted]
				let quoted = ""
			end
		elseif char == '"' || char == "'"
"		elseif char =~ g:argswap_quotes
			let quoted = char
		elseif char == "(" && len(tokens) == 0
			let token = ""
			let positions = {}
			let inverse = {}
			continue
"		elseif char == ")"
"			break
		elseif char == ","
			let tokens += [ token ]
			let token = ""
			continue
		end
		let token .= a:string[idx]

		let curtokidx = len(tokens)
		let positions[idx] = curtokidx
		if !exists("inverse[curtokidx]")
			let inverse[curtokidx] = []
		end
		let inverse[curtokidx] += [ idx ]
	endfor
	if strlen(token) > 0
		let tokens += [ token ]
	end
	
	return [ tokens, positions, inverse ]
endfunction

function! argswap#SplitToken(token)
	let result = matchlist(a:token, '^\(\s*\)\(.\{-1,}\)\(\s*\)$')

	let arg = {}
	let arg[s:LEADING_SPACES]  = result[1]
	let arg[s:TRIMMED_TOKEN]   = result[2]
	let arg[s:TRAILING_SPACES] = result[3]

	return arg
endfunction

function! argswap#CalcCursor(direction, token1, token2, start, positions, line, cpos)
	" 1. find cursor position in current argument
	let x = a:cpos
	while exists("a:positions[x-1]")
		let x -= 1
	endwhile
	let y = x
	while a:line[y] == " "
		let y += 1
	endwhile
	let offset = a:cpos - y
	" TODO handle case when cursor is at spaces of arg
	if offset < 0
		let offset = 0
	end

	" 2. calculate offset
	if a:direction > 0
		let offset += a:start
		let offset += strlen(a:token1[s:LEADING_SPACES])
		let offset += strlen(a:token2[s:TRIMMED_TOKEN])
		let offset += strlen(a:token1[s:TRAILING_SPACES])
		let offset += 1 " for the separating comma
		let offset += strlen(a:token2[s:LEADING_SPACES])
	elseif a:direction < 0
		let offset += a:start
		let offset += strlen(a:token2[s:LEADING_SPACES])
	else
		let offset = s:STAY
	end

	return offset
endfunction

