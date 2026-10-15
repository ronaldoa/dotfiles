" gtags module for Gutentags that feeds cscope_maps.nvim
"
" Same as the bundled gtags_cscope module, but without the built-in cscope
" (removed in Neovim 0.9): the GTAGS db goes to g:gutentags_cache_dir and
" cscope_maps is pointed at it through g:cscope_maps_db_file.

let s:runner_exe = gutentags#get_plat_file('update_gtags')

function! gutentags#gtags_maps#init(project_root) abort
    let l:db_path = gutentags#get_cachefile(a:project_root, 'gtags')
    if !isdirectory(l:db_path)
        call mkdir(l:db_path, 'p')
    endif
    let b:gutentags_files['gtags_maps'] = gutentags#normalizepath(l:db_path . '/GTAGS')
    call gutentags#gtags_maps#activate()
endfunction

" Point gtags-cscope / cscope_maps at the current buffer's project
function! gutentags#gtags_maps#activate() abort
    let l:db_file = get(get(b:, 'gutentags_files', {}), 'gtags_maps', '')
    if empty(l:db_file)
        return
    endif
    let $GTAGSDBPATH = fnamemodify(l:db_file, ':h')
    let $GTAGSROOT = gutentags#stripslash(b:gutentags_root)
    let g:cscope_maps_db_file = l:db_file . '::' . $GTAGSROOT
endfunction

function! gutentags#gtags_maps#generate(proj_dir, tags_file, gen_opts) abort
    let l:cmd = [s:runner_exe, '-e', 'gtags']
    let l:file_list_cmd = gutentags#get_project_file_list_cmd(a:proj_dir)
    if !empty(l:file_list_cmd)
        let l:cmd += ['-L', '"' . l:file_list_cmd . '"']
    endif
    let l:cmd += ['--incremental', '"' . fnamemodify(a:tags_file, ':p:h') . '"']
    let l:cmd = gutentags#make_args(l:cmd)

    call gutentags#trace("Running: " . string(l:cmd))
    if !g:gutentags_fake
        let l:job_opts = gutentags#build_default_job_options('gtags_maps')
        let l:job = gutentags#start_job(l:cmd, l:job_opts)
        call gutentags#add_job('gtags_maps', a:tags_file, l:job)
    endif
endfunction

function! gutentags#gtags_maps#on_job_exit(job, exit_val) abort
    let l:job_idx = gutentags#find_job_index_by_data('gtags_maps', a:job)
    call gutentags#remove_job('gtags_maps', l:job_idx)
    if a:exit_val != 0 && !g:__gutentags_vim_is_leaving
        call gutentags#warning("gtags job failed, returned: " . string(a:exit_val))
    endif
endfunction
