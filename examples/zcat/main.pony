"""
Example of ponyzip usage

This is a command line client that reads 1 zip archive
and prints the name and contents of each entry uncompressed to stdout.

Usage: ./example source.zip
"""

use "../ponyzip"
use "files"
use "buffered"
use "term"

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
        try
          env.out.write(ANSI.bold())
          env.out.print(stat.name as String)
          env.out.write(ANSI.reset())
          env.out.print("")
          let file =
            match stat.open()
            | let zf: ZipFile => zf
            | let e: ZipErrorT =>
              env.err.print(e.string())
              error
            end
          let reader = Reader
          let bufsize = USize(4096)
          while true do
            let buf = file.read(bufsize)?
            if buf.size() == 0 then
              break
            end
            reader.append(consume buf)
            // try to write lines
            while true do
              try
                let line = reader.line(where keep_line_breaks = true)?
                env.out.write("\t")
                env.out.write(consume line)
              else
                break
              end
            end
          end
        else
          env.err.print("ERROR reading file from archive")
        end
      end
    end
