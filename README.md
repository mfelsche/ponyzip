# PonyZip

Reading .zip files with Pony.

Wrapper around [`libzip`](https://libzip.org).

## Usage

- Add `ponyzip` to your dependencies

```sh
corral add mfelsche/ponyzip --revision=v0.1.0
```

- Install [`libzip`](https://libzip.org).
- Open a zipfile:

```pony
use "ponyzip"
use "files"
use "format"

actor Main
  new create(env: Env) =>
    try
      let path_str = env.args(env.args.size() - 1)?
      let path = FilePath(env.root as AmbientAuth, path_str)?
      let archive = match Zip.open(path)
      | let archive: ZipArchive => archive
      | let e: ZipError =>
        env.err.print(e.string())
        error
      end
      for stat in archive.stats() do
        env.out
          .>write(stat.name as String)
          .>write("\t")
          .>write(
            Format.int[U64]((stat.size as U64) where width=8))
          .print(" bytes")
      end
    end
```
- Checkout more examples in [examples](examples).
