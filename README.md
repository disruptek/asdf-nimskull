<div align="center">

# asdf-nimskull [![Build](https://github.com/nim-works/asdf-nimskull/actions/workflows/build.yml/badge.svg)](https://github.com/nim-works/asdf-nimskull/actions/workflows/build.yml) [![Lint](https://github.com/nim-works/asdf-nimskull/actions/workflows/lint.yml/badge.svg)](https://github.com/nim-works/asdf-nimskull/actions/workflows/lint.yml)

[nimskull](https://nim-works.github.io/nimskull/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

**TODO: adapt this section**

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

# Install

Plugin:

```shell
asdf plugin add nimskull
# or
asdf plugin add nimskull https://github.com/nim-works/asdf-nimskull.git
```

nimskull:

```shell
# Show all installable versions
asdf list-all nimskull

# Install specific version
asdf install nimskull latest

# Set a version globally (on your ~/.tool-versions file)
asdf global nimskull latest

# Now nimskull commands are available
nim --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/nim-works/asdf-nimskull/graphs/contributors)!

# License

MIT
