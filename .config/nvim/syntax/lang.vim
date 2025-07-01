if exists("b:current_syntax")
  finish
endif

" Keywords and core syntax
syntax keyword mydslKeyword fn return extern if else for struct as in
syntax keyword mydslType int float char bool void
syntax keyword mydslBoolean true false

" Match identifiers, numbers, characters, strings
syntax match mydslIdentifier /\<[a-zA-Z_][a-zA-Z0-9_]*\>/
syntax match mydslNumber /\<\d\+\>/
syntax match mydslChar /'\w'/
syntax match mydslString /"\([^"\\]\|\\.\)*"/
syntax match mydslFieldType /\v:\s*\zs\w+/ containedin=ALL

" Comments — use syntax region instead of match for better control
syntax region mydslComment start="//" end="$" contains=NONE containedin=ALL transparent

" Operators (put after comment syntax!)
syntax match mydslOperator /[-+*\/%=<>!&|]/

" Highlight linking
highlight link mydslKeyword Keyword
highlight link mydslType Type
highlight link mydslBoolean Boolean
highlight link mydslIdentifier Identifier
highlight link mydslNumber Number
highlight link mydslChar Character
highlight link mydslString String
highlight link mydslComment Comment
highlight link mydslOperator Operator
highlight link mydslFieldType Type

let b:current_syntax = "lang"

