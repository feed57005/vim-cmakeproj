" cmakeproj.vim - helper plugin for cmake projects
" Maintainer:   Pavel Novy
" Version:      0.1

if exists('g:loaded_cmakeproj') || &cp
  finish
endif
let g:loaded_cmakeproj = 1

if !exists('g:cmakeproj_cmake_bin')
  let g:cmakeproj_cmake_bin = 'cmake'
endif

if !exists('g:cmakeproj_default_generator')
  let g:cmakeproj_default_generator = 'ninja'
endif

if !exists('g:cmakeproj_build_root')
  let g:cmakeproj_build_root = '_build'
endif

let s:build_root = g:cmakeproj_build_root
let s:generator = g:cmakeproj_default_generator
let s:build_type = 'debug'
let s:platform = ''
let s:target = ''
let s:build_dir = ''

if has('win32')
  let s:sep = '\'
else
  let s:sep = '/'
endif

function s:DetectPlatform() abort
  if has('win32') || has('win64')
    let s:platform = 'win'
  elseif has('mac') || has('macunix')
    let s:platform = 'osx'
  elseif has('unix')
    let s:platform = 'linux'
  endif
  "echo s:platform
endfunction

function! s:SetBuildTypeComplete(A,L,P) abort
  let opts = ['debug', 'release']
  return filter(sort(opts), 'strpart(v:val, 0, strlen(a:A)) ==# a:A')
endfunction

function! s:GenBuildDir() abort
  return getcwd() . s:sep . s:build_root . s:sep . s:generator.'-'.s:build_type.'-'.s:platform
endfunction

function! s:UpdateMakePrg() abort
  let s:build_dir = s:GenBuildDir()
  let &makeprg = "ninja\ -C\ ".s:build_dir
  if s:target != ''
    let &makeprg .= ' '.s:target
  endif
endfunction

function! s:SetBuildType(build_type) abort
  let s:build_type = a:build_type
  call s:UpdateMakePrg()
endfunction

function! s:SetBuildTargetComplete(A,L,P) abort
  let targets = map(filter(split(system(s:generator.' -C '.s:build_dir.' help'), "\n"), 'v:val =~ ": phony"'), 'substitute(v:val, ": phony", "", "")')
  return filter(sort(targets), 'strpart(v:val, 0, strlen(a:A)) ==# a:A')
endfunction

function! s:SetBuildTarget(target) abort
  let s:target = a:target
  call s:UpdateMakePrg()
endfunction

function! s:RunCMake() abort
  for type_pair in [['debug', 'Debug'], ['release', 'Release']]
    if type_pair[0] == s:build_type
      let cmake_args = ' -DCMAKE_BUILD_TYPE='.type_pair[1]
    endif
  endfor
  for gen_pair in [['ninja', 'Ninja'], ['make', 'Unix Makefiles']]
    if gen_pair[0] == s:generator
      let cmake_generator =' -G "'.gen_pair[1].'"'
    endif
  endfor
  silent execute '!mkdir -p '. s:build_dir
  execute '!cd '.s:build_dir.' && '.g:cmakeproj_cmake_bin.cmake_generator.cmake_args.' ../..'
endfunction

command! -nargs=1 -complete=customlist,s:SetBuildTypeComplete BuildType :execute s:SetBuildType(<q-args>)
command! -nargs=1 -complete=customlist,s:SetBuildTargetComplete BuildTarget :execute s:SetBuildTarget(<q-args>)
command! -nargs=0 RunCMake :execute s:RunCMake()

call s:DetectPlatform()
call s:UpdateMakePrg()
