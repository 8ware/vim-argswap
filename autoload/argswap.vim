
" common
let g:argswap_quotes = "'|\""
let g:argswap_quotes_end = { "'": "'", '"': '"' }
" lua
let g:argswap_quotes .= "|[["
let g:argswap_quotes_end["[["] = "]]"


" TODO quoted string, escaped quotes
" Argswap(3, 8, 2)
" command Argswap call argswap#Argswap(getline("."))
" command Argswap call argswap#Argswap() range
" TODO here-documents as arguments
function! argswap#Argswap()
"function! argswap#Argswap(how)
"	if !a:how:0
"		a:how = [ 0, 1 ]
"	end
	let line = getline(".")

	" tokenize 
	let [ tokens, positions ] = argswap#Tokenize(line)
"	echo positions
	echo tokens

	" TODO do not match quoted parantheses
"	let tokens[0] = substitute(tokens[0], "^[^(]*(", "", "")
	let tokens[len(tokens)-1] = substitute(tokens[len(tokens)-1], ").*$", "", "")
	echo tokens

	let [ b, l, c, o, x ] = getcurpos()
	echo c

	let pos = positions[c]
	"let tmp = tokens[pos]
	"let tokens[pos] = tokens[pos+1]
	"let tokens[pos+1] = tmp
	"unlet tmp
	let pos2 = pos+1
	let length = len(tokens)
	let pos2 = pos2 % length
	echo pos
	echo pos2

	echo "swap '" . tokens[pos] . "' with '" . tokens[pos2] . "'"
	echo tokens
	let oldtokens = deepcopy(tokens)

	let norm_token_1 = substitute(tokens[pos],   '^\s\+\|\s\+$', "", "g")
	let norm_token_2 = substitute(tokens[pos2], '^\s\+\|\s\+$', "", "g")
	echo "nt1: " . norm_token_1
	echo "nt2: " . norm_token_2
	echo "substitute(" . tokens[pos] . ", " . norm_token_1 . ", " . norm_token_2 . ")"
	let tokens[pos] = substitute(tokens[pos], norm_token_1, norm_token_2, "")
	let tokens[pos2] = substitute(tokens[pos2], norm_token_2, norm_token_1, "")
	echo tokens
	let newarglist = substitute(line, join(oldtokens, ","), join(tokens, ",") , "")
	echo line
	echo newarglist


	" 'func(asd, ", \" ", bcd) s/(\s*)(\w.[^,]+)(,\s*)(\w.[^,]+)/$1$4$3$2/
	"let s:args = split(s:line, ",") ", 1)
	"echo join(s:args, "||")

	
	"if s:args[0] =~ "("
	"for e in s:args
		
	"endfor
endfunction

function! argswap#Tokenize(string)
	let quoted = ""
	let token = ""
	let tokens = []
	let positions = {}
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
			continue
		elseif char == ","
			let tokens += [ token ]
			let token = ""
			continue
		end
		let token .= a:string[idx]
		let positions[idx] = len(tokens)
	endfor
	if strlen(token) > 0
		let tokens += [ token ]
	end
	
	return [ tokens, positions ]
endfunction

