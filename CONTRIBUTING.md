# Contributing to Vim

Patches are welcome in whatever form.
Discussions about patches happen on the vim-dev maillist.
If you create a pull request on GitHub it will be
forwarded to the vim-dev maillist.  You can also send your patch there
directly.  An attachment with a unified diff format is preferred.
Information about the maillist can be found [on the Vim website].

[on the Vim website]: http://www.vim.org/maillist.php#vim-dev

Please consider adding a test.  Test coverage isn't very good yet, this needs
to improve.  Look through recent patches for examples.  The tests are located
under "src/testdir".


# Reporting issues

We use GitHub issues, but that is not a requirement.  Writing to the Vim
maillist is also fine.

Please use the GitHub issues only for actual issues. If you are not 100% sure
that your problem is a Vim issue, please first discuss this on the Vim user
maillist.  Try reproducing the problem without any plugins or settings:

    vim -N -u NONE

If you report an issue, please describe exactly how to reproduce it.
For example, don't say "insert some text" but say what you did exactly:
"ahere is some text&lt;Esc&gt;".
Ideally, the steps you list can be used to write a test to verify the problem
is fixed.

Feel free to report even the smallest problem, also typos in the documentation.

You can find known issues in the todo file: ":help todo".
Or open [the todo file] on GitHub to see the latest version.

[the todo file]: https://github.com/vim/vim/blob/master/runtime/doc/todo.txt


# Syntax, indent and other runtime files

The latest version of these files can be obtained from the repository.
They are usually not updated with numbered patches.

If you find a problem with one of these files or have a suggestion for
improvement, please first try to contact the maintainer directly.
Look in the header of the file for the name and email address.

The maintainer will take care of issues and send updates to Bram for 
distribution with Vim.

If the maintainer does not react, contact the vim-dev maillist.
