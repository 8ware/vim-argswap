vim-argswap
===========

Vim plugin to swap arguments in list contexts

Usage
-----

Assuming that the repository is in your `runtimepath` (e.g. by using
pathogen.vim) the following mappings are set by default:

```vim
<C-k> .. swap argument under cursor with its right neighbor
<C-j> .. swap argument under cursor with its left neighbor
```

For example, open the test file and play a bit:

    vim "+call cursor(22, 24)" t/test-file.t

