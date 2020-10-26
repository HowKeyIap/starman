class Vim < Package
  url 'https://github.com/vim/vim/archive/v8.2.0348.tar.gz'
  sha256 '63a178c80f1dfffd85071eaeec52b7614955237c4920aa726bef694a13ec440e'
  version '8.2.0348'
  file_name 'vim-8.2.0348.tar.gz'

  label :common

  option 'with-python', 'Build Python3 support.'

  depends_on :lua
  depends_on :python3 if with_python?
  depends_on :ncurses

  resource :neocomplete do
    # This plugin is not compatible with above Vim 8.2.1066!
    url 'https://github.com/Shougo/neocomplete.vim/archive/4be617947f3fcf2d725fab20b0e12f8b46c9e2f3.zip'
    sha256 '41ec5f593981d7455f482ea9adb68dbd31d3a93ef09f4a5be2135b9ad3398cc4'
    file_name 'neocomplete.4be617.zip'
  end

  resource :neosnippet_snippets do
    url 'https://github.com/Shougo/neosnippet-snippets/archive/e5946e9ec4c68965dbabfaaf2584b1c057738afd.zip'
    sha256 '9a8c4ba5228dbcd19ba73d1d179b730fd8fbe24751651eb08431720d5b90625d'
    file_name 'neosnippet_snippets.e5946e.zip'
  end

  resource :neosnippet do
    url 'https://github.com/Shougo/neosnippet.vim/archive/f7755084699db69ce9ff51c87baf8e639b7e543a.zip'
    sha256 'dfd39a8bfa40b18e8d90a084c77621db4dbd267e8fdf792ae27c1ac8934393e0'
    file_name 'neosnippet.f77550.zip'
  end

  resource :nerdtree do
    url 'https://github.com/scrooloose/nerdtree/archive/d6032c876c6d6932ab7f07e262a16c9a85a31d5b.zip'
    sha256 'b2c56084bd9636a9d720fefcc099fea7c6854f8f01b5402acc1c875e9eabe37f'
    file_name 'nerdtree.d6032c.zip'
  end

  resource :vim_ncl do
    url 'https://github.com/dongli/vim-ncl/archive/f4019ebe70df9f1bd2b9a491ea244a7d565f558a.zip'
    sha256 '042cf88d46ca99e436e43aa6778229cacd5ba86567127ae8e27d5baeccb6d441'
    file_name 'vim_ncl.f4019e.zip'
  end

  resource :numbertoggle do
    url 'https://github.com/jeffkreeftmeijer/vim-numbertoggle/archive/2.1.1.zip'
    sha256 '29212786f53743a55ac8f54f681e4287110e67da953f9cf615ba7eb4570b54ed'
    file_name 'numbertoggle.cfaecb9.zip'
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-multibyte
      --enable-gui=no
      --enable-cscope
      --enable-luainterp=yes
      --with-lua-prefix='#{Lua.prefix}'
      --without-x
      --with-features=huge
    ]
    if not OS.mac? and not CompilerSet.c.clang?
      args << "--with-tlib=ncurses CPPFLAGS='-I#{Ncurses.inc}' LDFLAGS='-L#{Ncurses.lib}'"
    end
    if CompilerSet.c.clang?
      inreplace 'src/auto/configure', {
        '#ifdef HAVE_STDINT_H' => "#include <stdlib.h>\n#ifdef HAVE_STDINT_H"
      }
    end
    if with_python?
      args << '--enable-python3interp=yes'
      args << "--with-python3-command='#{Python3.bin}/python3'"
    end
    run './configure', *args
    run 'make'
    run 'make', 'install', "prefix=#{prefix}", 'STRIP=true'
    ln "#{bin}/vim", "#{bin}/vi"
    # Install handy plugins.
    mkdir "#{share}/vim/vim82/pack/dist/start" do
      install_resource :neocomplete, '.'
      install_resource :neosnippet_snippets, '.'
      install_resource :neosnippet, '.'
      install_resource :nerdtree, '.'
      install_resource :vim_ncl, '.'
      install_resource :numbertoggle, '.'
    end
    # Create a vimrc for users.
    write_file "#{share}/vim/vimrc", <<-EOS
" Setup neocomplete and neosnippet.
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
" Left and right arrows are used to close popup menu.
imap <expr> <Left>  neocomplete#close_popup()."\<Left>"
imap <expr> <Right> neocomplete#close_popup()."\<Right>"
" When popup menu is open, close it or just print <CR>.
imap <expr> <CR>    pumvisible() ? neocomplete#close_popup() : "\<CR>"
" When popup menu is open, iterate the candidate options or expand expandables.
imap <expr> <TAB>   pumvisible() ? "\<C-n>" : neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#snippets_directory='~/.vim/snippets'
" Setup nerdtree.
autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
map <C-n> :NERDTreeToggle<CR>
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
" Silly VIM does not delete characters by DELETE key default.
set backspace=indent,eol,start
EOS
    CLI.caveat "Please add the following line into your ~/.vimrc.\nsource #{share}/vim/vimrc"
  end
end
