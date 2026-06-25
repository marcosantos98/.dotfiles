" Syntax highlighting for Lang (.lang)
" https://github.com/... — see language.md for grammar

if exists('b:current_syntax')
  finish
endif

syn case match

" --- Keywords ----------------------------------------------------------------
syn keyword langStatement  break return if else for in import
syn keyword langStatement  fn extern extype struct type as
syn keyword langStorage    dyn
syn keyword langType       void int bool char string cstr any rawptr
syn keyword langType       u8 u32 u64 f32
syn keyword langConstant   nil true false
syn keyword langBuiltin    len listof append reset free sizeof

" --- Literals ----------------------------------------------------------------
syn match  langNumber      display containedin=ALLBUT,langComment,langString,langCString,langChar /\<\d\+\>/
syn match  langFloat       display containedin=ALLBUT,langComment,langString,langCString,langChar /\<\d\+\.\d\+\([eE][+-]\?\d\+\)\?\>/
syn match  langPointer     display containedin=ALLBUT,langComment,langString,langCString,langChar /\^\+/
syn match  langVariadic    display containedin=ALLBUT,langComment,langString,langCString,langChar /\.\.\./

syn match  langEscape      display contained /\\[nrt\\'"0]/
syn region langString      start=/"/ skip=/\\./ end=/"/ contains=langEscape
syn region langCString     start=/c"/ skip=/\\./ end=/"/ contains=langEscape
syn region langChar        start=/'/ end=/'/ skip=/\\./ contains=langEscape

" --- Operators & delimiters --------------------------------------------------
syn match langAssignOp      display containedin=ALLBUT,langComment,langString,langCString,langChar /:\=\|[+\-*\/%]=/
syn match langCompareOp     display containedin=ALLBUT,langComment,langString,langCString,langChar /==\|!=/
syn match langLogAnd        display containedin=ALLBUT,langComment,langString,langCString,langChar /&&/
syn match langOperator      display containedin=ALLBUT,langComment,langString,langCString,langChar /[+\-*\/%<>!&|^$]/
syn match langDelimiter     display containedin=ALLBUT,langComment,langString,langCString,langChar /[][;(),]/
syn match langBrace         display containedin=ALLBUT,langComment,langString,langCString,langChar /[{}]/
syn match langLabel         display containedin=ALLBUT,langComment,langString,langCString,langChar /\./

" --- Comments (after `/` operator so `//` wins) ------------------------------
syn keyword langTodo         TODO FIXME NOTE contained
syn region  langComment      start='//' end='$' keepend contains=langTodo,@Spell

" --- Identifiers (after keywords) --------------------------------------------
syn match langIdentifier    display containedin=ALLBUT,langComment,langString,langCString,langChar contains=NONE /\<\h\w*\>/

" --- Highlight links ---------------------------------------------------------
highlight default link langStatement   Statement
highlight default link langStorage     StorageClass
highlight default link langType        Type
highlight default link langConstant    Constant
highlight default link langBuiltin     Function
highlight default link langNumber      Number
highlight default link langFloat       Float
highlight default link langPointer     Special
highlight default link langVariadic    Special
highlight default link langString      String
highlight default link langCString     String
highlight default link langChar        Character
highlight default link langEscape      SpecialChar
highlight default link langComment     Comment
highlight default link langTodo        Todo
highlight default link langAssignOp    Operator
highlight default link langCompareOp   Operator
highlight default link langLogAnd      Operator
highlight default link langOperator    Operator
highlight default link langDelimiter   Delimiter
highlight default link langBrace       Delimiter
highlight default link langLabel       Operator
highlight default link langIdentifier  Identifier

let b:current_syntax = 'lang'
