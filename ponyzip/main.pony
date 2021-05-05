use "lib:zip"
use "format"
use "debug"
use "files"
use "collections"

use @zip_open[Pointer[_ZipArchive] tag](path: Pointer[U8] tag, flags: U32, errorp: Pointer[I32] tag)
use @zip_libzip_version[Pointer[U8] ref]()


primitive Zip
  fun open(path: FilePath, flags: OpenFlags): (ZipArchive | ZipError) =>
    var err: I32 = 0
    // TODO: check path caps in correspondance with OpenFlags
    let rawzip = @zip_open(path.path.cstring(), flags.value(), addressof err)
    match ZipErrors.from_error_code(err)
    | Ok => ZipArchive._create(rawzip, path)
    | let zoe: ZipError => zoe
    end

  fun libzip_version(): String iso^ =>
    recover
      let raw = @zip_libzip_version()
      String.copy_cstring(raw)
    end




