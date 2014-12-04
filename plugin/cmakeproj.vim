" cmakeproj.vim - helper plugin for cmake projects
" Maintainer:   Pavel Novy
" Version:      0.2

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

let s:cmake_root = getcwd()
let s:build_root = g:cmakeproj_build_root " relative path
let s:generator = g:cmakeproj_default_generator
let s:build_type = 'debug'
let s:platform = ''
let s:target = ''
let s:build_dir = ''
let s:prefix = ''
let s:crossplatform = ''
let s:build_types = [
	\['debug', 'Debug'],
	\['release', 'Release']]
let s:cmake_generators = [
	\['ninja', 'Ninja'],
	\['make', 'Unix Makefiles']]

let s:build_types = ['debug', 'release']
let s:build_types_cmake = ['Debug', 'Release']

let s:build_generators = ['ninja', 'make']
let s:build_generators_cmake = ['Ninja', 'Unix Makefiles']

if has('win32')
  let s:sep = '\'
else
  let s:sep = '/'
	if has('mac') || has('macunix')
		let s:build_generators += ['xcode']
		let s:build_generators_cmake += ['Xcode']
	endif
endif

function s:DetectPlatform() abort
  if has('win32') || has('win64')
    let s:platform = 'win'
  elseif has('mac') || has('macunix')
    let s:platform = 'osx'
  elseif has('unix')
    let s:platform = 'linux'
	else
		throw 'vim-cmakeproj: Unknown platform'
  endif
  "echo s:platform
endfunction

function! s:UpdateMakePrg() abort
  let s:build_dir = s:cmake_root . s:sep . s:build_root . s:sep . s:generator.'-'.s:build_type.'-'.s:platform
  let &makeprg = s:generator."\ -C\ ".s:build_dir
  if s:target != ''
    let &makeprg .= ' '.s:target
  endif
endfunction

function! s:cmd_CMakeGeneratorComplete(A,L,P) abort
  let opts = copy(s:build_generators)
  return filter(sort(opts), 'strpart(v:val, 0, strlen(a:A)) ==# a:A')
endfunction

function! s:cmd_CMakeGenerator(generator) abort
	if a:generator == ''
		echo s:generator
		return
	endif
	if index(s:build_generators, a:generator) == -1
		throw 'Unknown build generator: '. a:generator
	endif
	let s:generator = a:generator
	echo 'CMake Generator: '.s:generator
	call s:UpdateMakePrg()
endfunction

function! s:cmd_CMakeBuildTypeComplete(A,L,P) abort
  let opts = copy(s:build_types)
  return filter(sort(opts), 'strpart(v:val, 0, strlen(a:A)) ==# a:A')
endfunction

function! s:cmd_CMakeBuildType(build_type) abort
	if a:build_type == ''
		echo s:build_type
		return
	endif
	if index(s:build_types, a:build_type) == -1
		throw 'Unknown build type: '. a:build_type
	endif

  let s:build_type = a:build_type
	echo 'CMake Build Type: '.s:build_type
  call s:UpdateMakePrg()
endfunction

function! s:cmd_CMakeTargetComplete(A,L,P) abort
  let targets = map(filter(split(system(s:generator.' -C '.s:build_dir.' help'), "\n"), 'v:val =~ ": phony"'), 'substitute(v:val, ": phony", "", "")')
  return filter(sort(targets), 'strpart(v:val, 0, strlen(a:A)) ==# a:A')
endfunction

function! s:cmd_CMakeTarget(target) abort
	if a:target == ''
		echo s:target
		return
	endif
  let s:target = a:target
	echo 'CMake Target: '.s:target
  call s:UpdateMakePrg()
endfunction

function! s:cmd_CMakeInstallPrefix(prefix) abort
	if a:prefix == ''
		echo s:prefix
		return
	endif
  let s:prefix = a:prefix
	echo 'CMake Install Prefix: '.s:prefix
endfunction

function! s:cmd_CMakeSourceFromBuffer() abort
	echo fnamemodify(expand(bufname('%')), ":h")
	cd %:p:h
	let s:cmake_root = getcwd()
	call s:UpdateMakePrg()
endfunction

function! s:cmd_CMakeRun() abort
	" build type
	let idx = index(s:build_types, s:build_type)
	if idx != -1
		let cmake_args = ' -DCMAKE_BUILD_TYPE='.s:build_types_cmake[idx]
	endif
	" generator
	let idx = index(s:build_generators, s:generator)
	if idx != -1
      let cmake_args .=' -G "'.s:build_generators_cmake[idx].'"'
	endif
	" install prefix
  if s:prefix != ''
    let cmake_args .= ' -DCMAKE_INSTALL_PREFIX='.s:prefix
  endif
  silent execute '!mkdir -p '. s:build_dir
  "execute '!echo running cmake with args: '.cmake_args. ' '.s:generator
  execute '!cd '.s:build_dir.' && '.g:cmakeproj_cmake_bin.cmake_args.' ../..'
endfunction

function! s:cmd_CMakeClean() abort
	if s:build_dir == ''
		throw 'Build directory not set'
	endif
  execute '!rm -rf '. s:build_dir
endfunction

function! cmakeproj#CMakeOpenHelp()
  let s = getline( '.' )
  let i = col( '.' ) - 1
  while i > 0 && strpart( s, i, 1 ) =~ '[A-Za-z0-9_]'
    let i = i - 1
  endwhile
  while i < col('$') && strpart( s, i, 1 ) !~ '[A-Za-z0-9_]'
    let i = i + 1
  endwhile
  let start = match( s, '[A-Za-z0-9_]\+', i )
  let end = matchend( s, '[A-Za-z0-9_]\+', i )
  let ident = strpart( s, start, end - start )
  execute 'vertical new'
  execute '%!'.g:cmakeproj_cmake_bin.' --help-command '.ident
  set nomodified
  set readonly
endfunction

autocmd BufRead,BufNewFile *.cmake,CMakeLists.txt nmap <F1> :execute cmakeproj#CMakeOpenHelp()<CR>

command! -nargs=? -complete=customlist,s:cmd_CMakeGeneratorComplete CMGenerator :execute s:cmd_CMakeGenerator(<q-args>)
command! -nargs=? -complete=customlist,s:cmd_CMakeBuildTypeComplete CMBuildType :execute s:cmd_CMakeBuildType(<q-args>)
command! -nargs=? -complete=customlist,s:cmd_CMakeTargetComplete CMTarget :execute s:cmd_CMakeTarget(<q-args>)
command! -nargs=1 CMInstalPrefix :execute s:cmd_CMakeInstallPrefix(<q-args>)
command! -nargs=0 CMSourceFromBuffer :execute s:cmd_CMakeSourceFromBuffer()
command! -nargs=0 CMRun :execute s:cmd_CMakeRun()
command! -nargs=0 CMClean :execute s:cmd_CMakeClean()

call s:DetectPlatform()
call s:UpdateMakePrg()
